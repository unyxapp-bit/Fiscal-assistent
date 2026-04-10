import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/notificacao_provider.dart';

class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificacaoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notificações'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (provider.totalNaoLidas > 0)
            TextButton(
              onPressed: () => provider.marcarTodasComoLidas(),
              child: Text('Marcar todas'),
            ),
        ],
      ),
      body: provider.notificacoes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppColors.inactive,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              itemCount: provider.notificacoes.length,
              itemBuilder: (context, index) {
                final notif = provider.notificacoes[index];
                final timeFormat = DateFormat('HH:mm');

                return Card(
                  color: notif.lida
                      ? null
                      : AppColors.primary.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTipoColor(notif.tipo),
                      child: Icon(
                        _getTipoIcon(notif.tipo),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notif.titulo,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight:
                            notif.lida ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(notif.mensagem),
                        SizedBox(height: 4),
                        Text(
                          timeFormat.format(notif.criadoEm),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => provider.marcarComoLida(notif.id),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      iconSize: 16,
                      onPressed: () => provider.removerNotificacao(notif.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

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
}
