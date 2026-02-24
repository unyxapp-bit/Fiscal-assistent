import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/snapshot.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/enums/status_presenca.dart';
import '../../data/datasources/remote/supabase_client.dart';

class SnapshotProvider with ChangeNotifier {
  static const _tableS = 'snapshots';
  static const _tableP = 'presencas_snapshot';

  Snapshot? _snapshotAtual;

  Snapshot? get snapshotAtual => _snapshotAtual;
  bool get temSnapshotAtivo =>
      _snapshotAtual != null && !_snapshotAtual!.finalizado;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Converte "HH:mm" em DateTime do dia de hoje (horário local → UTC para storage).
  DateTime _parseHorario(String hhmm) {
    final parts = hhmm.split(':');
    final hoje = DateTime.now();
    return DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    ).toUtc();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  /// Carrega o snapshot ativo de HOJE do Supabase.
  Future<void> load() async {
    try {
      final hoje = DateTime.now();
      final dataHojeStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

      final rows = await SupabaseClientManager.client
          .from(_tableS)
          .select()
          .eq('fiscal_id', _fiscalId)
          .eq('finalizado', false)
          .gte('data_hora', '${dataHojeStr}T00:00:00')
          .lte('data_hora', '${dataHojeStr}T23:59:59')
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) {
        _snapshotAtual = null;
        notifyListeners();
        return;
      }

      final snapMap = rows.first;
      final snapshotId = snapMap['id'] as String;

      final presRows = await SupabaseClientManager.client
          .from(_tableP)
          .select()
          .eq('snapshot_id', snapshotId);

      final presencas = presRows.map(_presencaFromMap).toList();

      _snapshotAtual = Snapshot(
        id: snapshotId,
        fiscalId: snapMap['fiscal_id'] as String,
        dataHora: DateTime.parse(snapMap['data_hora'] as String),
        finalizado: snapMap['finalizado'] as bool? ?? false,
        presencas: presencas,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[SnapshotProvider] Erro ao carregar: $e');
    }
  }

  // ─── Criar Snapshot ───────────────────────────────────────────────────────

  /// Cria um novo snapshot baseado nos registros de ponto de hoje.
  ///
  /// [colaboradores] deve conter todos os colaboradores ativos do fiscal.
  Future<void> criarSnapshot(
    String fiscalId,
    DateTime dataHora,
    List<Colaborador> colaboradores,
  ) async {
    // Busca os registros de ponto de hoje para todos os colaboradores
    final hoje = DateTime.now();
    final dataStr =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
    final colaboradorIds =
        colaboradores.where((c) => c.ativo).map((c) => c.id).toList();

    List<Map<String, dynamic>> registroRows = [];
    if (colaboradorIds.isNotEmpty) {
      try {
        registroRows = List<Map<String, dynamic>>.from(
          await SupabaseClientManager.client
              .from('registros_ponto')
              .select()
              .inFilter('colaborador_id', colaboradorIds)
              .eq('data', dataStr),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SnapshotProvider] Erro ao buscar registros: $e');
        }
      }
    }

    final presencas = _gerarPresencasDeRegistros(colaboradores, registroRows);
    final snapshotId = const Uuid().v4();

    _snapshotAtual = Snapshot(
      id: snapshotId,
      fiscalId: fiscalId,
      dataHora: dataHora,
      finalizado: false,
      presencas: presencas,
    );
    notifyListeners();

