import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/checklist_provider.dart';

class ChecklistExecucaoScreen extends StatelessWidget {
  final String execucaoId;

  const ChecklistExecucaoScreen({super.key, required this.execucaoId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChecklistProvider>(context);

    // Recupera a execução atual
    final exec = provider.todas.firstWhere(
      (e) => e.id == execucaoId,
      orElse: () => provider.todas.first,
    );

    // Resolve título e cor a partir do template (com fallback legado)
    ChecklistTemplate? template;
    try {
      template = provider.templates.firstWhere((t) => t.id == exec.tipo);
    } catch (_) {}
    final titulo = template?.titulo ??
        (exec.tipo == 'abertura'
            ? 'Abertura da Loja'
            : exec.tipo == 'fechamento'
                ? 'Fechamento da Loja'
                : 'Checklist');
    final cor = template?.cor ??
        (exec.tipo == 'abertura' ? AppColors.success : AppColors.danger);
    final progresso = exec.progresso;
    final concluido = exec.concluido;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(titulo, style: AppTextStyles.h3),
        actions: [
          if (!concluido)
            TextButton.icon(
              onPressed: () {
                provider.concluir(execucaoId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$titulo concluído!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              label: const Text('Concluir',
                  style: TextStyle(color: AppColors.success)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de progresso ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 8, Dimensions.paddingMD, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${exec.marcados} de ${exec.totalItens} itens',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: concluido ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${(progresso * 100).round()}%',
                      style: AppTextStyles.body.copyWith(
                        color: concluido ? AppColors.success : cor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progresso,
                  backgroundColor: AppColors.inactive.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    concluido ? AppColors.success : cor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
              ],
            ),
          ),

          if (concluido) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD),
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Checklist concluído!',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: Dimensions.spacingMD),

          // ── Lista de itens ───────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD),
              itemCount: exec.itens.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final marcado = exec.itensMarcados[i] == true;
                return CheckboxListTile(
                  value: marcado,
                  onChanged: (_) => provider.toggleItem(execucaoId, i),
                  title: Text(
                    exec.itens[i],
                    style: AppTextStyles.body.copyWith(
                      decoration:
                          marcado ? TextDecoration.lineThrough : null,
                      color: marcado
                          ? AppColors.inactive
                          : AppColors.textPrimary,
                    ),
                  ),
                  secondary: CircleAvatar(
                    radius: 14,
                    backgroundColor: marcado
                        ? AppColors.success.withValues(alpha: 0.15)
                        : cor.withValues(alpha: 0.1),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: marcado ? AppColors.success : cor,
                      ),
                    ),
                  ),
                  activeColor: AppColors.success,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingXS,
                    horizontal: 0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
