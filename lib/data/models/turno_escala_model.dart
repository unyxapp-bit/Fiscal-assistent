import 'package:equatable/equatable.dart';

/// Model para TurnoEscala - Horários de um colaborador em um dia específico
class TurnoEscalaModel extends Equatable {
  final String id;
  final String escalaId;
  final String colaboradorId;
  final DateTime data;
  final String? entradaPrevista; // HH:mm
  final String? intervaloPrevisto; // HH:mm
  final String? retornoPrevisto; // HH:mm
  final String? saidaPrevista; // HH:mm
  final bool ehFolga;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TurnoEscalaModel({
    required this.id,
    required this.escalaId,
    required this.colaboradorId,
    required this.data,
    this.entradaPrevista,
    this.intervaloPrevisto,
    this.retornoPrevisto,
    this.saidaPrevista,
    this.ehFolga = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria TurnoEscalaModel a partir de JSON (Supabase)
  factory TurnoEscalaModel.fromJson(Map<String, dynamic> json) {
    return TurnoEscalaModel(
      id: json['id'] as String,
      escalaId: json['escala_id'] as String,
      colaboradorId: json['colaborador_id'] as String,
      data: DateTime.parse(json['data'] as String),
      entradaPrevista: json['entrada_prevista'] as String?,
      intervaloPrevisto: json['intervalo_previsto'] as String?,
      retornoPrevisto: json['retorno_previsto'] as String?,
      saidaPrevista: json['saida_prevista'] as String?,
      ehFolga: json['eh_folga'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converte TurnoEscalaModel para JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'escala_id': escalaId,
      'colaborador_id': colaboradorId,
      'data': data.toIso8601String().split('T')[0], // Apenas data (YYYY-MM-DD)
      'entrada_prevista': entradaPrevista,
      'intervalo_previsto': intervaloPrevisto,
      'retorno_previsto': retornoPrevisto,
      'saida_prevista': saidaPrevista,
      'eh_folga': ehFolga,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria cópia com alterações
  TurnoEscalaModel copyWith({
    String? id,
    String? escalaId,
    String? colaboradorId,
    DateTime? data,
    String? entradaPrevista,
    String? intervaloPrevisto,
    String? retornoPrevisto,
    String? saidaPrevista,
    bool? ehFolga,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TurnoEscalaModel(
      id: id ?? this.id,
      escalaId: escalaId ?? this.escalaId,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      data: data ?? this.data,
      entradaPrevista: entradaPrevista ?? this.entradaPrevista,
      intervaloPrevisto: intervaloPrevisto ?? this.intervaloPrevisto,
      retornoPrevisto: retornoPrevisto ?? this.retornoPrevisto,
      saidaPrevista: saidaPrevista ?? this.saidaPrevista,
      ehFolga: ehFolga ?? this.ehFolga,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se o turno é hoje
  bool get isHoje {
    final hoje = DateTime.now();
    return data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day;
  }

  /// Verifica se tem todos os horários definidos
  bool get isCompleto {
    return !ehFolga &&
        entradaPrevista != null &&
        intervaloPrevisto != null &&
        retornoPrevisto != null &&
        saidaPrevista != null;
  }

  @override
  List<Object?> get props => [
        id,
        escalaId,
        colaboradorId,
        data,
        entradaPrevista,
        intervaloPrevisto,
        retornoPrevisto,
        saidaPrevista,
        ehFolga,
      ];
}
