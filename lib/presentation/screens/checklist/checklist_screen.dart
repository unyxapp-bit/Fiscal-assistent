import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/checklist_provider.dart';
import 'checklist_execucao_screen.dart';
import 'checklist_template_form_screen.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às $h:$m';
  }

  // ── Card de cada template ─────────────────────────────────────────────────

  Widget _buildCard(
    BuildContext context,
    ChecklistProvider provider,
    ChecklistTemplate template,
  ) {
    final execucao = provider.execucaoHoje(template.id);
    final concluido = execucao?.concluido == true;
    final emAndamento = execucao != null && !concluido;
    final cor = template.cor;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        onTap: () {
          final exec = execucao ?? provider.iniciar(template.id);
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
                  // Ícone
                  CircleAvatar(
                    backgroundColor: cor.withValues(alpha: 0.15),
                    child: Icon(template.icone, color: cor),
                  ),
                  const SizedBox(width: Dimensions.spacingMD),

                  // Título e status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.titulo, style: AppTextStyles.h4),
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

                  // Status icon + menu
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
                    size: 26,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary, size: 20),
                    onSelected: (v) =>
                        _onMenu(context, v, template, provider),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ]),
                      ),
                      if (!template.isDefault)
                        const PopupMenuItem(
                          value: 'deletar',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Deletar',
                                style: TextStyle(color: AppColors.danger)),
                          ]),
                        ),
                    ],
                  ),
                ],
              ),

              // Barra de progresso
              if (execucao != null) ...[
                const SizedBox(height: Dimensions.spacingMD),
                LinearProgressIndicator(
                  value: execucao.progresso,
                  backgroundColor:
                      AppColors.inactive.withValues(alpha: 0.2),
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
                    final exec = execucao ?? provider.iniciar(template.id);
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

  void _onMenu(
    BuildContext context,
    String value,
    ChecklistTemplate template,
    ChecklistProvider provider,
  ) {
    switch (value) {
      case 'editar':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ChecklistTemplateFormScreen(template: template),
        ));
      case 'deletar':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Deletar checklist'),
            content: Text(
                'Deletar "${template.titulo}"? As execuções já registradas não serão afetadas.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  provider.deletarTemplate(template.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Deletar',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChecklistProvider>(context);
    final templates = provider.templates;
    final total = templates.length;
    final concluidos = provider.totalConcluidosHoje;

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
            // ── Resumo do dia ─────────────────────────────────────────────
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: concluidos == total && total > 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.inactive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$concluidos / $total concluídos',
                      style: AppTextStyles.caption.copyWith(
                        color: concluidos == total && total > 0
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spacingLG),
            const Text('Turno de Hoje', style: AppTextStyles.h3),
            const SizedBox(height: Dimensions.spacingMD),

            // ── Cards de templates ────────────────────────────────────────
            if (templates.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.checklist,
                          size: 56, color: AppColors.inactive),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum checklist criado',
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use o botão + para criar o primeiro',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...templates.map(
                  (t) => _buildCard(context, provider, t)),

            // ── Histórico recente ─────────────────────────────────────────
            if (provider.todas.length > templates.length) ...[
              const SizedBox(height: Dimensions.spacingMD),
              const Text('Histórico Recente', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingSM),
              ...provider.todas.skip(templates.length).take(8).map((exec) {
                // Tenta resolver template para nome/cor
                ChecklistTemplate? tmpl;
                try {
                  tmpl = provider.templates
                      .firstWhere((t) => t.id == exec.tipo);
                } catch (_) {}
                final nomeExec = tmpl?.titulo ??
                    (exec.tipo == 'abertura'
                        ? 'Abertura da Loja'
                        : exec.tipo == 'fechamento'
                            ? 'Fechamento da Loja'
                            : exec.tipo);
                final corExec = tmpl?.cor ??
                    (exec.tipo == 'abertura'
                        ? AppColors.success
                        : AppColors.danger);
                final iconeExec = tmpl?.icone ??
                    (exec.tipo == 'abertura'
                        ? Icons.lock_open
                        : Icons.lock);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    iconeExec,
                    color: exec.concluido ? corExec : AppColors.inactive,
                  ),
                  title: Text(nomeExec, style: AppTextStyles.body),
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
                    color: exec.concluido
                        ? AppColors.success
                        : AppColors.inactive,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ChecklistTemplateFormScreen(),
        )),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Novo Checklist'),
      ),
    );
  }
}
