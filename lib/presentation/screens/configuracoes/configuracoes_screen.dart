import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/fiscal_provider.dart';
import '../profile/profile_screen.dart';
import 'cupom_config_screen.dart';

/// Tela de Configurações — exibe informações da loja e atalhos de perfil
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<FiscalProvider>(
        builder: (context, fiscalProvider, _) {
          final fiscal = fiscalProvider.fiscal;

          return LayoutBuilder(
              builder: (context, constraints) => ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.hPad(constraints.maxWidth),
                      vertical: Dimensions.paddingMD,
                    ),
                    children: [
                      // ── Informações da Loja ────────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.store_outlined,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Informações da Loja',
                                        style: AppTextStyles.h4),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ProfileScreen()),
                                    ),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 16),
                                    label: const Text('Editar',
                                        style: TextStyle(fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Dimensions.spacingMD),
                              if (fiscal == null)
                                const Center(child: CircularProgressIndicator())
                              else ...[
                                _InfoRow(
                                    label: 'Loja',
                                    value: fiscal.loja ?? 'Não informado'),
                                const Divider(height: 24),
                                _InfoRow(label: 'Fiscal', value: fiscal.nome),
                                const Divider(height: 24),
                                _InfoRow(label: 'E-mail', value: fiscal.email),
                                const Divider(height: 24),
                                _InfoRow(
                                  label: 'Telefone',
                                  value: fiscal.telefone ?? 'Não informado',
                                  valueColor: fiscal.telefone == null
                                      ? AppColors.textSecondary
                                      : null,
                                ),
                                const Divider(height: 24),
                                _InfoRow(
                                  label: 'Status',
                                  value: fiscal.ativo ? 'Ativo' : 'Inativo',
                                  valueColor: fiscal.ativo
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: Dimensions.spacingMD),

                      // ── Atalhos ────────────────────────────────────────────────────
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person_outline,
                                  color: AppColors.primary),
                              title: const Text('Editar Perfil',
                                  style: AppTextStyles.body),
                              subtitle: const Text('Nome, telefone, loja',
                                  style: AppTextStyles.caption),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: AppColors.textSecondary),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen()),
                              ),
                            ),
                            const Divider(height: 1, indent: 56),
                            ListTile(
                              leading: const Icon(Icons.receipt_long_outlined,
                                  color: AppColors.primary),
                              title: const Text('Dados do Cupom',
                                  style: AppTextStyles.body),
                              subtitle: const Text(
                                  'Layout completo da impressao',
                                  style: AppTextStyles.caption),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: AppColors.textSecondary),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const CupomConfigScreen()),
                              ),
                            ),
                            const Divider(height: 1, indent: 56),
                            ListTile(
                              leading: const Icon(Icons.lock_outline,
                                  color: AppColors.textSecondary),
                              title: const Text('Alterar Senha',
                                  style: AppTextStyles.body),
                              subtitle: const Text('Altere a senha de acesso',
                                  style: AppTextStyles.caption),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: AppColors.textSecondary),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ));
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.h4
                .copyWith(color: valueColor ?? AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
