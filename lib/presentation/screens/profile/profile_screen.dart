import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fiscal_provider.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de Perfil do Fiscal
/// Permite visualizar e editar informações do perfil
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  String? _lojaSelecionada;
  bool _isEditMode = false;
  bool _isChangingPassword = false;
  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;

  final List<String> _lojas = ['Baependi', 'Caxambu', 'Cruzília'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final fiscalProvider = Provider.of<FiscalProvider>(context, listen: false);
    final fiscal = fiscalProvider.fiscal;

    if (fiscal != null) {
      _nomeController.text = fiscal.nome;
      _telefoneController.text = fiscal.telefone ?? '';
      _lojaSelecionada = fiscal.loja;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    final fiscalProvider = Provider.of<FiscalProvider>(context, listen: false);
    final fiscal = fiscalProvider.fiscal;

    if (fiscal == null) return;

    final fiscalAtualizado = fiscal.copyWith(
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim().isEmpty
          ? null
          : _telefoneController.text.trim(),
      loja: _lojaSelecionada,
      updatedAt: DateTime.now(),
    );

    final sucesso = await fiscalProvider.updateProfile(fiscalAtualizado);

    if (!mounted) return;

    if (sucesso) {
      AppNotif.show(
        context,
        titulo: 'Perfil Atualizado',
        mensagem: 'Perfil atualizado com sucesso!',
        tipo: 'saida',
        cor: AppColors.success,
      );
      setState(() => _isEditMode = false);
    } else {
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: fiscalProvider.errorMessage ?? 'Erro ao atualizar perfil',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    }
  }

  Future<void> _alterarSenha() async {
    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      AppNotif.show(
        context,
        titulo: 'Senha Inválida',
        mensagem: 'As senhas não coincidem',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    if (_novaSenhaController.text.length < 6) {
      AppNotif.show(
        context,
        titulo: 'Senha Inválida',
        mensagem: 'A senha deve ter pelo menos 6 caracteres',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    // TODO: Implementar alteração de senha via AuthProvider
    AppNotif.show(
      context,
      titulo: 'Em Desenvolvimento',
      mensagem: 'Funcionalidade em desenvolvimento',
      tipo: 'intervalo',
      cor: AppColors.warning,
    );

    setState(() {
      _isChangingPassword = false;
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Meu Perfil', style: AppTextStyles.h3),
        actions: [
          if (!_isEditMode && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
              tooltip: 'Editar Perfil',
            ),
        ],
      ),
      body: Consumer2<FiscalProvider, AuthProvider>(
        builder: (context, fiscalProvider, authProvider, _) {
          if (fiscalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final fiscal = fiscalProvider.fiscal;
          if (fiscal == null) {
            return const Center(
              child: Text('Nenhum perfil encontrado'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        fiscal.nome.isNotEmpty ? fiscal.nome[0].toUpperCase() : 'U',
                        style: AppTextStyles.h1.copyWith(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.spacingXL),

                  // Informações do Perfil
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informações Pessoais', style: AppTextStyles.h4),
                          const SizedBox(height: Dimensions.spacingMD),

                          // Nome
                          TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome Completo',
                              prefixIcon: Icon(Icons.person),
                            ),
                            enabled: _isEditMode,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nome é obrigatório';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: Dimensions.spacingMD),

                          // Email (readonly)
                          TextFormField(
                            initialValue: fiscal.email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              helperText: 'O email não pode ser alterado',
                            ),
                            enabled: false,
                          ),

                          const SizedBox(height: Dimensions.spacingMD),

                          // Telefone
                          TextFormField(
                            controller: _telefoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone (opcional)',
                              prefixIcon: Icon(Icons.phone),
                              hintText: '(00) 00000-0000',
                            ),
                            keyboardType: TextInputType.phone,
                            enabled: _isEditMode,
                          ),

                          const SizedBox(height: Dimensions.spacingMD),

                          // Loja
                          DropdownButtonFormField<String>(
                            initialValue: _lojaSelecionada,
                            decoration: const InputDecoration(
                              labelText: 'Loja',
                              prefixIcon: Icon(Icons.store),
                            ),
                            items: _lojas.map((loja) {
                              return DropdownMenuItem(
                                value: loja,
                                child: Text(loja),
                              );
                            }).toList(),
                            onChanged: _isEditMode
                                ? (value) => setState(() => _lojaSelecionada = value)
                                : null,
                          ),

                          if (_isEditMode) ...[
                            const SizedBox(height: Dimensions.spacingLG),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _loadProfileData();
                                      setState(() => _isEditMode = false);
                                    },
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: Dimensions.spacingSM),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _salvarPerfil,
                                    child: const Text('Salvar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.spacingLG),

                  // Alteração de Senha
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Segurança', style: AppTextStyles.h4),
                          const SizedBox(height: Dimensions.spacingMD),

                          if (!_isChangingPassword) ...[
                            ListTile(
                              leading: const Icon(Icons.lock, color: AppColors.primary),
                              title: const Text('Alterar Senha'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => setState(() => _isChangingPassword = true),
                            ),
                          ] else ...[
                            // Senha Atual
                            TextFormField(
                              controller: _senhaAtualController,
                              decoration: InputDecoration(
                                labelText: 'Senha Atual',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureSenhaAtual ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(() => _obscureSenhaAtual = !_obscureSenhaAtual),
                                ),
                              ),
                              obscureText: _obscureSenhaAtual,
                            ),

                            const SizedBox(height: Dimensions.spacingMD),

                            // Nova Senha
                            TextFormField(
                              controller: _novaSenhaController,
                              decoration: InputDecoration(
                                labelText: 'Nova Senha',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNovaSenha ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(() => _obscureNovaSenha = !_obscureNovaSenha),
                                ),
                              ),
                              obscureText: _obscureNovaSenha,
                            ),

                            const SizedBox(height: Dimensions.spacingMD),

                            // Confirmar Senha
                            TextFormField(
                              controller: _confirmarSenhaController,
                              decoration: InputDecoration(
                                labelText: 'Confirmar Nova Senha',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmarSenha ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmarSenha = !_obscureConfirmarSenha),
                                ),
                              ),
                              obscureText: _obscureConfirmarSenha,
                            ),

                            const SizedBox(height: Dimensions.spacingLG),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isChangingPassword = false;
                                        _senhaAtualController.clear();
                                        _novaSenhaController.clear();
                                        _confirmarSenhaController.clear();
                                      });
                                    },
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: Dimensions.spacingSM),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _alterarSenha,
                                    child: const Text('Alterar Senha'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.spacingLG),

                  // Botão de Logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sair'),
                            content: const Text('Deseja realmente sair do aplicativo?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  authProvider.signOut();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                ),
                                child: const Text('Sair'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da Conta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingMD),
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.spacingMD),

                  // Info da conta
                  Center(
                    child: Text(
                      'Conta criada em: ${_formatDate(fiscal.createdAt)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
