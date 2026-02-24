import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../providers/caixa_provider.dart';
import '../caixa_form_screen.dart';

/// Card de caixa individual
class CaixaCard extends StatelessWidget {
  final Caixa caixa;

  const CaixaCard({
    super.key,
    required this.caixa,
  });

  Color _getStatusColor() {
    if (!caixa.ativo) {
      return AppColors.textSecondary;
    }
    if (caixa.emManutencao) {
      return Colors.orange;
    }
    return AppColors.success;
  }

  String _getStatusLabel() {
    if (!caixa.ativo) {
      return 'Inativo';
    }
    if (caixa.emManutencao) {
      return 'Manutenção';
    }
    return 'Ativo';
  }

  void _abrirEdicao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaixaFormScreen(caixa: caixa),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          children: [
            Row(
              children: [
                // Ícone e número
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        caixa.tipo.icone,
                        color: _getStatusColor(),
                        size: 28,
                      ),
                      Text(
                        'Cx ${caixa.numero}',
                        style: AppTextStyles.label.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: Dimensions.spacingMD),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caixa.tipo.nome,
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Badge de status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: AppTextStyles.caption.copyWith(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (caixa.colaboradorAlocadoNome != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                caixa.colaboradorAlocadoNome!,
                                style:
                                    AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton(
                  itemBuilder: (BuildContext context) => [
                    // Editar sempre disponível
                    PopupMenuItem(
                      onTap: () => _abrirEdicao(context),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (caixa.ativo && !caixa.emManutencao)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.close, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Desativar'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleStatus(caixa.id, false);
                        },
                      ),
                    if (!caixa.ativo)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Ativar'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleStatus(caixa.id, true);
                        },
                      ),
                    if (caixa.ativo && !caixa.emManutencao)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.build, size: 20, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Marcar manutenção'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleManutencao(caixa.id, true);
                        },
                      ),
                    if (caixa.emManutencao)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.check, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Fim da manutenção'),
                          ],
                        ),
                        onTap: () {
                          final provider = Provider.of<CaixaProvider>(
                            context,
                            listen: false,
                          );
                          provider.toggleManutencao(caixa.id, false);
                        },
                      ),
                  ],
                ),
              ],
            ),
            if (caixa.observacoes != null) ...[
              const SizedBox(height: Dimensions.spacingSM),
              Text(
                caixa.observacoes!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
