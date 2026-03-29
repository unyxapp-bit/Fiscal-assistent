import 'package:shared_preferences/shared_preferences.dart';

class CupomDadosConfig {
  final String tituloCabecalho;
  final String linhaAdicional;
  final String mensagemFinal;

  const CupomDadosConfig({
    required this.tituloCabecalho,
    required this.linhaAdicional,
    required this.mensagemFinal,
  });

  factory CupomDadosConfig.padrao() {
    return const CupomDadosConfig(
      tituloCabecalho: 'PIZZARIA CARROSSEL',
      linhaAdicional: '',
      mensagemFinal: 'BOM APETITE!',
    );
  }

  CupomDadosConfig copyWith({
    String? tituloCabecalho,
    String? linhaAdicional,
    String? mensagemFinal,
  }) {
    return CupomDadosConfig(
      tituloCabecalho: tituloCabecalho ?? this.tituloCabecalho,
      linhaAdicional: linhaAdicional ?? this.linhaAdicional,
      mensagemFinal: mensagemFinal ?? this.mensagemFinal,
    );
  }
}

class CupomConfigService {
  static const _kTituloCabecalho = 'cupom_titulo_cabecalho';
  static const _kLinhaAdicional = 'cupom_linha_adicional';
  static const _kMensagemFinal = 'cupom_mensagem_final';

  static Future<CupomDadosConfig> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final padrao = CupomDadosConfig.padrao();

    return CupomDadosConfig(
      tituloCabecalho:
          prefs.getString(_kTituloCabecalho) ?? padrao.tituloCabecalho,
      linhaAdicional:
          prefs.getString(_kLinhaAdicional) ?? padrao.linhaAdicional,
      mensagemFinal: prefs.getString(_kMensagemFinal) ?? padrao.mensagemFinal,
    );
  }

  static Future<void> salvar(CupomDadosConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTituloCabecalho, config.tituloCabecalho.trim());
    await prefs.setString(_kLinhaAdicional, config.linhaAdicional.trim());
    await prefs.setString(_kMensagemFinal, config.mensagemFinal.trim());
  }

  static Future<CupomDadosConfig> restaurarPadrao() async {
    final padrao = CupomDadosConfig.padrao();
    await salvar(padrao);
    return padrao;
  }
}
