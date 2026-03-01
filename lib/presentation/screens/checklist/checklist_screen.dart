import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/checklist_provider.dart';
import 'checklist_execucao_screen.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às $h:$m';
  }

  Widget _buildCard(
    BuildContext context,
    ChecklistProvider provider,
    String tipo,
    String titulo,
    IconData icone,
    Color cor,
  ) {
    final execucao = provider.execucaoHoje(tipo);
    final concluido = execucao?.concluido == true;
    final emAndamento = execucao != null && !concluido;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        onTap: () {
          final exec = execucao ?? provider.iniciar(tipo);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChecklistExecucaoScreen(execucaoId: exec.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cor.withValues(alpha: 0.15),
                    child: Icon(icone, color: cor),
                  ),
                  const SizedBox(width: Dimensions.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: AppTextStyles.h4),
                        Text(
                          execucao == null
                              ? 'Não iniciado hoje'
                              : concluido
                                  ? 'Concluído às ${_formatTime(execucao.concluidoEm!)}'
                                  : 'Em andamento — ${execucao.marcados}/${execucao.totalItens} itens',
                          style: AppTextStyles.caption.copyWith(
                            color: concluido
                                ? AppColors.success
                                : emAndamento
                                    ? AppColors.statusAtencao
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status icon
                  Icon(
                    concluido
                        ? Icons.check_circle
                        : emAndamento
                            ? Icons.pending
                            : Icons.play_circle_outline,
                    color: concluido
                        ? AppColors.success
                        : emAndamento
                            ? AppColors.statusAtencao
                            : AppColors.inactive,
                    size: 28,
                  ),
                ],
              ),

              // Barra de progresso (se iniciado)
              if (execucao != null) ...[
                const SizedBox(height: Dimensions.spacingMD),
                LinearProgressIndicator(
                  value: execucao.progresso,
                  backgroundColor: AppColors.inactive.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    concluido ? AppColors.success : cor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 6),
                Text(
                  '${execucao.marcados} de ${execucao.totalItens} itens marcados',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: Dimensions.spacingSM),

              // Botão de ação
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final exec = execucao ?? provider.iniciar(tipo);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChecklistExecucaoScreen(execucaoId: exec.id),
                      ),
                    );
                  },
                  icon: Icon(
                    concluido
                        ? Icons.visibility
                        : emAndamento
                            ? Icons.play_arrow
                            : Icons.start,
                    size: 18,
                    color: cor,
                  ),
                  label: Text(
                    concluido
                        ? 'Ver detalhes'
                        : emAndamento
                            ? 'Continuar'
                            : 'Iniciar checklist',
                    style: TextStyle(color: cor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cor.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChecklistProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checklist de Turno'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo do dia
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Checklists de hoje',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${provider.foiConcluidoHoje('abertura') ? '✓' : '○'} Abertura  '
                    '${provider.foiConcluidoHoje('fechamento') ? '✓' : '○'} Fechamento',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spacingLG),
            const Text('Turno de Hoje', style: AppTextStyles.h3),
            const SizedBox(height: Dimensions.spacingMD),

            // Card Abertura
            _buildCard(
              context,
              provider,
              'abertura',
              'Abertura da Loja',
              Icons.lock_open,
              AppColors.success,
            ),

            // Card Fechamento
            _buildCard(
              context,
              provider,
              'fechamento',
              'Fechamento da Loja',
              Icons.lock,
              AppColors.danger,
            ),

            // Histórico recente
            if (provider.todas.length > 2) ...[
              const SizedBox(height: Dimensions.spacingMD),
              const Text('Histórico Recente', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingSM),
              ...provider.todas.skip(2).take(5).map((exec) {
                final cor =
                    exec.tipo == 'abertura' ? AppColors.success : AppColors.danger;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    exec.tipo == 'abertura' ? Icons.lock_open : Icons.lock,
                    color: exec.concluido ? cor : AppColors.inactive,
                  ),
                  title: Text(
                    exec.tipo == 'abertura' ? 'Abertura' : 'Fechamento',
                    style: AppTextStyles.body,
                  ),
                  subtitle: Text(
                    '${exec.data.day.toString().padLeft(2, '0')}/${exec.data.month.toString().padLeft(2, '0')} · '
                    '${exec.marcados}/${exec.totalItens} itens',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(
                    exec.concluido
                        ? Icons.check_circle
                        : Icons.cancel_outlined,
                    color:
                        exec.concluido ? AppColors.success : AppColors.inactive,
                    size: 20,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChecklistExecucaoScreen(execucaoId: exec.id),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