    try {
      await SupabaseClientManager.client.from(_tableS).insert({
        'id': snapshotId,
        'fiscal_id': fiscalId,
        'data_hora': dataHora.toIso8601String(),
        'finalizado': false,
      });

      if (presencas.isNotEmpty) {
        final presData = presencas
            .map((p) => {
                  'id': p.id,
                  'snapshot_id': snapshotId,
                  'fiscal_id': fiscalId,
                  'colaborador_id': p.colaboradorId,
                  'status': p.status.name,
                  'horario_esperado': p.horarioEsperado.toIso8601String(),
                  'confirmado_em': p.confirmadoEm?.toIso8601String(),
                  'minutos_atraso': p.minutosAtraso,
                  'observacao': p.observacao,
                  'substituido_por': p.substituidoPor,
                })
            .toList();

        await SupabaseClientManager.client.from(_tableP).insert(presData);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SnapshotProvider] Erro ao criar: $e');
    }
  }

  /// Constrói a lista de presenças a partir dos registros de ponto de hoje.
  List<PresencaSnapshot> _gerarPresencasDeRegistros(
    List<Colaborador> colaboradores,
    List<Map<String, dynamic>> registroRows,
  ) {
    final agora = DateTime.now();
    final presencas = <PresencaSnapshot>[];

    // Index registros por colaborador_id para lookup O(1)
    final registroByColab = <String, Map<String, dynamic>>{};
    for (final r in registroRows) {
      registroByColab[r['colaborador_id'] as String] = r;
    }

    for (final colab in colaboradores) {
      if (!colab.ativo) continue;

      final registro = registroByColab[colab.id];
      if (registro == null) continue; // sem registro hoje — não aparece no snapshot

      final obs = (registro['observacao'] as String?)?.toLowerCase().trim();
      if (obs == 'feriado') continue; // feriados não aparecem no snapshot

      if (obs == 'folga') {
        presencas.add(PresencaSnapshot(
          id: const Uuid().v4(),
          colaboradorId: colab.id,
          status: StatusPresenca.folga,
          horarioEsperado: DateTime(agora.year, agora.month, agora.day, 0, 0),
        ));
        continue;
      }

      final entradaRaw = registro['entrada'] as String?;
      if (entradaRaw != null && entradaRaw.isNotEmpty) {
        // Suporta "HH:mm" e "HH:mm:ss" (formato Postgres TIME)
        final horarioEsperado = _parseHorario(entradaRaw.substring(0, 5));
        final atraso = DateTime.now().toUtc().difference(horarioEsperado);
        final minutosAtraso = atraso.inMinutes > 0 ? atraso.inMinutes : null;

        presencas.add(PresencaSnapshot(
          id: const Uuid().v4(),
          colaboradorId: colab.id,
          status: StatusPresenca.pendente,
          horarioEsperado: horarioEsperado,
          minutosAtraso: minutosAtraso,
        ));
      } else {
        // Registro existe mas sem horário de entrada — pendente sem atraso
        presencas.add(PresencaSnapshot(
          id: const Uuid().v4(),
          colaboradorId: colab.id,
          status: StatusPresenca.pendente,
          horarioEsperado: agora.toUtc(),
        ));
      }
    }

    // Ordenar: primeiro os ativos (por horário), depois os de folga
    presencas.sort((a, b) {
      if (a.status == StatusPresenca.folga &&
          b.status != StatusPresenca.folga) {
        return 1;
      }
      if (a.status != StatusPresenca.folga &&
          b.status == StatusPresenca.folga) {
        return -1;
      }
      return a.horarioEsperado.compareTo(b.horarioEsperado);
    });

    return presencas;
  }

  // ─── Ações de presença ───────────────────────────────────────────────────

  void confirmarPresenca(String colaboradorId) {
    if (_snapshotAtual == null) return;
    final index = _snapshotAtual!.presencas
        .indexWhere((p) => p.colaboradorId == colaboradorId);
    if (index != -1) {
      _snapshotAtual!.presencas[index] =
          _snapshotAtual!.presencas[index].copyWith(
        status: StatusPresenca.confirmado,
        confirmadoEm: DateTime.now(),
      );
      notifyListeners();
      _syncPresenca(_snapshotAtual!.presencas[index]);
    }
  }

  void marcarAusente(String colaboradorId, String? observacao) {
    if (_snapshotAtual == null) return;
    final index = _snapshotAtual!.presencas
        .indexWhere((p) => p.colaboradorId == colaboradorId);
    if (index != -1) {
      _snapshotAtual!.presencas[index] =
          _snapshotAtual!.presencas[index].copyWith(
        status: StatusPresenca.ausente,
        observacao: observacao,
      );
      notifyListeners();
      _syncPresenca(_snapshotAtual!.presencas[index]);
    }
  }

  void marcarAtrasado(String colaboradorId) {
    if (_snapshotAtual == null) return;
    final index = _snapshotAtual!.presencas
        .indexWhere((p) => p.colaboradorId == colaboradorId);
    if (index != -1) {
      _snapshotAtual!.presencas[index] =
          _snapshotAtual!.presencas[index].copyWith(
        status: StatusPresenca.atrasado,
        confirmadoEm: DateTime.now(),
      );
      notifyListeners();
      _syncPresenca(_snapshotAtual!.presencas[index]);
    }
  }

  Future<void> substituir(
    String colaboradorIdOriginal,
    String colaboradorIdSubstituto,
    String nomeSubstituto,
  ) async {
    if (_snapshotAtual == null) return;

    final indexOriginal = _snapshotAtual!.presencas
        .indexWhere((p) => p.colaboradorId == colaboradorIdOriginal);

    if (indexOriginal != -1) {
      _snapshotAtual!.presencas[indexOriginal] =
          _snapshotAtual!.presencas[indexOriginal].copyWith(
        status: StatusPresenca.ausente,
        substituidoPor: colaboradorIdSubstituto,
        observacao: 'Substituído por $nomeSubstituto',
      );
      notifyListeners();
      _syncPresenca(_snapshotAtual!.presencas[indexOriginal]);
    }
  }

  void finalizar() {
    if (_snapshotAtual == null) return;
    _snapshotAtual = _snapshotAtual!.copyWith(finalizado: true);
    notifyListeners();

    SupabaseClientManager.client
        .from(_tableS)
        .update({'finalizado': true})
        .eq('id', _snapshotAtual!.id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[SnapshotProvider] Erro ao finalizar: $e');
    });
  }

  // ─── Getters agregados ───────────────────────────────────────────────────

  int get totalPresentes => _snapshotAtual?.presencas
          .where((p) =>
              p.status == StatusPresenca.confirmado ||
              p.status == StatusPresenca.atrasado)
          .length ??
      0;

  int get totalAusentes =>
      _snapshotAtual?.presencas
          .where((p) => p.status == StatusPresenca.ausente)
          .length ??
      0;

  int get totalPendentes =>
      _snapshotAtual?.presencas
          .where((p) => p.status == StatusPresenca.pendente)
          .length ??
      0;

  int get totalFolgas =>
      _snapshotAtual?.presencas
          .where((p) => p.status == StatusPresenca.folga)
          .length ??
      0;

  /// Quantidade de colaboradores com atraso > 10 min ainda pendentes.
  int get totalComAtraso =>
      _snapshotAtual?.presencas
          .where((p) =>
              p.status == StatusPresenca.pendente &&
              p.minutosAtraso != null &&
              p.minutosAtraso! > 10)
          .length ??
      0;

  // ─── Sync / Parse ────────────────────────────────────────────────────────

  void _syncPresenca(PresencaSnapshot p) {
    SupabaseClientManager.client.from(_tableP).update({
      'status': p.status.name,
      'confirmado_em': p.confirmadoEm?.toIso8601String(),
      'minutos_atraso': p.minutosAtraso,
      'observacao': p.observacao,
      'substituido_por': p.substituidoPor,
    }).eq('id', p.id).then((_) {}).catchError((e) {
      if (kDebugMode) debugPrint('[SnapshotProvider] Erro ao sync: $e');
    });
  }

  PresencaSnapshot _presencaFromMap(Map<String, dynamic> m) =>
      PresencaSnapshot(
        id: m['id'] as String,
        colaboradorId: m['colaborador_id'] as String,
        status: _parseStatus(m['status'] as String? ?? 'pendente'),
        horarioEsperado: DateTime.parse(m['horario_esperado'] as String),
        confirmadoEm: m['confirmado_em'] != null
            ? DateTime.parse(m['confirmado_em'] as String)
            : null,
        minutosAtraso: m['minutos_atraso'] as int?,
        observacao: m['observacao'] as String?,
        substituidoPor: m['substituido_por'] as String?,
      );

  StatusPresenca _parseStatus(String s) {
    switch (s) {
      case 'confirmado':
        return StatusPresenca.confirmado;
      case 'atrasado':
        return StatusPresenca.atrasado;
      case 'ausente':
        return StatusPresenca.ausente;
      case 'folga':
        return StatusPresenca.folga;
      default:
        return StatusPresenca.pendente;
    }
  }
}
