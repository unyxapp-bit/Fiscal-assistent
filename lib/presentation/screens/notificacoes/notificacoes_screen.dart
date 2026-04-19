import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/notificacao_provider.dart';

class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  // ── Timestamp relativo ────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final dia = DateTime(dt.year, dt.month, dt.day);

    final hora = DateFormat('HH:mm').format(dt);
    if (dia == hoje) return hora;
    if (dia == ontem) return 'Ontem $hora';
    return '${DateFormat('dd/MM').format(dt)} $hora';
  }

  // ── Cor e ícone por tipo ──────────────────────────────────────────────────

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'intervalo':
        return AppColors.statusIntervalo;
      case 'cafe':
        return AppColors.statusCafe;
      case 'saida':
        return AppColors.statusSaida;
      case 'alerta':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'intervalo':
        return Icons.pause_circle;
      case 'cafe':
        return Icons.coffee;
      case 'saida':
        return Icons.exit_to_app;
      case 'alerta':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificacaoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (provider.notificacoes.isNotEmpty)
            PopupMenuButton<_NotifAction>(
              onSelected: (action) {
                if (action == _NotifAction.marcarTodas) {
                  provider.marcarTodasComoLidas();
                } else {
                  provider.limparNotificacoes();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _NotifAction.marcarTodas,
                  enabled: provider.totalNaoLidas > 0,
                  child: Row(
                    children: [
                      Icon(Icons.done_all,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Text('Marcar todas como lidas'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _NotifAction.limparTodas,
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined,
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Text('Limpar tudo',
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: provider.notificacoes.isEmpty
          ? _buildVazio()
          : ListView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              itemCount: provider.notificacoes.length,
              itemBuilder: (context, index) {
                final notif = provider.notificacoes[index];
                final cor = _getTipoColor(notif.tipo);

                return Dismissible(
                  key: ValueKey(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: Dimensions.paddingMD),
                    margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius:
                          BorderRadius.circular(Dimensions.borderRadius),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 22),
                  ),
                  onDismissed: (_) =>
                      provider.removerNotificacao(notif.id),
                  child: Card(
                    margin:
                        const EdgeInsets.only(bottom: Dimensions.spacingSM),
                    clipBehavior: Clip.hardEdge,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Borda esquerda colorida para não lida
                          if (!notif.lida)
                            Container(width: 3, color: AppColors.primary),
                          Expanded(
                            child: ListTile(
                              onTap: () =>
                                  provider.marcarComoLida(notif.id),
                              leading: CircleAvatar(
                                backgroundColor: cor,
                                child: Icon(
                                  _getTipoIcon(notif.tipo),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                notif.titulo,
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: notif.lida
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(notif.mensagem,
                                      style: AppTextStyles.body),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(notif.criadoEm),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Ponto indicador quando não lida
                                  if (!notif.lida)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    iconSize: 18,
                                    constraints: const BoxConstraints(
                                        minWidth: 40, minHeight: 40),
                                    onPressed: () =>
                                        provider.removerNotificacao(notif.id),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 52,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tudo em dia',
              style: AppTextStyles.h3
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhuma notificação no momento',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.inactive),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotifAction { marcarTodas, limparTodas }
