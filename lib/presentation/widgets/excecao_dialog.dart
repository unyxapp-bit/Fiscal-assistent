import 'package:flutter/material.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/entities/caixa.dart';

/// Dialog para justificar exceção (regra quebrada)
class ExcecaoDialog extends StatefulWidget {
  final Colaborador? colaborador;
  final Caixa? caixa;
  final String motivo;
  final String tipo;
  final void Function(String justificativa) onConfirm;
  final VoidCallback onCancel;

  const ExcecaoDialog({
    super.key,
    required this.colaborador,
    required this.caixa,
    required this.motivo,
    required this.tipo,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ExcecaoDialog> createState() => _ExcecaoDialogState();
}

class _ExcecaoDialogState extends State<ExcecaoDialog> {
  final _justificativaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _justificativaController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Exceção de Alocação'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivo da exceção
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Motivo:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.motivo,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detalhes
            if (widget.colaborador != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Colaborador: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.colaborador!.nome,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.caixa != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Caixa: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.caixa!.numero.toString(),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),

            // Campo de justificativa
            const Text(
              'Justifique o motivo:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _justificativaController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Em qual motivo o colaborador trabalha nesta caixa novamente?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onCancel();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _justificativaController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirm(_justificativaController.text.trim());
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Justificar e Alocar'),
        ),
      ],
    );
  }

  String get justificativa => _justificativaController.text;
}
