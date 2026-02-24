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

/// Tela de Formulário de Caixa
class CaixaFormScreen extends StatefulWidget {
  final Caixa? caixa; // Null para novo, preenchido para edição

  const CaixaFormScreen({
    super.key,
    this.caixa,
  });

  @override
  State<CaixaFormScreen> createState() => _CaixaFormScreenState();
}

class _CaixaFormScreenState extends State<CaixaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _tipoSelecionado = 'normal';
  bool _emManutencao = false;
  bool _ativo = true;

  final List<Map<String, String>> _tipos = [
    {'value': 'rapido', 'label': 'Caixa Rápido'},
    {'value': 'normal', 'label': 'Caixa Normal'},
    {'value': 'self', 'label': 'Self-Service'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.caixa != null) {
      _numeroController.text = widget.caixa!.numero.toString();
      _observacoesController.text = widget.caixa!.observacoes ?? '';
      _tipoSelecionado = widget.caixa!.tipo.toJson();
      _emManutencao = widget.caixa!.emManutencao;
      _ativo = widget.caixa!.ativo;
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
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
          isNovo ? 'Novo Caixa' : 'Editar Caixa',
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
                  final numero = int.tryParse(value);
                  if (numero == null || numero < 1) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingLG),

              const Text('Tipo de Caixa *', style: AppTextStyles.body),
              const SizedBox(height: Dimensions.spacingSM),
              ..._tipos.map((tipo) {
                return RadioListTile<String>(
                  value: tipo['value']!,
                  groupValue: _tipoSelecionado,
                  title: Text(tipo['label']!),
                  onChanged: (value) {
                    setState(() => _tipoSelecionado = value!);
                  },
                );
              }),

              const SizedBox(height: Dimensions.spacingLG),

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
