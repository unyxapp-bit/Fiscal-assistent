// lib/modules/pizza/cupom_widget.dart
//
// Substitua o CupomWidget que estava dentro de novo_pedido_screen.dart
// por este arquivo separado. Atualize os imports onde necessário.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'pizza_models.dart';

// Import condicional: usa web em produção web, stub no mobile/desktop
import 'cupom_print_stub.dart' if (dart.library.html) 'cupom_print_web.dart';

class CupomWidget extends StatelessWidget {
  final PedidoPizza pedido;
  final VoidCallback onFechar;

  const CupomWidget({super.key, required this.pedido, required this.onFechar});

  String _gerarTexto() {
    const linha = '================================';
    const linhaf = '--------------------------------';
    final buf = StringBuffer();

    buf.writeln(linha);
    buf.writeln('      PIZZARIA CARROSSEL');
    buf.writeln(linha);
    buf.writeln('Cod. Entrega : ${pedido.codigoEntrega}');
    buf.writeln(
        'Data         : ${DateFormat('dd/MM/yyyy').format(pedido.dataPedido)}');
    buf.writeln('Horário      : ${pedido.horarioPedido}');
    buf.writeln('Cliente      : ${pedido.nomeCliente}');
    buf.writeln(linhaf);
    buf.writeln('ITENS:');
    buf.writeln(linhaf);

    for (final item in pedido.itens) {
      final tamanho = item.tamanhoLabel.toUpperCase();
      if (item.ehMeioAMeio) {
        buf.writeln('${item.quantidade}x Pizza $tamanho (Meio a Meio)');
        buf.writeln('   ½ ${item.pizzaNome}');
        buf.writeln('   ½ ${item.pizza2Nome}');
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
    buf.writeln('       BOM APETITE!');
    buf.writeln(linha);

    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final texto = _gerarTexto();

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
          // Cabeçalho
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Cupom do Pedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: onFechar),
            ],
          ),
          const Divider(),

          // Texto do cupom
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

          // Botões de ação
          Row(
            children: [
              // Copiar (funciona em web e mobile)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: texto));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cupom copiado! Cole no WhatsApp.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Imprimir (só funciona no web, no mobile é invisível)
              if (kIsWeb)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Imprimir'),
                    onPressed: () => imprimirCupom(texto),
                  ),
                ),

              if (kIsWeb) const SizedBox(width: 8),

              // Concluir
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Concluir'),
                  onPressed: onFechar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
