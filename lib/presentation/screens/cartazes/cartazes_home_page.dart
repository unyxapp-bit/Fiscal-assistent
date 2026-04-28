import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import '../../widgets/cartazes/cartaz_template_specs.dart';
import 'criar_cartaz_page.dart';

class CartazesHomePage extends StatefulWidget {
  const CartazesHomePage({super.key});

  @override
  State<CartazesHomePage> createState() => _CartazesHomePageState();
}

class _CartazesHomePageState extends State<CartazesHomePage> {
  CartazTemplateTipo? _tipoSelecionado;
  CartazTamanho _tamanhoSelecionado = CartazTamanho.a6;

  void _iniciar() {
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha um modelo primeiro')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CriarCartazPage(
          tipo: _tipoSelecionado!,
          tamanho: _tamanhoSelecionado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cartazes promocionais'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('1. Escolha o modelo'),
                  const SizedBox(height: 12),
                  for (final spec in cartazTemplateSpecs) ...[
                    _TemplateCard(
                      spec: spec,
                      selecionado: _tipoSelecionado == spec.tipo,
                      onTap: () => setState(() => _tipoSelecionado = spec.tipo),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 18),
                  _sectionLabel('2. Escolha o tamanho'),
                  const SizedBox(height: 12),
                  _TamanhoSelector(
                    selecionado: _tamanhoSelecionado,
                    onChanged: (t) => setState(() => _tamanhoSelecionado = t),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _tipoSelecionado != null ? _iniciar : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text(
            'Preencher dados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD6166A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final CartazTemplateSpec spec;
  final bool selecionado;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.spec,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? spec.color.withAlpha(18) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: selecionado ? 0 : 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                selecionado ? Border.all(color: spec.color, width: 2) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: spec.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Icon(spec.icon, color: spec.iconColor, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selecionado ? spec.color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      spec.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  selecionado
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selecionado ? spec.color : Colors.grey.shade300,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TamanhoSelector extends StatelessWidget {
  final CartazTamanho selecionado;
  final ValueChanged<CartazTamanho> onChanged;

  const _TamanhoSelector({
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CartazTamanho.values.map((t) {
        final sel = t == selecionado;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFD6166A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? const Color(0xFFD6166A) : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: sel ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.descricao,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: sel ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
