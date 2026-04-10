import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de criar/editar colaborador
class ColaboradorFormScreen extends StatefulWidget {
  final String? colaboradorId;

  const ColaboradorFormScreen({
    super.key,
    this.colaboradorId,
  });

  @override
  State<ColaboradorFormScreen> createState() => _ColaboradorFormScreenState();
}

class _ColaboradorFormScreenState extends State<ColaboradorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _observacoesController = TextEditingController();

  Colaborador? _colaboradorAtual;
  DepartamentoTipo _departamentoSelecionado = DepartamentoTipo.caixa;
  bool _ativo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.colaboradorId != null) {
      _loadColaborador();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _loadColaborador() async {
    if (widget.colaboradorId == null) return;

    final provider = Provider.of<ColaboradorProvider>(context, listen: false);
    try {
      final colaborador = provider.colaboradores
          .firstWhere((c) => c.id == widget.colaboradorId);

      setState(() {
        _colaboradorAtual = colaborador;
        _nomeController.text = colaborador.nome;
        _departamentoSelecionado = colaborador.departamento;
        _observacoesController.text = colaborador.observacoes ?? '';
        _ativo = colaborador.ativo;
      });
    } catch (e) {
      if (mounted) {
        AppNotif.show(
          context,
          titulo: 'Erro',
          mensagem: 'Erro ao carregar colaborador',
          tipo: 'alerta',
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final collaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      _showError('UsuÃƒÂ¡rio nÃƒÂ£o autenticado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = _colaboradorAtual != null
          ? await _updateColaborador(collaboradorProvider)
          : await _createColaborador(
              collaboradorProvider, authProvider.user!.id);

      if (!mounted) return;

      if (success) {
        AppNotif.show(
          context,
          titulo: 'Colaborador Salvo',
          mensagem: _colaboradorAtual != null
              ? 'Colaborador atualizado!'
              : 'Colaborador criado!',
          tipo: 'saida',
          cor: AppColors.success,
        );
        Navigator.of(context).pop();
      } else {
        _showError(collaboradorProvider.errorMessage ?? 'Erro ao salvar');
      }
    } catch (e) {
      _showError('Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _createColaborador(
    ColaboradorProvider provider,
    String userId,
  ) async {
    return await provider.createColaborador(
      fiscalId: userId,
      nome: _nomeController.text.trim(),
      departamento: _departamentoSelecionado,
      observacoes: _observacoesController.text.isEmpty
          ? null
          : _observacoesController.text.trim(),
      ativo: _ativo,
    );
  }

  Future<bool> _updateColaborador(ColaboradorProvider provider) async {
    final colaboradorAtualizado = _colaboradorAtual!.copyWith(
      nome: _nomeController.text.trim(),
      departamento: _departamentoSelecionado,
      ativo: _ativo,
      observacoes: _observacoesController.text.isEmpty
          ? null
          : _observacoesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    return await provider.updateColaborador(colaboradorAtualizado);
  }

  void _showError(String message) {
    AppNotif.show(
      context,
      titulo: 'Erro',
      mensagem: message,
      tipo: 'alerta',
      cor: AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_colaboradorAtual == null
            ? 'Novo Colaborador'
            : 'Editar Colaborador'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                Text('Nome do Colaborador', style: AppTextStyles.subtitle),
                SizedBox(height: Dimensions.spacingSM),
                CustomTextField(
                  controller: _nomeController,
                  label: 'Nome',
                  hintText: 'Ex: Francielly',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome ÃƒÂ© obrigatÃƒÂ³rio';
                    }
                    if (value.length < 3) {
                      return 'Nome deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  },
                ),

                SizedBox(height: Dimensions.spacingLG),

                // Departamento
                Text('Departamento', style: AppTextStyles.subtitle),
                SizedBox(height: Dimensions.spacingSM),
                _buildDepartamentoSelector(),

                SizedBox(height: Dimensions.spacingLG),

                // ObservaÃƒÂ§ÃƒÂµes
                Text('ObservaÃƒÂ§ÃƒÂµes (Opcional)',
                    style: AppTextStyles.subtitle),
                SizedBox(height: Dimensions.spacingSM),
                CustomTextField(
                  controller: _observacoesController,
                  label: 'Observacoes',
                  hintText: 'Ex: Self, Vipp, etc',
                  prefixIcon: Icons.note,
                  maxLines: 3,
                  validator: null,
                ),

                SizedBox(height: Dimensions.spacingLG),

                // --- SeÃƒÂ§ÃƒÂ£o Status ---
                Text('Status', style: AppTextStyles.subtitle),
                SizedBox(height: Dimensions.spacingSM),
                _buildStatusCard(),

                SizedBox(height: Dimensions.spacingXL),

                // BotÃƒÂµes
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSM,
                          ),
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: Dimensions.spacingMD),
                    Expanded(
                      child: PrimaryButton(
                        onPressed: _isLoading ? () {} : _handleSave,
                        text: _colaboradorAtual == null ? 'Criar' : 'Atualizar',
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: AppColors.cardBackground,
      child: SwitchListTile(
        title: Text('Colaborador Ativo'),
        subtitle: Text(
          _ativo
              ? 'Aparece nas listas e escalas'
              : 'Oculto das listas e escalas',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        value: _ativo,
        activeThumbColor: AppColors.success,
        onChanged: (val) => setState(() => _ativo = val),
      ),
    );
  }

  Widget _buildDepartamentoSelector() {
    return Wrap(
      spacing: Dimensions.spacingMD,
      runSpacing: Dimensions.spacingMD,
      children: DepartamentoTipo.values.map((tipo) {
        final isSelected = _departamentoSelecionado == tipo;
        final label = tipo.toString().split('.').last.toUpperCase();

        return GestureDetector(
          onTap: () {
            setState(() => _departamentoSelecionado = tipo);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingMD,
              vertical: Dimensions.paddingSM,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
