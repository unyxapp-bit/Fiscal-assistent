import '../datasources/remote/supabase_client.dart';

class CupomDadosConfig {
  final String tituloCabecalho;
  final String subtituloCabecalho;
  final String cnpj;
  final String enderecoLinha1;
  final String enderecoLinha2;
  final String telefone;
  final String whatsapp;
  final String instagram;
  final String website;
  final String mensagemTopo;
  final String mensagemFinal;
  final String observacaoPadrao;
  final bool exibirDataHoraEmissao;
  final double tamanhoFonte;
  final bool centralizarCabecalho;
  final bool centralizarRodape;
  final String textoDestaque;
  final String termoDestaqueItem;

  const CupomDadosConfig({
    required this.tituloCabecalho,
    required this.subtituloCabecalho,
    required this.cnpj,
    required this.enderecoLinha1,
    required this.enderecoLinha2,
    required this.telefone,
    required this.whatsapp,
    required this.instagram,
    required this.website,
    required this.mensagemTopo,
    required this.mensagemFinal,
    required this.observacaoPadrao,
    required this.exibirDataHoraEmissao,
    required this.tamanhoFonte,
    required this.centralizarCabecalho,
    required this.centralizarRodape,
    required this.textoDestaque,
    required this.termoDestaqueItem,
  });

  factory CupomDadosConfig.padrao() {
    return const CupomDadosConfig(
      tituloCabecalho: 'PIZZARIA CARROSSEL',
      subtituloCabecalho: '',
      cnpj: '',
      enderecoLinha1: '',
      enderecoLinha2: '',
      telefone: '',
      whatsapp: '',
      instagram: '',
      website: '',
      mensagemTopo: '',
      mensagemFinal: 'BOM APETITE!',
      observacaoPadrao: '',
      exibirDataHoraEmissao: true,
      tamanhoFonte: 12,
      centralizarCabecalho: true,
      centralizarRodape: true,
      textoDestaque: '',
      termoDestaqueItem: '',
    );
  }

  CupomDadosConfig copyWith({
    String? tituloCabecalho,
    String? subtituloCabecalho,
    String? cnpj,
    String? enderecoLinha1,
    String? enderecoLinha2,
    String? telefone,
    String? whatsapp,
    String? instagram,
    String? website,
    String? mensagemTopo,
    String? mensagemFinal,
    String? observacaoPadrao,
    bool? exibirDataHoraEmissao,
    double? tamanhoFonte,
    bool? centralizarCabecalho,
    bool? centralizarRodape,
    String? textoDestaque,
    String? termoDestaqueItem,
  }) {
    return CupomDadosConfig(
      tituloCabecalho: tituloCabecalho ?? this.tituloCabecalho,
      subtituloCabecalho: subtituloCabecalho ?? this.subtituloCabecalho,
      cnpj: cnpj ?? this.cnpj,
      enderecoLinha1: enderecoLinha1 ?? this.enderecoLinha1,
      enderecoLinha2: enderecoLinha2 ?? this.enderecoLinha2,
      telefone: telefone ?? this.telefone,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      website: website ?? this.website,
      mensagemTopo: mensagemTopo ?? this.mensagemTopo,
      mensagemFinal: mensagemFinal ?? this.mensagemFinal,
      observacaoPadrao: observacaoPadrao ?? this.observacaoPadrao,
      exibirDataHoraEmissao:
          exibirDataHoraEmissao ?? this.exibirDataHoraEmissao,
      tamanhoFonte: tamanhoFonte ?? this.tamanhoFonte,
      centralizarCabecalho: centralizarCabecalho ?? this.centralizarCabecalho,
      centralizarRodape: centralizarRodape ?? this.centralizarRodape,
      textoDestaque: textoDestaque ?? this.textoDestaque,
      termoDestaqueItem: termoDestaqueItem ?? this.termoDestaqueItem,
    );
  }

