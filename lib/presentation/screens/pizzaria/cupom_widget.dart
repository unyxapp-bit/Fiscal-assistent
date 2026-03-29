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

  String _gerarTexto(CupomDadosConfig config) {
    const linha = '================================';
    const linhaf = '--------------------------------';
    final pedido = widget.pedido;
    final buf = StringBuffer();

    buf.writeln(linha);
    buf.writeln('      ${config.tituloCabecalho}');
    if (config.linhaAdicional.trim().isNotEmpty) {
      buf.writeln('      ${config.linhaAdicional.trim()}');
    }
    buf.writeln(linha);
    buf.writeln('Cod. Entrega : ${pedido.codigoEntrega}');
    buf.writeln(
        'Data         : ${DateFormat('dd/MM/yyyy').format(pedido.dataPedido)}');
    buf.writeln('Horario      : ${pedido.horarioPedido}');
    buf.writeln('Cliente      : ${pedido.nomeCliente}');
    buf.writeln(linhaf);
    buf.writeln('ITENS:');
    buf.writeln(linhaf);

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

    buf.writeln(linhaf);
    if (pedido.observacoes != null && pedido.observacoes!.isNotEmpty) {
      buf.writeln('OBS: ${pedido.observacoes}');
      buf.writeln(linhaf);
    }
    buf.writeln(linha);
    buf.writeln('       ${config.mensagemFinal}');
    buf.writeln(linha);

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
                  icon: const Icon(Icons.close), onPressed: widget.onFechar),
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
