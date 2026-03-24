import '../enums/tipo_lembrete.dart';

class Nota {
  final String id;
  final String titulo;
  final String conteudo;
  final TipoLembrete tipo;
  final bool concluida;
  final bool importante;
  final bool lembreteAtivo;
  final DateTime? dataLembrete;
  final String? fotoUrl;
  final String? fotoNome;
  final String? arquivoUrl;
  final String? arquivoNome;
  final DateTime createdAt;
  final DateTime updatedAt;

  Nota({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.tipo,
    this.concluida = false,
    this.importante = false,
    this.lembreteAtivo = true,
    this.dataLembrete,
    this.fotoUrl,
    this.fotoNome,
    this.arquivoUrl,
    this.arquivoNome,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True quando a nota tem data passada e ainda não foi concluída.
  bool get isVencido =>
      dataLembrete != null &&
      dataLembrete!.isBefore(DateTime.now()) &&
      !concluida;

  Nota copyWith({
    String? id,
    String? titulo,
    String? conteudo,
    TipoLembrete? tipo,
    bool? concluida,
    bool? importante,
    bool? lembreteAtivo,
    DateTime? dataLembrete,
    String? fotoUrl,
    String? fotoNome,
    String? arquivoUrl,
    String? arquivoNome,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Nota(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      tipo: tipo ?? this.tipo,
      concluida: concluida ?? this.concluida,
      importante: importante ?? this.importante,
      lembreteAtivo: lembreteAtivo ?? this.lembreteAtivo,
      dataLembrete: dataLembrete ?? this.dataLembrete,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoNome: fotoNome ?? this.fotoNome,
      arquivoUrl: arquivoUrl ?? this.arquivoUrl,
      arquivoNome: arquivoNome ?? this.arquivoNome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
