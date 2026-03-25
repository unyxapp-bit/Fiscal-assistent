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
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!success && mounted) {
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: authProvider.errorMessage ?? 'Erro ao fazer login',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: authProvider.isLoading
            ? const LoadingWidget()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingXL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      Container(
                        decoration: AppStyles.softCard(
                          tint: AppColors.inactive,
                          radius: 24,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 26,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                size: 46,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Bem-vindo',
                              style: AppTextStyles.h2,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Entre para continuar',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 22),
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
                                  return 'Digite sua senha';
                                }
                                if (value.length < 6) {
                                  return 'Senha deve ter no minimo 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: Dimensions.spacingLG),
                            PrimaryButton(
                              text: 'Entrar',
                              onPressed: _handleLogin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: RichText(
                          text: const TextSpan(
                            style: AppTextStyles.body,
                            children: [
                              TextSpan(
                                text: 'Nao tem uma conta? ',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              TextSpan(
                                text: 'Criar conta',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
