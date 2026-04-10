import 'package:flutter/material.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/entities/caixa.dart';

/// Dialog para justificar exceÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o (regra quebrada)
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
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('ExceÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de AlocaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivo da exceÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motivo:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.motivo,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Detalhes
            if (widget.colaborador != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Colaborador: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.colaborador!.nome,
                        style: TextStyle(color: Colors.black87),
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
                      TextSpan(
                        text: 'Caixa: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.caixa!.numero.toString(),
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),

            // Campo de justificativa
            Text(
              'Justifique o motivo:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _justificativaController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText:
                    'Em qual motivo o colaborador trabalha nesta caixa novamente?',
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
          child: Text('Cancelar'),
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
          child: Text('Justificar e Alocar'),
        ),
      ],
    );
  }

  String get justificativa => _justificativaController.text;
}
