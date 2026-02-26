import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/caixa.dart';
import '../../../domain/enums/tipo_caixa.dart';
import '../../../data/models/caixa_model.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/auth_provider.dart';

class CaixaFormScreen extends StatefulWidget {
  final Caixa? caixa;

  const CaixaFormScreen({super.key, this.caixa});

  @override
  State<CaixaFormScreen> createState() => _CaixaFormScreenState();
}

class _CaixaFormScreenState extends State<CaixaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _lojaController = TextEditingController();
  final _observacoesController = TextEditingController();

  // valor de TipoCaixa.toJson() — 'pdv' | 'rapido' | 'preferencial' | 'self_service'
  String _tipoSelecionado = 'pdv';
  String? _localizacaoSelecionada;
  bool _emManutencao = false;
  bool _ativo = true;

  static const _localizacoes = ['Entrada', 'Meio', 'Fundo', 'Outro'];

  @override
  void initState() {
    super.initState();
    if (widget.caixa != null) {
      final c = widget.caixa!;
      _numeroController.text = c.numero.toString();
      _lojaController.text = c.loja ?? '';
      _observacoesController.text = c.observacoes ?? '';
      _tipoSelecionado = c.tipo.toJson();
      _localizacaoSelecionada =
          _localizacoes.contains(c.localizacao) ? c.localizacao : null;
      _emManutencao = c.emManutencao;
      _ativo = c.ativo;
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _lojaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final caixaProvider = Provider.of<CaixaProvider>(context, listen: false);
    final fiscalId = authProvider.user?.id;

    if (fiscalId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não autenticado'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final numero = int.tryParse(_numeroController.text);
    if (numero == null) return;

    final agora = DateTime.now();
    final loja = _lojaController.text.trim().isEmpty
        ? null
        : _lojaController.text.trim();
    final observacoes = _observacoesController.text.trim().isEmpty
        ? null
        : _observacoesController.text.trim();

    final Caixa caixa;
    if (widget.caixa == null) {
      caixa = CaixaModel(
        id: const Uuid().v4(),
        fiscalId: fiscalId,
        numero: numero,
        tipo: TipoCaixa.fromString(_tipoSelecionado),
        loja: loja,
        localizacao: _localizacaoSelecionada,
        ativo: _ativo,
        emManutencao: _emManutencao,
        observacoes: observacoes,
        createdAt: agora,
        updatedAt: agora,
      );
    } else {
      caixa = CaixaModel(
        id: widget.caixa!.id,
        fiscalId: widget.caixa!.fiscalId,
        numero: numero,
        tipo: TipoCaixa.fromString(_tipoSelecionado),
        loja: loja,
        localizacao: _localizacaoSelecionada,
        ativo: _ativo,
        emManutencao: _emManutencao,
        observacoes: observacoes,
        createdAt: widget.caixa!.createdAt,
        updatedAt: agora,
      );
    }

    try {
      await caixaProvider.upsertCaixa(caixa);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.caixa == null
                ? 'Caixa cadastrado com sucesso!'
                : 'Caixa atualizado com sucesso!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNovo = widget.caixa == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          isNovo ? 'Novo Caixa' : 'Editar Caixa ${widget.caixa?.numero ?? ''}',
          style: AppTextStyles.h3,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número do Caixa *',
                  hintText: 'Ex: 1, 2, 3...',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Número é obrigatório';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n < 1) return 'Número inválido';
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Tipo
              const Text('Tipo de Caixa *', style: AppTextStyles.body),
              const SizedBox(height: Dimensions.spacingSM),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TipoCard(
                          label: 'Normal',
                          descricao: 'Sem limite',
                          icon: Icons.shopping_cart,
                          color: const Color(0xFF2196F3),
                          selected: _tipoSelecionado == 'pdv',
                          onTap: () =>
                              setState(() => _tipoSelecionado = 'pdv'),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spacingSM),
                      Expanded(
                        child: _TipoCard(
                          label: 'Rápido',
                          descricao: 'Até 15 vol.',
                          icon: Icons.flash_on,
                          color: const Color(0xFF4CAF50),
                          selected: _tipoSelecionado == 'rapido',
                          onTap: () =>
                              setState(() => _tipoSelecionado = 'rapido'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingSM),
                  Row(
                    children: [
                      Expanded(
                        child: _TipoCard(
                          label: 'Preferencial',
                          descricao: 'Idosos, PCD',
                          icon: Icons.accessible_forward,
                          color: const Color(0xFFFF9800),
                          selected: _tipoSelecionado == 'preferencial',
                          onTap: () =>
                              setState(() => _tipoSelecionado = 'preferencial'),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spacingSM),
                      Expanded(
                        child: _TipoCard(
                          label: 'Self Checkout',
                          descricao: 'Autoatend.',
                          icon: Icons.computer,
                          color: const Color(0xFF9C27B0),
                          selected: _tipoSelecionado == 'self_service',
                          onTap: () =>
                              setState(() => _tipoSelecionado = 'self_service'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Loja
              TextFormField(
                controller: _lojaController,
                decoration: const InputDecoration(
                  labelText: 'Loja',
                  hintText: 'Ex: Baependi, Matriz...',
                  prefixIcon: Icon(Icons.store),
                ),
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Localização
              DropdownButtonFormField<String>(
                value: _localizacaoSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Localização no mercado',
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: _localizacoes
                    .map((loc) =>
                        DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _localizacaoSelecionada = value),
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Switches
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                      title: const Text('Ativo'),
                      subtitle: const Text('Caixa disponível para uso'),
                      secondary: Icon(
                        _ativo ? Icons.check_circle : Icons.cancel,
                        color: _ativo ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _emManutencao,
                      onChanged: (value) =>
                          setState(() => _emManutencao = value),
                      title: const Text('Em Manutenção'),
                      subtitle:
                          const Text('Caixa temporariamente indisponível'),
                      secondary: Icon(
                        _emManutencao
                            ? Icons.build
                            : Icons.check_circle_outline,
                        color: _emManutencao
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Observações
              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Informações adicionais sobre o caixa',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: Dimensions.spacingXL),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
                      child: Text(isNovo ? 'Cadastrar' : 'Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipoCard extends StatelessWidget {
  final String label;
  final String descricao;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TipoCard({
    required this.label,
    required this.descricao,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : AppColors.backgroundSection,
          borderRadius: BorderRadius.circular(Dimensions.radiusMD),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.cardBorder.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? color : AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
