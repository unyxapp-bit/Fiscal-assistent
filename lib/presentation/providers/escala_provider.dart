import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/enums/departamento_tipo.dart';
import '../../data/datasources/remote/supabase_client.dart';

/// Modelo de turno com persistência no Supabase
class TurnoLocal {
  final String id;
  final String colaboradorId;
  final String colaboradorNome;
  final DepartamentoTipo departamento;
  final DateTime data;
  final String? entrada;    // HH:mm
  final String? intervalo;  // HH:mm
  final String? retorno;    // HH:mm
  final String? saida;      // HH:mm
  final bool folga;
  final bool feriado;
  final String? observacao;

  TurnoLocal({
    required this.id,
    required this.colaboradorId,
    required this.colaboradorNome,
    required this.departamento,
    required this.data,
    this.entrada,
    this.intervalo,
    this.retorno,
    this.saida,
    this.folga = false,
    this.feriado = false,
    this.observacao,
  });

  factory TurnoLocal.fromMap(Map<String, dynamic> m) => TurnoLocal(
        id: m['id'] as String,
        colaboradorId: m['colaborador_id'] as String,
        colaboradorNome: m['colaborador_nome'] as String,
        departamento:
            DepartamentoTipo.fromString(m['departamento'] as String? ?? 'fiscal'),
        data: DateTime.parse(m['data'] as String),
        entrada: m['entrada'] as String?,
        intervalo: m['intervalo'] as String?,
        retorno: m['retorno'] as String?,
        saida: m['saida'] as String?,
        folga: m['folga'] as bool? ?? false,
        feriado: m['feriado'] as bool? ?? false,
        observacao: m['observacao'] as String?,
      );

  Map<String, dynamic> toMap(String fiscalId) => {
        'id': id,
        'fiscal_id': fiscalId,
        'colaborador_id': colaboradorId,
        'colaborador_nome': colaboradorNome,
        'departamento': departamento.toJson(),
        'data':
            '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
        'entrada': entrada,
        'intervalo': intervalo,
        'retorno': retorno,
        'saida': saida,
        'folga': folga,
        'feriado': feriado,
        'observacao': observacao,
        'updated_at': DateTime.now().toIso8601String(),
      };

  bool get trabalhando => !folga && !feriado;

  bool get completo =>
      trabalhando &&
      entrada != null &&
      intervalo != null &&
      retorno != null &&
      saida != null;

  String get statusLabel {
    if (feriado) return 'Feriado';
    if (folga) return 'Folga';
    return completo ? '$entrada–$saida' : 'Incompleto';
  }

  TurnoLocal copyWith({
    String? colaboradorId,
    String? colaboradorNome,
    DepartamentoTipo? departamento,
    DateTime? data,
    String? entrada,
    String? intervalo,
    String? retorno,
    String? saida,
    bool? folga,
    bool? feriado,
    String? observacao,
  }) {
    return TurnoLocal(
      id: id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      colaboradorNome: colaboradorNome ?? this.colaboradorNome,
      departamento: departamento ?? this.departamento,
      data: data ?? this.data,
      entrada: entrada ?? this.entrada,
      intervalo: intervalo ?? this.intervalo,
      retorno: retorno ?? this.retorno,
      saida: saida ?? this.saida,
      folga: folga ?? this.folga,
      feriado: feriado ?? this.feriado,
      observacao: observacao ?? this.observacao,
    );
  }
}

class EscalaProvider with ChangeNotifier {
  static const _table = 'turnos_escala';

  final List<TurnoLocal> _turnos = [];
  bool _gerando = false;

  List<TurnoLocal> get turnos => List.unmodifiable(_turnos);
  bool get gerando => _gerando;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  /// Carrega todos os turnos do Supabase.
  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('data');

