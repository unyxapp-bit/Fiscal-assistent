import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/app_notif.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/buttons/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signUpWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      nome: _nomeController.text,
    );

    if (!mounted) return;

    if (success) {
      AppNotif.show(
        context,
        titulo: 'Conta criada',
        mensagem: 'Conta criada com sucesso',
        tipo: 'saida',
        cor: AppColors.success,
      );
      Navigator.of(context).pop();
      return;
    }

    AppNotif.show(
      context,
      titulo: 'Erro',
      mensagem: authProvider.errorMessage ?? 'Erro ao criar conta',
      tipo: 'alerta',
      cor: AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: authProvider.isLoading
            ? const LoadingWidget()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingXL),
                child: Form(
                  key: _formKey,
                  child: Container(
                    decoration: AppStyles.softCard(
                      tint: AppColors.primary,
                      radius: 22,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Crie sua conta', style: AppTextStyles.h2),
                        const SizedBox(height: 6),
                        Text(
                          'Preencha os dados para comecar',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        CustomTextField(
                          controller: _nomeController,
                          label: 'Nome completo',
                          hintText: 'Seu nome',
                          prefixIcon: Icons.person_outlined,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite seu nome';
                            }
                            if (value.length < 3) {
                              return 'Nome deve ter no minimo 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hintText: 'seu@email.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite seu email';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          hintText: 'Minimo 6 caracteres',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite uma senha';
                            }
                            if (value.length < 6) {
                              return 'Senha deve ter no minimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar senha',
                          hintText: 'Digite a senha novamente',
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: Icons.lock_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirme sua senha';
                            }
                            if (value != _passwordController.text) {
                              return 'As senhas nao coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.spacingXL),
                        PrimaryButton(
                          text: 'Criar conta',
                          onPressed: _handleRegister,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
