import 'package:equatable/equatable.dart';

/// Entidade que representa um registro de ponto (entrada/saída de um dia)
class RegistroPonto extends Equatable {
  final String id;
  final String colaboradorId;
  final DateTime data;
  final String? entrada;          // HH:mm
  final String? intervaloSaida;   // HH:mm — saída para intervalo
  final String? intervaloRetorno; // HH:mm — retorno do intervalo
  final String? saida;            // HH:mm
  final String? observacao;

  const RegistroPonto({
    required this.id,
    required this.colaboradorId,
    required this.data,
    this.entrada,
    this.intervaloSaida,
    this.intervaloRetorno,
    this.saida,
    this.observacao,
  });

  RegistroPonto copyWith({
    String? id,
    String? colaboradorId,
    DateTime? data,
    String? entrada,
    String? intervaloSaida,
    String? intervaloRetorno,
    String? saida,
    String? observacao,
  }) {
    return RegistroPonto(
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

  @override
  List<Object?> get props => [
        id,
        colaboradorId,
        data,
        entrada,
        intervaloSaida,
        intervaloRetorno,
        saida,
        observacao,
      ];
}
