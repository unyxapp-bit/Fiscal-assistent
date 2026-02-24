import '../../domain/entities/registro_ponto.dart';

/// Model para RegistroPonto — conversão JSON ↔ Entity
class RegistroPontoModel extends RegistroPonto {
  const RegistroPontoModel({
    required super.id,
    required super.colaboradorId,
    required super.data,
    super.entrada,
    super.intervaloSaida,
    super.intervaloRetorno,
    super.saida,
    super.observacao,
  });

  /// Converte "HH:mm:ss" (Postgres time) → "HH:mm"
  static String? _parseTime(dynamic v) {
    if (v == null) return null;
    final s = v as String;
    return s.length > 5 ? s.substring(0, 5) : s;
  }

  factory RegistroPontoModel.fromJson(Map<String, dynamic> json) {
    return RegistroPontoModel(
      id: json['id'] as String,
      colaboradorId: json['colaborador_id'] as String,
      data: DateTime.parse(json['data'] as String),
      entrada: _parseTime(json['entrada']),
      intervaloSaida: _parseTime(json['intervalo_saida']),
      intervaloRetorno: _parseTime(json['intervalo_retorno']),
      saida: _parseTime(json['saida']),
      observacao: json['observacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colaborador_id': colaboradorId,
      'data':
          '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
      'entrada': entrada,
      'intervalo_saida': intervaloSaida,
      'intervalo_retorno': intervaloRetorno,
      'saida': saida,
      'observacao': observacao,
    };
  }

  factory RegistroPontoModel.fromEntity(RegistroPonto entity) {
    return RegistroPontoModel(
      id: entity.id,
      colaboradorId: entity.colaboradorId,
      data: entity.data,
      entrada: entity.entrada,
      intervaloSaida: entity.intervaloSaida,
      intervaloRetorno: entity.intervaloRetorno,
      saida: entity.saida,
      observacao: entity.observacao,
    );
  }

  RegistroPonto toEntity() {
    return RegistroPonto(
      id: id,
      colaboradorId: colaboradorId,
      data: data,
      entrada: entrada,
      intervaloSaida: intervaloSaida,
      intervaloRetorno: intervaloRetorno,
      saida: saida,
      observacao: observacao,
    );
  }

  @override
  RegistroPontoModel copyWith({
    String? id,
    String? colaboradorId,
    DateTime? data,
    String? entrada,
    String? intervaloSaida,
    String? intervaloRetorno,
    String? saida,
    String? observacao,
  }) {
    return RegistroPontoModel(
      id: id ?? this.id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      data: data ?? this.data,
      entrada: entrada ?? this.entrada,
      intervaloSaida: intervaloSaida ?? this.intervaloSaida,
      intervaloRetorno: intervaloRetorno ?? this.intervaloRetorno,
      saida: saida ?? this.saida,
      observacao: observacao ?? this.observacao,
    );
  }
}