  Map<String, dynamic> toMap(String fiscalId) => {
        'fiscal_id': fiscalId,
        'titulo_cabecalho': tituloCabecalho.trim(),
        'subtitulo_cabecalho': subtituloCabecalho.trim(),
        'cnpj': cnpj.trim(),
        'endereco_linha1': enderecoLinha1.trim(),
        'endereco_linha2': enderecoLinha2.trim(),
        'telefone': telefone.trim(),
        'whatsapp': whatsapp.trim(),
        'instagram': instagram.trim(),
        'website': website.trim(),
        'mensagem_topo': mensagemTopo.trim(),
        'mensagem_final': mensagemFinal.trim(),
        'observacao_padrao': observacaoPadrao.trim(),
        'exibir_data_hora_emissao': exibirDataHoraEmissao,
        'tamanho_fonte': tamanhoFonte,
        'centralizar_cabecalho': centralizarCabecalho,
        'centralizar_rodape': centralizarRodape,
        'texto_destaque': textoDestaque.trim(),
        'termo_destaque_item': termoDestaqueItem.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory CupomDadosConfig.fromMap(Map<String, dynamic> map) {
    final padrao = CupomDadosConfig.padrao();
    return CupomDadosConfig(
      tituloCabecalho:
          (map['titulo_cabecalho'] as String?)?.trim().isNotEmpty == true
              ? (map['titulo_cabecalho'] as String).trim()
              : padrao.tituloCabecalho,
      subtituloCabecalho: (map['subtitulo_cabecalho'] as String?)?.trim() ?? '',
      cnpj: (map['cnpj'] as String?)?.trim() ?? '',
      enderecoLinha1: (map['endereco_linha1'] as String?)?.trim() ?? '',
      enderecoLinha2: (map['endereco_linha2'] as String?)?.trim() ?? '',
      telefone: (map['telefone'] as String?)?.trim() ?? '',
      whatsapp: (map['whatsapp'] as String?)?.trim() ?? '',
      instagram: (map['instagram'] as String?)?.trim() ?? '',
      website: (map['website'] as String?)?.trim() ?? '',
      mensagemTopo: (map['mensagem_topo'] as String?)?.trim() ?? '',
      mensagemFinal:
          (map['mensagem_final'] as String?)?.trim().isNotEmpty == true
              ? (map['mensagem_final'] as String).trim()
              : padrao.mensagemFinal,
      observacaoPadrao: (map['observacao_padrao'] as String?)?.trim() ?? '',
      exibirDataHoraEmissao: (map['exibir_data_hora_emissao'] as bool?) ?? true,
      tamanhoFonte: _asDouble(map['tamanho_fonte'], padrao.tamanhoFonte),
      centralizarCabecalho: (map['centralizar_cabecalho'] as bool?) ?? true,
      centralizarRodape: (map['centralizar_rodape'] as bool?) ?? true,
      textoDestaque: (map['texto_destaque'] as String?)?.trim() ?? '',
      termoDestaqueItem: (map['termo_destaque_item'] as String?)?.trim() ?? '',
    );
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

class CupomConfigService {
  static const _table = 'cupom_configuracoes';

  static String get _fiscalId {
    final id = SupabaseClientManager.currentUserId;
    if (id == null || id.isEmpty) {
      throw Exception('Usuario nao autenticado para configurar cupom.');
    }
    return id;
  }

  static Future<CupomDadosConfig> carregar() async {
    try {
      final row = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .maybeSingle();

      if (row == null) return CupomDadosConfig.padrao();
      return CupomDadosConfig.fromMap(row);
    } catch (_) {
      return CupomDadosConfig.padrao();
    }
  }

  static Future<void> salvar(CupomDadosConfig config) async {
    await SupabaseClientManager.client
        .from(_table)
        .upsert(config.toMap(_fiscalId), onConflict: 'fiscal_id');
  }

  static Future<CupomDadosConfig> restaurarPadrao() async {
    final padrao = CupomDadosConfig.padrao();
    await salvar(padrao);
    return padrao;
  }
}
