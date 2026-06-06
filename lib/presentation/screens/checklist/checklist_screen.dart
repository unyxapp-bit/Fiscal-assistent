import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_notif.dart';
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

  String _periodizacaoTexto(ChecklistTemplate template) {
    if (template.periodizacao == PeriodizacaoChecklist.qualquerHorario) {
      return 'Qualquer horário';
    }
    if (template.periodizacao == PeriodizacaoChecklist.horarioEspecifico) {
      return 'Horário: ${template.horarioNotificacao ?? '--:--'} (+/-30 min)';
    }
    return template.periodizacao.label;
  }

  String _statusTexto({
    required ChecklistTemplate template,
    required ChecklistProvider provider,
    required ChecklistExecucao? execucaoAberta,
    required ChecklistExecucao? ultimaExecucao,
  }) {
    if (execucaoAberta != null) {
      return 'Em andamento — ${execucaoAberta.marcados}/${execucaoAberta.totalItens} itens';
    }

    if (ultimaExecucao == null) {
      return template.modoExecucao == ModoExecucaoChecklist.continuo
          ? 'Pronto para responder'
          : 'Disponível para a primeira resposta';
    }

    if (template.modoExecucao == ModoExecucaoChecklist.usoUnico &&
        provider.jaFoiConcluidoAlgumaVez(template.id) &&
        ultimaExecucao.concluido &&
        ultimaExecucao.concluidoEm != null) {
      return 'Uso único concluído em ${_formatTime(ultimaExecucao.concluidoEm!)}';
    }

    if (ultimaExecucao.concluido && ultimaExecucao.concluidoEm != null) {
      return 'Última execução concluída em ${_formatTime(ultimaExecucao.concluidoEm!)}';
    }

    return 'Execução pendente para revisar';
  }

  String _textoChecklist(
    ChecklistTemplate template,
    ChecklistExecucao? execucao,
  ) {
    final buf = StringBuffer();
    buf.writeln('*${template.titulo}*');
    if (template.descricao.isNotEmpty) {
      buf.writeln();
      buf.writeln(template.descricao);
    }
    buf.writeln();
    buf.writeln('Modo: ${template.modoExecucao.label}');
    buf.writeln('Agendamento: ${_periodizacaoTexto(template)}');
    final status = execucao == null
        ? 'Sem execução iniciada'
        : execucao.concluido
            ? 'Concluído'
            : 'Em andamento';
    buf.writeln('Status: $status');
    buf.writeln();
    buf.writeln('Itens:');

    for (var i = 0; i < template.itens.length; i++) {
      final marcado = execucao != null &&
          i < execucao.itensMarcados.length &&
          execucao.itensMarcados[i] == true;
      buf.writeln('${marcado ? '[x]' : '[ ]'} ${template.itens[i]}');
    }

    return buf.toString().trim();
  }

  Future<void> _copiarChecklist(
    BuildContext context,
    ChecklistTemplate template,
    ChecklistExecucao? execucao,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: _textoChecklist(template, execucao)),
    );
    if (!context.mounted) return;
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Checklist copiado para a área de transferência',
      tipo: 'intervalo',
    );
  }

  void _compartilharChecklist(
    ChecklistTemplate template,
    ChecklistExecucao? execucao,
  ) {
    Share.share(
      _textoChecklist(template, execucao),
      subject: template.titulo,
    );
  }

  void _abrirFormularioNovo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChecklistTemplateFormScreen(),
      ),
    );
  }

  Future<void> _restaurarPadroes(
    BuildContext context,
    ChecklistProvider provider,
  ) async {
    try {
      await provider.restaurarTemplatesPadrao();
      if (!context.mounted) return;
      AppNotif.show(
        context,
        titulo: 'Padrões restaurados',
        mensagem: 'Abertura e Fechamento voltaram para a lista.',
        tipo: 'sucesso',
        cor: AppColors.success,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppNotif.show(
        context,
        titulo: 'Erro ao restaurar',
        mensagem: 'Não foi possível restaurar os checklists padrão.',
        tipo: 'erro',
        cor: AppColors.danger,
      );
    }
  }

  Future<void> _abrirChecklist(
    BuildContext context,
    ChecklistProvider provider,
    ChecklistTemplate template,
    ChecklistExecucao? execucaoAberta,
    ChecklistExecucao? ultimaExecucao,
  ) async {
    try {
      ChecklistExecucao? execucao = execucaoAberta;

      if (execucao == null &&
          template.modoExecucao == ModoExecucaoChecklist.usoUnico &&
          provider.jaFoiConcluidoAlgumaVez(template.id)) {
        execucao = ultimaExecucao;
      }

      execucao ??= await provider.iniciar(template.id);

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChecklistExecucaoScreen(execucaoId: execucao!.id),
        ),
      );
    } on StateError {
      if (!context.mounted) return;
      AppNotif.show(
        context,
        titulo: 'Checklist bloqueado',
        mensagem:
            'Esse checklist é de uso único e já foi concluído anteriormente.',
        tipo: 'alerta',
        cor: AppColors.warning,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppNotif.show(
        context,
        titulo: 'Erro ao iniciar checklist',
        mensagem: 'Não foi possível salvar no servidor.',
        tipo: 'erro',
        cor: AppColors.danger,
      );
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ChecklistProvider provider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        tint: AppColors.primary,
        radius: Dimensions.radiusMD,
        elevated: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.checklist_rtl,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nenhum checklist ativo', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      provider.temTemplatesExcluidos
                          ? 'Os checklists excluídos não serão recriados automaticamente.'
                          : 'Crie um fluxo do zero ou use os modelos padrão.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spacingMD),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _abrirFormularioNovo(context),
                icon: const Icon(Icons.add),
                label: const Text('Novo checklist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _restaurarPadroes(context, provider),
                icon: const Icon(Icons.restore),
                label: const Text('Restaurar padrões'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ChecklistProvider provider,
    ChecklistTemplate template,
  ) {
    final execucaoAberta = provider.execucaoAberta(template.id);
    final ultimaExecucao = provider.ultimaExecucao(template.id);
    final execucaoVisual = execucaoAberta ?? ultimaExecucao;
    final cor = template.cor;
    final emAndamento = execucaoAberta != null;
    final bloqueadoUsoUnico =
        template.modoExecucao == ModoExecucaoChecklist.usoUnico &&
            provider.jaFoiConcluidoAlgumaVez(template.id) &&
            execucaoAberta == null;
    final concluido = execucaoVisual?.concluido == true;
    final corStatus = bloqueadoUsoUnico
        ? AppColors.textSecondary
        : emAndamento
            ? AppColors.statusAtencao
            : concluido
                ? AppColors.success
                : cor;
    final iconeStatus = bloqueadoUsoUnico
        ? Icons.lock_outline
        : emAndamento
            ? Icons.pending
            : concluido
                ? (template.modoExecucao == ModoExecucaoChecklist.continuo
                    ? Icons.refresh
                    : Icons.check_circle)
                : Icons.play_circle_outline;
    final labelAcao = bloqueadoUsoUnico
        ? 'Ver última execução'
        : emAndamento
            ? 'Continuar'
            : concluido &&
                    template.modoExecucao == ModoExecucaoChecklist.continuo
                ? 'Responder novamente'
                : 'Iniciar checklist';

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        onTap: () => _abrirChecklist(
          context,
          provider,
          template,
          execucaoAberta,
          ultimaExecucao,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cor.withValues(alpha: 0.15),
                    child: Icon(template.icone, color: cor, size: 19),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.titulo, style: AppTextStyles.h4),
                        const SizedBox(height: 2),
                        Text(
                          _statusTexto(
                            template: template,
                            provider: provider,
                            execucaoAberta: execucaoAberta,
                            ultimaExecucao: ultimaExecucao,
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: corStatus,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(iconeStatus, color: corStatus, size: 24),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (v) => _onMenu(
                      context,
                      v,
                      template,
                      provider,
                      execucaoVisual,
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'copiar',
                        child: Row(
                          children: [
                            Icon(Icons.copy_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Copiar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'compartilhar',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Compartilhar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deletar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spacingXS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon:
                        template.modoExecucao == ModoExecucaoChecklist.continuo
                            ? Icons.autorenew_rounded
                            : Icons.lock_outline,
                    color:
                        template.modoExecucao == ModoExecucaoChecklist.continuo
                            ? AppColors.primary
                            : AppColors.statusAtencao,
                    label: template.modoExecucao.label,
                  ),
                  _buildInfoChip(
                    icon: Icons.schedule,
                    color: AppColors.textSecondary,
                    label: _periodizacaoTexto(template),
                  ),
                ],
              ),
              if (template.descricao.isNotEmpty) ...[
                const SizedBox(height: Dimensions.spacingXS),
                Text(
                  template.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (execucaoVisual != null) ...[
                const SizedBox(height: Dimensions.spacingSM),
                LinearProgressIndicator(
                  value: execucaoVisual.progresso,
                  backgroundColor: AppColors.inactive.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    concluido ? AppColors.success : cor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 6),
                Text(
                  '${execucaoVisual.marcados} de ${execucaoVisual.totalItens} itens marcados',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: Dimensions.spacingXS),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _abrirChecklist(
                    context,
                    provider,
                    template,
                    execucaoAberta,
                    ultimaExecucao,
                  ),
                  icon: Icon(
                    bloqueadoUsoUnico
                        ? Icons.visibility_outlined
                        : emAndamento
                            ? Icons.play_arrow
                            : concluido &&
                                    template.modoExecucao ==
                                        ModoExecucaoChecklist.continuo
                                ? Icons.refresh
                                : Icons.start,
                    size: 18,
                    color: corStatus,
                  ),
                  label: Text(
                    labelAcao,
                    style: TextStyle(color: corStatus),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: corStatus.withValues(alpha: 0.45)),
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
    ChecklistExecucao? execucao,
  ) {
    switch (value) {
      case 'copiar':
        _copiarChecklist(context, template, execucao);
        break;
      case 'compartilhar':
        _compartilharChecklist(template, execucao);
        break;
      case 'editar':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChecklistTemplateFormScreen(template: template),
          ),
        );
        break;
      case 'deletar':
        var excluirHistorico = true;
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              title: const Text('Excluir checklist'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excluir "${template.titulo}"? Ele sairá do turno, das pendências e não será recriado automaticamente.',
                  ),
                  const SizedBox(height: Dimensions.spacingSM),
                  CheckboxListTile(
                    value: excluirHistorico,
                    onChanged: (value) {
                      setDialogState(() {
                        excluirHistorico = value ?? true;
                      });
                    },
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remover histórico desse checklist'),
                    subtitle: const Text(
                      'As execuções antigas também deixam de aparecer aqui.',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await provider.deletarTemplate(
                        template.id,
                        excluirHistorico: excluirHistorico,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!context.mounted) return;
                      AppNotif.show(
                        context,
                        titulo: 'Checklist excluído',
                        mensagem: excluirHistorico
                            ? 'Modelo e histórico removidos.'
                            : 'Modelo removido. Histórico preservado.',
                        tipo: 'sucesso',
                        cor: AppColors.success,
                      );
                    } catch (_) {
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!context.mounted) return;
                      // Deletado localmente; avisa que sync falhou
                      AppNotif.show(
                        context,
                        titulo: 'Excluído localmente',
                        mensagem:
                            'Removido do dispositivo. Falha ao sincronizar com o servidor.',
                        tipo: 'alerta',
                        cor: AppColors.warning,
                      );
                    }
                  },
                  child: Text(
                    'Excluir',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }
  }

  int _prioridadeTemplate(
      ChecklistProvider provider, ChecklistTemplate template) {
    if (provider.execucaoAberta(template.id) != null) return 0;
    if (!provider.foiConcluidoHoje(template.id)) return 1;
    return 2;
  }

  Widget _buildHistoricoItem(
    BuildContext context,
    ChecklistProvider provider,
    ChecklistExecucao exec,
  ) {
    final nomeExec = provider.tituloParaTemplate(exec.tipo);
    final template = provider.templateById(exec.tipo);
    final corExec = template?.cor ??
        (exec.tipo == 'abertura' ? AppColors.success : AppColors.danger);
    final iconeExec = template?.icone ??
        (exec.tipo == 'abertura' ? Icons.lock_open : Icons.lock);

    final dataStr =
        '${exec.data.day.toString().padLeft(2, '0')}/${exec.data.month.toString().padLeft(2, '0')} · ${exec.marcados}/${exec.totalItens} itens';

    return Dismissible(
      key: Key(exec.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Dimensions.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        try {
          await provider.deletarExecucao(exec.id);
          return true;
        } catch (_) {
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusMD),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChecklistExecucaoScreen(execucaoId: exec.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingMD,
              vertical: Dimensions.paddingSM,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: corExec.withValues(alpha: 0.12),
                  child: Icon(
                    iconeExec,
                    size: 18,
                    color: exec.concluido ? corExec : AppColors.inactive,
                  ),
                ),
                const SizedBox(width: Dimensions.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomeExec, style: AppTextStyles.body),
                      const SizedBox(height: 2),
                      Text(
                        dataStr,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      exec.concluido
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      color: exec.concluido
                          ? AppColors.success
                          : AppColors.inactive,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    if (exec.totalItens > 0)
                      Text(
                        '${(exec.progresso * 100).round()}%',
                        style: AppTextStyles.caption.copyWith(
                          color: exec.concluido
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChecklistProvider>(context);
    final templates = provider.templates.toList();
    final total = templates.length;
    final concluidosHoje = provider.totalConcluidosHoje;

    final ativos =
        templates.where((t) => provider.estaDisponivelNoTurno(t.id)).toList()
          ..sort((a, b) {
            final prioridade = _prioridadeTemplate(provider, a)
                .compareTo(_prioridadeTemplate(provider, b));
            if (prioridade != 0) return prioridade;
            return a.titulo.compareTo(b.titulo);
          });

    final arquivadosUsoUnico = templates
        .where(
          (t) =>
              t.modoExecucao == ModoExecucaoChecklist.usoUnico &&
              provider.jaFoiConcluidoAlgumaVez(t.id),
        )
        .toList()
      ..sort((a, b) => a.titulo.compareTo(b.titulo));

    final execucoesAbertasIds = {
      for (final t in templates)
        if (provider.execucaoAberta(t.id) != null)
          provider.execucaoAberta(t.id)!.id,
    };

    final historicoRecente = provider.todas
        .where((exec) => !execucoesAbertasIds.contains(exec.id))
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Checklist de Turno', style: AppTextStyles.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (provider.temPadroesExcluidos)
            IconButton(
              tooltip: 'Restaurar padrões',
              onPressed: () => _restaurarPadroes(context, provider),
              icon: const Icon(Icons.restore),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.operationalHPad(constraints.maxWidth),
            vertical: Dimensions.paddingSM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Resumo do dia ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today, color: AppColors.primary, size: 18),
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: concluidosHoje == total && total > 0
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.inactive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$concluidosHoje / $total concluídos',
                        style: AppTextStyles.caption.copyWith(
                          color: concluidosHoje == total && total > 0
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spacingSM),

              // ── Dica de uso ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: AppStyles.softCard(
                  tint: AppColors.statusAtencao,
                  radius: Dimensions.radiusMD,
                  elevated: false,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              AppColors.statusAtencao.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppColors.statusAtencao,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Uso contínuo fica sempre liberado para novas respostas. Uso único sai da lista após a primeira conclusão.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spacingSM),

              // ── Turno de hoje ────────────────────────────────────────────
              Text('Turno de Hoje', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingSM),
              if (templates.isEmpty)
                _buildEmptyState(context, provider)
              else if (ativos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSM),
                  decoration: AppStyles.softCard(
                    tint: AppColors.success,
                    radius: Dimensions.radiusMD,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nenhum checklist ativo para responder agora.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...ativos.map((t) => _buildCard(context, provider, t)),

              // ── Uso único concluído ──────────────────────────────────────
              if (arquivadosUsoUnico.isNotEmpty) ...[
                const SizedBox(height: Dimensions.spacingSM),
                ExpansionTile(
                  leading: Icon(
                    Icons.lock_outline,
                    color: AppColors.statusAtencao,
                    size: 20,
                  ),
                  title: Text(
                    'Uso único concluído (${arquivadosUsoUnico.length})',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.statusAtencao,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  children: arquivadosUsoUnico
                      .map((t) => _buildCard(context, provider, t))
                      .toList(),
                ),
              ],

              // ── Histórico Recente ────────────────────────────────────────
              if (historicoRecente.isNotEmpty) ...[
                const SizedBox(height: Dimensions.spacingSM),
                Row(
                  children: [
                    Expanded(
                        child:
                            Text('Histórico Recente', style: AppTextStyles.h3)),
                    Text(
                      'Deslize para excluir',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spacingSM),
                ...historicoRecente.map(
                  (exec) => _buildHistoricoItem(context, provider, exec),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioNovo(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Checklist'),
      ),
    );
  }
}
