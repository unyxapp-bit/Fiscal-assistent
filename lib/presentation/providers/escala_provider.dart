import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
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

  List<TurnoLocal> get turnos => List.unmodifiable(_turnos);

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
