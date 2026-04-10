import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../data/services/cupom_config_service.dart';
import 'pizza_models.dart';

import 'cupom_print_stub.dart' if (dart.library.html) 'cupom_print_web.dart';

class CupomWidget extends StatefulWidget {
  final PedidoPizza pedido;
  final VoidCallback onFechar;

  const CupomWidget({super.key, required this.pedido, required this.onFechar});

  @override
  State<CupomWidget> createState() => _CupomWidgetState();
}

class _CupomWidgetState extends State<CupomWidget> {
  static const _linha = '================================';
  static const _linhaFina = '--------------------------------';
  static const _larguraCupom = 32;

  CupomDadosConfig? _config;
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _carregarConfig();
  }

  Future<void> _carregarConfig() async {
    final config = await CupomConfigService.carregar();
    if (!mounted) return;
    setState(() {
      _config = config;
      _loadingConfig = false;
    });
  }

  String _center(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return '';
    if (t.length >= _larguraCupom) return t;

    final total = _larguraCupom - t.length;
    final left = total ~/ 2;
    final right = total - left;
    return '${' ' * left}$t${' ' * right}';
  }

  void _writeIfNotEmpty(
    StringBuffer b,
    String value, {
    bool centralizar = false,
  }) {
    final v = value.trim();
    if (v.isEmpty) return;
    b.writeln(centralizar ? _center(v) : v);
  }

  void _writeLabeledIfHasValue(
    StringBuffer b, {
    required String label,
    required String value,
    bool centralizar = false,
  }) {
    final v = value.trim();
    if (v.isEmpty) return;
    final line = '$label$v';
    b.writeln(centralizar ? _center(line) : line);
  }

  String _linhaDestaque(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return '';
    return '>>> ${t.toUpperCase()} <<<';
  }

  String _textoOuPadrao(String? texto, {String padrao = '-'}) {
    final t = texto?.trim() ?? '';
    return t.isEmpty ? padrao : t;
  }

  String _gerarTexto(CupomDadosConfig config) {
    final pedido = widget.pedido;
    final buf = StringBuffer();

    buf.writeln(_linha);
    _writeIfNotEmpty(
      buf,
      config.tituloCabecalho,
      centralizar: config.centralizarCabecalho,
    );
    _writeIfNotEmpty(
      buf,
      config.subtituloCabecalho,
      centralizar: config.centralizarCabecalho,
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'CNPJ: ',
      value: config.cnpj,
      centralizar: config.centralizarCabecalho,
    );
    _writeIfNotEmpty(
      buf,
      config.enderecoLinha1,
      centralizar: config.centralizarCabecalho,
    );
    _writeIfNotEmpty(
      buf,
      config.enderecoLinha2,
      centralizar: config.centralizarCabecalho,
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'TEL: ',
      value: config.telefone,
      centralizar: config.centralizarCabecalho,
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'WHATS: ',
      value: config.whatsapp,
      centralizar: config.centralizarCabecalho,
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'INSTA: ',
      value: config.instagram,
      centralizar: config.centralizarCabecalho,
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'SITE: ',
      value: config.website,
      centralizar: config.centralizarCabecalho,
    );
    buf.writeln(_linha);

    if (config.exibirDataHoraEmissao) {
      buf.writeln(
        'Emissao      : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      );
    }

    buf.writeln('Cod. Cliente : ${_textoOuPadrao(pedido.codigoEntrega)}');
    buf.writeln(
      'Data         : ${DateFormat('dd/MM/yyyy').format(pedido.dataPedido)}',
    );
    buf.writeln('Horario      : ${pedido.horarioPedido}');
    buf.writeln('Cliente      : ${_textoOuPadrao(pedido.nomeCliente)}');
    _writeLabeledIfHasValue(
      buf,
      label: 'Endereco     : ',
      value: pedido.endereco ?? '',
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'Bairro       : ',
      value: pedido.bairro ?? '',
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'Telefone     : ',
      value: pedido.telefone ?? '',
    );
    _writeLabeledIfHasValue(
      buf,
      label: 'Referencia   : ',
      value: pedido.referencia ?? '',
    );
    buf.writeln(_linhaFina);

    if (config.mensagemTopo.trim().isNotEmpty) {
      buf.writeln('MSG: ${config.mensagemTopo.trim()}');
      buf.writeln(_linhaFina);
    }

    if (config.textoDestaque.trim().isNotEmpty) {
      buf.writeln(_linhaDestaque(config.textoDestaque));
      buf.writeln(_linhaFina);
    }

    buf.writeln('ITENS:');
    buf.writeln(_linhaFina);

    final termoDestaque = config.termoDestaqueItem.trim().toLowerCase();

    for (final item in pedido.itens) {
      final tamanho = item.tamanhoLabel.toUpperCase();
      final itemTexto =
          '${item.quantidade}x Pizza $tamanho - ${item.descricao}'.trim();
      final destacarItem = termoDestaque.isNotEmpty &&
          itemTexto.toLowerCase().contains(termoDestaque);

      if (item.ehMeioAMeio) {
        buf.writeln(
          destacarItem
              ? _linhaDestaque(
                  '${item.quantidade}x Pizza $tamanho (Meio a Meio)')
              : '${item.quantidade}x Pizza $tamanho (Meio a Meio)',
        );
        buf.writeln('   1/2 ${item.pizzaNome}');
        buf.writeln('   1/2 ${item.pizza2Nome}');
      } else {
        buf.writeln(
          destacarItem
              ? _linhaDestaque('${item.quantidade}x Pizza $tamanho')
              : '${item.quantidade}x Pizza $tamanho',
        );
        buf.writeln('   ${item.pizzaNome}');
      }
    }

    final observacoes = <String>[];
    if (pedido.observacoes != null && pedido.observacoes!.trim().isNotEmpty) {
      observacoes.add(pedido.observacoes!.trim());
    }
    if (config.observacaoPadrao.trim().isNotEmpty) {
      observacoes.add(config.observacaoPadrao.trim());
    }

    buf.writeln(_linhaFina);
    if (observacoes.isNotEmpty) {
      buf.writeln('OBS: ${observacoes.join(' | ')}');
      buf.writeln(_linhaFina);
    }

    buf.writeln(_linha);
    _writeIfNotEmpty(
      buf,
      config.mensagemFinal.trim().isEmpty
          ? 'BOM APETITE!'
          : config.mensagemFinal,
      centralizar: config.centralizarRodape,
    );
    buf.writeln(_linha);

    return buf.toString();
  }

  Widget _buildAcoes(String texto) {
    final copiarBtn = OutlinedButton.icon(
      icon: Icon(Icons.copy, size: 18),
      label: Text('Copiar'),
      onPressed: _loadingConfig
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: texto));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cupom copiado. Cole no WhatsApp.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
    );

    final imprimirBtn = OutlinedButton.icon(
      icon: Icon(Icons.print, size: 18),
      label: Text('Imprimir'),
      onPressed: _loadingConfig ? null : () => imprimirCupom(texto),
    );

    final concluirBtn = FilledButton.icon(
      icon: Icon(Icons.check_circle_outline, size: 18),
      label: Text('Concluir'),
      onPressed: widget.onFechar,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 460;
        if (compacto) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: copiarBtn),
              if (kIsWeb) ...[
                SizedBox(height: 8),
                SizedBox(width: double.infinity, child: imprimirBtn),
              ],
              SizedBox(height: 8),
              SizedBox(width: double.infinity, child: concluirBtn),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: copiarBtn),
            if (kIsWeb) ...[
              SizedBox(width: 8),
              Expanded(child: imprimirBtn),
            ],
            SizedBox(width: 8),
            Expanded(child: concluirBtn),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _config ?? CupomDadosConfig.padrao();
    final texto = _gerarTexto(config);
    final alturaMaximaSheet = MediaQuery.of(context).size.height * 0.9;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: alturaMaximaSheet),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Cupom do Pedido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: widget.onFechar,
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: _loadingConfig
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            texto,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: config.tamanhoFonte.clamp(9, 22),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 12),
              _buildAcoes(texto),
            ],
          ),
        ),
      ),
    );
  }
}
