import 'package:flutter/material.dart';

// ── Tipo de campo ─────────────────────────────────────────────────────────────

enum TipoCampo { texto, simNao, numero, opcoes }

extension TipoCampoExt on TipoCampo {
  String get nome {
    switch (this) {
      case TipoCampo.texto:
        return 'Texto';
      case TipoCampo.simNao:
        return 'Sim / Não';
      case TipoCampo.numero:
        return 'Número';
      case TipoCampo.opcoes:
        return 'Opções';
    }
  }

  IconData get icone {
    switch (this) {
      case TipoCampo.texto:
        return Icons.short_text;
      case TipoCampo.simNao:
        return Icons.toggle_on_outlined;
      case TipoCampo.numero:
        return Icons.pin_outlined;
      case TipoCampo.opcoes:
        return Icons.radio_button_checked;
    }
  }
}

// ── Campo individual ──────────────────────────────────────────────────────────

class CampoFormulario {
  final String id;
  final String label;
  final TipoCampo tipo;
  final bool obrigatorio;
  final List<String> opcoes; // apenas quando tipo == opcoes

  const CampoFormulario({
    required this.id,
    required this.label,
    this.tipo = TipoCampo.texto,
    this.obrigatorio = true,
    this.opcoes = const [],
  });

  /// Suporta formato legado (String) e novo (Map).
  factory CampoFormulario.fromRaw(dynamic raw) {
    if (raw is String) {
      return CampoFormulario(id: raw, label: raw);
    }
    final m = raw as Map<String, dynamic>;
    final rawId = (m['id'] as String?) ?? '';
    final id = rawId.isNotEmpty ? rawId : (m['label'] as String? ?? 'campo');
    return CampoFormulario(
      id: id,
      label: m['label'] as String? ?? id,
      tipo: TipoCampo.values.firstWhere(
        (t) => t.name == (m['tipo'] as String? ?? 'texto'),
        orElse: () => TipoCampo.texto,
      ),
      obrigatorio: m['obrigatorio'] as bool? ?? true,
      opcoes: (m['opcoes'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'tipo': tipo.name,
        'obrigatorio': obrigatorio,
        'opcoes': opcoes,
      };

  CampoFormulario copyWith({
    String? id,
    String? label,
    TipoCampo? tipo,
    bool? obrigatorio,
    List<String>? opcoes,
  }) =>
      CampoFormulario(
        id: id ?? this.id,
        label: label ?? this.label,
        tipo: tipo ?? this.tipo,
        obrigatorio: obrigatorio ?? this.obrigatorio,
        opcoes: opcoes ?? this.opcoes,
      );
}

// ── Formulário ────────────────────────────────────────────────────────────────

class Formulario {
  final String id;
  final String titulo;
  final String descricao;
  final bool template;
  final bool ativo;
  final List<CampoFormulario> campos;
  final DateTime createdAt;
  final DateTime updatedAt;

  Formulario({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.template = false,
    this.ativo = true,
    required this.campos,
    required this.createdAt,
    required this.updatedAt,
  });

  Formulario copyWith({
    String? id,
    String? titulo,
    String? descricao,
    bool? template,
    bool? ativo,
    List<CampoFormulario>? campos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Formulario(
        id: id ?? this.id,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        template: template ?? this.template,
        ativo: ativo ?? this.ativo,
        campos: campos ?? this.campos,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ── Resposta ──────────────────────────────────────────────────────────────────

class RespostaFormulario {
  final String id;
  final String formularioId;
  final Map<String, dynamic> valores; // campo.label → valor
  final DateTime preenchidoEm;

  RespostaFormulario({
    required this.id,
    required this.formularioId,
    required this.valores,
    required this.preenchidoEm,
  });

  RespostaFormulario copyWith({
    String? id,
    String? formularioId,
    Map<String, dynamic>? valores,
    DateTime? preenchidoEm,
  }) =>
      RespostaFormulario(
        id: id ?? this.id,
        formularioId: formularioId ?? this.formularioId,
        valores: valores ?? this.valores,
        preenchidoEm: preenchidoEm ?? this.preenchidoEm,
      );
}
