import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../../core/utils/app_notif.dart';

class ChecklistExecucaoScreen extends StatelessWidget {
  final String execucaoId;

  const ChecklistExecucaoScreen({super.key, required this.execucaoId});

  String _formatDateTime(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final minuto = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} \u00e0s $hora:$minuto';
  }

  String _textoExecucao(ChecklistExecucao exec, String titulo) {
    final buf = StringBuffer();
    buf.writeln('*$titulo*');
    buf.writeln();
    buf.writeln('Data: ${_formatDateTime(exec.data)}');
    buf.writeln(
      'Status: ${exec.concluido ? 'Conclu\u00eddo' : 'Em andamento'}',
    );
    buf.writeln('Progresso: ${exec.marcados}/${exec.totalItens} itens');
    if (exec.concluido && exec.concluidoEm != null) {
      buf.writeln('Conclus\u00e3o: ${_formatDateTime(exec.concluidoEm!)}');
    }
    buf.writeln();
    buf.writeln('Itens:');
    for (var i = 0; i < exec.itens.length; i++) {
      final marcado =
          i < exec.itensMarcados.length && exec.itensMarcados[i] == true;
      buf.writeln('${marcado ? '[x]' : '[ ]'} ${exec.itens[i]}');
    }
    return buf.toString().trim();
  }

  Future<void> _copiarExecucao(
    BuildContext context,
    ChecklistExecucao exec,
    String titulo,
  ) async {
    await Clipboard.setData(ClipboardData(text: _textoExecucao(exec, titulo)));
    if (!context.mounted) return;
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Checklist copiado para a \u00e1rea de transfer\u00eancia',
      tipo: 'intervalo',
    );
  }

  void _compartilharExecucao(ChecklistExecucao exec, String titulo) {
    Share.share(
      _textoExecucao(exec, titulo),
      subject: titulo,
    );
  }

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
              onPressed: () async {
                try {
                  await provider.concluir(execucaoId);
                  if (!context.mounted) return;
                  final eventoProvider =
                      Provider.of<EventoTurnoProvider>(context, listen: false);
                  if (eventoProvider.turnoAtivo) {
                    final fiscalId =
                        Provider.of<AuthProvider>(context, listen: false)
                                .user
                                ?.id ??
                            '';
                    eventoProvider.registrar(
                      fiscalId: fiscalId,
                      tipo: TipoEvento.checklistConcluido,
                      detalhe: titulo,
                    );
                  }
                  AppNotif.show(
                    context,
                    titulo: 'Checklist Concluído',
                    mensagem: '$titulo concluído!',
                    tipo: 'saida',
                    cor: AppColors.success,
                  );
                } catch (_) {
                  AppNotif.show(
                    context,
                    titulo: 'Erro ao concluir',
                    mensagem: 'Nao foi possivel salvar no Supabase.',
                    tipo: 'erro',
                    cor: AppColors.danger,
                  );
                }
              },
              icon: Icon(Icons.check_circle, color: AppColors.success),
              label:
                  Text('Concluir', style: TextStyle(color: AppColors.success)),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copiar') {
                _copiarExecucao(context, exec, titulo);
              }
              if (value == 'compartilhar') {
                _compartilharExecucao(exec, titulo);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'copiar',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Copiar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'compartilhar',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Compartilhar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // â”€â”€ Barra de progresso â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                        color: concluido
                            ? AppColors.success
                            : AppColors.textPrimary,
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
                SizedBox(height: 8),
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
            SizedBox(height: Dimensions.spacingSM),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Checklist concluído!',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: Dimensions.spacingMD),

          // â”€â”€ Lista de itens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
              itemCount: exec.itens.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final marcado = exec.itensMarcados[i] == true;
                return CheckboxListTile(
                  value: marcado,
                  onChanged: (_) async {
                    try {
                      await provider.toggleItem(execucaoId, i);
                      if (!context.mounted) return;
                    } catch (_) {
                      AppNotif.show(
                        context,
                        titulo: 'Erro ao atualizar item',
                        mensagem: 'Nao foi possivel salvar no Supabase.',
                        tipo: 'erro',
                        cor: AppColors.danger,
                      );
                    }
                  },
                  title: Text(
                    exec.itens[i],
                    style: AppTextStyles.body.copyWith(
                      decoration: marcado ? TextDecoration.lineThrough : null,
                      color:
                          marcado ? AppColors.inactive : AppColors.textPrimary,
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
