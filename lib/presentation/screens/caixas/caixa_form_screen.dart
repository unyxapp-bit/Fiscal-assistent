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
import '../../../core/utils/app_notif.dart';

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

  // valor de TipoCaixa.toJson() ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â 'pdv' | 'rapido' | 'preferencial' | 'self_service' | 'balcao'
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
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: 'Erro: UsuÃƒÆ’Ã‚Â¡rio nÃƒÆ’Ã‚Â£o autenticado',
        tipo: 'alerta',
        cor: AppColors.danger,
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
      AppNotif.show(
        context,
        titulo: 'Caixa Salvo',
        mensagem: widget.caixa == null
            ? 'Caixa cadastrado com sucesso!'
            : 'Caixa atualizado com sucesso!',
        tipo: 'saida',
        cor: AppColors.success,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: 'Erro ao salvar: $e',
        tipo: 'alerta',
        cor: AppColors.danger,
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
              // NÃƒÆ’Ã‚Âºmero
              TextFormField(
                controller: _numeroController,
                decoration: InputDecoration(
                  labelText: 'NÃƒÆ’Ã‚Âºmero do Caixa *',
                  hintText: 'Ex: 1, 2, 3...',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NÃƒÆ’Ã‚Âºmero ÃƒÆ’Ã‚Â© obrigatÃƒÆ’Ã‚Â³rio';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n < 1)
                    return 'NÃƒÆ’Ã‚Âºmero invÃƒÆ’Ã‚Â¡lido';
                  return null;
                },
              ),

              SizedBox(height: Dimensions.spacingLG),

              // Tipo
              Text('Tipo de Caixa *', style: AppTextStyles.body),
              SizedBox(height: Dimensions.spacingSM),
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
                          onTap: () => setState(() => _tipoSelecionado = 'pdv'),
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingSM),
                      Expanded(
                        child: _TipoCard(
                          label: 'RÃƒÆ’Ã‚Â¡pido',
                          descricao: 'AtÃƒÆ’Ã‚Â© 15 vol.',
                          icon: Icons.flash_on,
                          color: const Color(0xFF4CAF50),
                          selected: _tipoSelecionado == 'rapido',
                          onTap: () =>
                              setState(() => _tipoSelecionado = 'rapido'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingSM),
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
                      SizedBox(width: Dimensions.spacingSM),
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
                  SizedBox(height: Dimensions.spacingSM),
                  Row(
                    children: [
                      Expanded(
                        child: _TipoCard(
                          label: 'BalcÃƒÆ’Ã‚Â£o',
                          descricao: 'AtÃƒÆ’Ã‚Â© 3 fiscais',
                          icon: Icons.support_agent,
                          color: const Color(0xFF009688),
                          selected: _tipoSelecionado == 'balcao',
                          onTap: () =>
                              setState(() => _tipoSelecionado = 'balcao'),
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingSM),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),

              SizedBox(height: Dimensions.spacingLG),

              // Loja
              TextFormField(
                controller: _lojaController,
                decoration: InputDecoration(
                  labelText: 'Loja',
                  hintText: 'Ex: Baependi, Matriz...',
                  prefixIcon: Icon(Icons.store),
                ),
              ),

              SizedBox(height: Dimensions.spacingLG),

              // LocalizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o
              DropdownButtonFormField<String>(
                initialValue: _localizacaoSelecionada,
                decoration: InputDecoration(
                  labelText: 'LocalizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o no mercado',
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: _localizacoes
                    .map(
                        (loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _localizacaoSelecionada = value),
              ),

              SizedBox(height: Dimensions.spacingLG),

              // Switches
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                      title: Text('Ativo'),
                      subtitle: Text('Caixa disponÃƒÆ’Ã‚Â­vel para uso'),
                      secondary: Icon(
                        _ativo ? Icons.check_circle : Icons.cancel,
                        color: _ativo ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    Divider(height: 1),
                    SwitchListTile(
                      value: _emManutencao,
                      onChanged: (value) =>
                          setState(() => _emManutencao = value),
                      title: Text('Em ManutenÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o'),
                      subtitle:
                          Text('Caixa temporariamente indisponÃƒÆ’Ã‚Â­vel'),
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

              SizedBox(height: Dimensions.spacingLG),

              // ObservaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(
                  labelText: 'ObservaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes (opcional)',
                  hintText:
                      'InformaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes adicionais sobre o caixa',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              SizedBox(height: Dimensions.spacingXL),

              // BotÃƒÆ’Ã‚Âµes
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingSM),
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
            SizedBox(width: 8),
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
                    style: TextStyle(
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
