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

  void _writeIfNotEmpty(StringBuffer b, String value, {bool center = false}) {
    final v = value.trim();
    if (v.isEmpty) return;
    b.writeln(center ? _center(v) : v);
  }

  String _gerarTexto(CupomDadosConfig config) {
    final pedido = widget.pedido;
    final buf = StringBuffer();

    buf.writeln(_linha);
    _writeIfNotEmpty(buf, config.tituloCabecalho, center: true);
    _writeIfNotEmpty(buf, config.subtituloCabecalho, center: true);
    _writeIfNotEmpty(buf, 'CNPJ: ${config.cnpj}', center: true);
    _writeIfNotEmpty(buf, config.enderecoLinha1, center: true);
    _writeIfNotEmpty(buf, config.enderecoLinha2, center: true);
    _writeIfNotEmpty(buf, 'TEL: ${config.telefone}', center: true);
    _writeIfNotEmpty(buf, 'WHATS: ${config.whatsapp}', center: true);
    _writeIfNotEmpty(buf, 'INSTA: ${config.instagram}', center: true);
    _writeIfNotEmpty(buf, 'SITE: ${config.website}', center: true);
    buf.writeln(_linha);

    if (config.exibirDataHoraEmissao) {
      buf.writeln(
        'Emissao      : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      );
    }

    buf.writeln('Cod. Entrega : ${pedido.codigoEntrega}');
    buf.writeln(
      'Data         : ${DateFormat('dd/MM/yyyy').format(pedido.dataPedido)}',
    );
    buf.writeln('Horario      : ${pedido.horarioPedido}');
    buf.writeln('Cliente      : ${pedido.nomeCliente}');
    buf.writeln(_linhaFina);

    if (config.mensagemTopo.trim().isNotEmpty) {
      buf.writeln('MSG: ${config.mensagemTopo.trim()}');
      buf.writeln(_linhaFina);
    }

    buf.writeln('ITENS:');
    buf.writeln(_linhaFina);

    for (final item in pedido.itens) {
      final tamanho = item.tamanhoLabel.toUpperCase();
      if (item.ehMeioAMeio) {
        buf.writeln('${item.quantidade}x Pizza $tamanho (Meio a Meio)');
        buf.writeln('   1/2 ${item.pizzaNome}');
        buf.writeln('   1/2 ${item.pizza2Nome}');
      } else {
        buf.writeln('${item.quantidade}x Pizza $tamanho');
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
      center: true,
    );
    buf.writeln(_linha);

    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config ?? CupomDadosConfig.padrao();
    final texto = _gerarTexto(config);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Cupom do Pedido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onFechar,
              ),
            ],
          ),
          const Divider(),
          if (_loadingConfig)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                texto,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar'),
                  onPressed: _loadingConfig
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: texto));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cupom copiado. Cole no WhatsApp.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 8),
              if (kIsWeb)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Imprimir'),
                    onPressed:
                        _loadingConfig ? null : () => imprimirCupom(texto),
                  ),
                ),
              if (kIsWeb) const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Concluir'),
                  onPressed: widget.onFechar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