      _turnos
        ..clear()
        ..addAll((rows as List)
            .map((r) => TurnoLocal.fromMap(r as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[EscalaProvider] Erro ao carregar: $e');
    }
  }

  /// Todos os turnos de uma data específica
  List<TurnoLocal> getTurnosByData(DateTime data) {
    return _turnos
        .where((t) =>
            t.data.year == data.year &&
            t.data.month == data.month &&
            t.data.day == data.day)
        .toList()
      ..sort((a, b) => a.colaboradorNome.compareTo(b.colaboradorNome));
  }

  /// Turnos de hoje
  List<TurnoLocal> get turnosHoje => getTurnosByData(DateTime.now());

  /// Turnos de hoje que estão trabalhando
  List<TurnoLocal> get trabalhandoHoje =>
      turnosHoje.where((t) => t.trabalhando).toList();

  int get totalTrabalhandoHoje => trabalhandoHoje.length;

  Set<String> get datasComEscala {
    return _turnos
        .map((t) =>
            '${t.data.year}-${t.data.month.toString().padLeft(2, "0")}-${t.data.day.toString().padLeft(2, "0")}')
        .toSet();
  }

  TurnoLocal? getTurno(String colaboradorId, DateTime data) {
    try {
      return _turnos.firstWhere((t) =>
          t.colaboradorId == colaboradorId &&
          t.data.year == data.year &&
          t.data.month == data.month &&
          t.data.day == data.day);
    } catch (_) {
      return null;
    }
  }

  /// Adiciona ou substitui turno (mesmo colaborador/data).
  void adicionarOuAtualizarTurno({
    required String colaboradorId,
    required String colaboradorNome,
    required DepartamentoTipo departamento,
    required DateTime data,
    String? entrada,
    String? intervalo,
    String? retorno,
    String? saida,
    bool folga = false,
    bool feriado = false,
    String? observacao,
  }) {
    // Remover existente localmente
    final existente = getTurno(colaboradorId, data);
    _turnos.removeWhere((t) =>
        t.colaboradorId == colaboradorId &&
        t.data.year == data.year &&
        t.data.month == data.month &&
        t.data.day == data.day);

    final turno = TurnoLocal(
      id: existente?.id ?? const Uuid().v4(),
      colaboradorId: colaboradorId,
      colaboradorNome: colaboradorNome,
      departamento: departamento,
      data: DateTime(data.year, data.month, data.day),
      entrada: folga || feriado ? null : entrada,
      intervalo: folga || feriado ? null : intervalo,
      retorno: folga || feriado ? null : retorno,
      saida: folga || feriado ? null : saida,
      folga: folga,
      feriado: feriado,
      observacao: observacao,
    );

    _turnos.add(turno);
    notifyListeners();

    // Upsert para Supabase (ON CONFLICT (fiscal_id, colaborador_id, data))
    SupabaseClientManager.client
        .from(_table)
        .upsert(turno.toMap(_fiscalId))
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[EscalaProvider] Erro ao sincronizar: $e');
    });
  }

  /// Remove um turno pelo id
  void removerTurno(String id) {
    _turnos.removeWhere((t) => t.id == id);
    notifyListeners();

    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[EscalaProvider] Erro ao remover: $e');
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String? _parseTime(dynamic v) {
    if (v == null) return null;
    final s = v as String;
    return s.length > 5 ? s.substring(0, 5) : s;
  }

  // ── Geração automática ─────────────────────────────────────────────────────

  /// Gera a escala da semana a partir dos registros de ponto de todos os
  /// colaboradores ativos. Faz uma única query ao Supabase para a semana inteira.
  ///
  /// Retorna um mapa com as chaves 'criados' e 'semRegistro'.
  Future<Map<String, int>> gerarEscalaDaSemana({
    required List<Colaborador> colaboradores,
    required DateTime segunda,
    bool substituirExistentes = false,
  }) async {
    _gerando = true;
    notifyListeners();

    int criados = 0;
    int semRegistro = 0;

    try {
      final ativos = colaboradores.where((c) => c.ativo).toList();
      if (ativos.isEmpty) {
        _gerando = false;
        notifyListeners();
        return {'criados': 0, 'semRegistro': 0};
      }

      final segundaNorm =
          DateTime(segunda.year, segunda.month, segunda.day);

      // Busca todos os registros dos colaboradores (sem filtro de data),
      // ordenados do mais recente para o mais antigo, para usar como template
      // de qualquer semana independente do ano.
      final umAnoAtras = segundaNorm.subtract(const Duration(days: 365 * 2));
      final rows = await SupabaseClientManager.client
          .from('registros_ponto')
          .select()
          .inFilter('colaborador_id', ativos.map((c) => c.id).toList())
          .gte('data', _dateKey(umAnoAtras))
          .order('data', ascending: false);

      // Map: colaboradorId → weekday (1=Seg…7=Dom) → linha mais recente
      final regMap = <String, Map<int, Map<String, dynamic>>>{};
      for (final row in (rows as List)) {
        final m = row as Map<String, dynamic>;
        final cId = m['colaborador_id'] as String;
        final date = DateTime.parse((m['data'] as String).substring(0, 10));
        final wd = date.weekday; // 1=Seg, 7=Dom
        regMap.putIfAbsent(cId, () => <int, Map<String, dynamic>>{});
        // Só guarda o mais recente (já ordenado desc)
        regMap[cId]!.putIfAbsent(wd, () => m);
      }

      final novosTurnos = <TurnoLocal>[];

      for (final colab in ativos) {
        for (int d = 0; d < 7; d++) {
          final dia = DateTime(
              segundaNorm.year, segundaNorm.month, segundaNorm.day + d);

          // Pular se já existe e não queremos substituir
          if (!substituirExistentes && getTurno(colab.id, dia) != null) {
            continue;
          }

          final reg = regMap[colab.id]?[dia.weekday];

          if (reg != null) {
            final obs = (reg['observacao'] as String?)?.toUpperCase();
            final folga = obs == 'FOLGA';
            final feriado = obs == 'FERIADO';

            final existente = getTurno(colab.id, dia);
            novosTurnos.add(TurnoLocal(
              id: existente?.id ?? const Uuid().v4(),
              colaboradorId: colab.id,
              colaboradorNome: colab.nome,
              departamento: colab.departamento,
              data: dia,
              entrada: folga || feriado ? null : _parseTime(reg['entrada']),
              intervalo: folga || feriado
                  ? null
                  : _parseTime(reg['intervalo_saida']),
              retorno: folga || feriado
                  ? null
                  : _parseTime(reg['intervalo_retorno']),
              saida: folga || feriado ? null : _parseTime(reg['saida']),
              folga: folga,
              feriado: feriado,
            ));
            criados++;
          } else {
            semRegistro++;
          }
        }
      }

      // Atualizar estado local em lote
      for (final nt in novosTurnos) {
        _turnos.removeWhere((t) =>
            t.colaboradorId == nt.colaboradorId &&
            t.data.year == nt.data.year &&
            t.data.month == nt.data.month &&
            t.data.day == nt.data.day);
        _turnos.add(nt);
      }

      // Bulk upsert para o Supabase
      if (novosTurnos.isNotEmpty) {
        await SupabaseClientManager.client
            .from(_table)
            .upsert(novosTurnos.map((t) => t.toMap(_fiscalId)).toList());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EscalaProvider] Erro ao gerar escala: $e');
      }
    } finally {
      _gerando = false;
      notifyListeners();
    }

    return {'criados': criados, 'semRegistro': semRegistro};
  }

  /// Remove todos os turnos de uma data
  void limparDia(DateTime data) {
    final ids = _turnos
        .where((t) =>
            t.data.year == data.year &&
            t.data.month == data.month &&
            t.data.day == data.day)
        .map((t) => t.id)
        .toList();

    _turnos.removeWhere((t) =>
        t.data.year == data.year &&
        t.data.month == data.month &&
        t.data.day == data.day);
    notifyListeners();

    if (ids.isNotEmpty) {
      SupabaseClientManager.client
          .from(_table)
          .delete()
          .inFilter('id', ids)
          .then((_) {})
          .catchError((e) {
        if (kDebugMode) debugPrint('[EscalaProvider] Erro ao limpar dia: $e');
      });
    }
  }
}
