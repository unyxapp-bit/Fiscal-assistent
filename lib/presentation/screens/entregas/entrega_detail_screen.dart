import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/evento_turno_provider.dart';
import 'entrega_form_screen.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de Detalhes da Entrega
/// Mostra informações completas, timeline e permite mudança de status
class EntregaDetailScreen extends StatelessWidget {
  final Entrega entrega;

  const EntregaDetailScreen({
    super.key,
    required this.entrega,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'separada':
        return AppColors.statusAtencao;
      case 'em_rota':
        return AppColors.primary;
      case 'entregue':
        return AppColors.success;
      case 'cancelada':
        return AppColors.danger;
      default:
        return AppColors.inactive;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'separada':
        return Icons.assignment;
      case 'em_rota':
        return Icons.directions_car;
      case 'entregue':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'separada':
        return 'Separada';
      case 'em_rota':
        return 'Em Rota';
      case 'entregue':
        return 'Entregue';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  void _marcarEmRota(BuildContext context) {
    final provider = Provider.of<EntregaProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('Marcar esta entrega como "Em Rota"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.atualizarStatus(entrega.id, 'em_rota');
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
                  tipo: TipoEvento.entregaStatusAlterado,
                  detalhe: 'NF ${entrega.numeroNota} → Em Rota',
                );
              }
              Navigator.pop(context);
              AppNotif.show(
                context,
                titulo: 'Em Rota',
                mensagem: 'Entrega marcada como "Em Rota"',
                tipo: 'saida',
                cor: AppColors.primary,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _marcarEntregue(BuildContext context) {
    final provider = Provider.of<EntregaProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('Marcar esta entrega como "Entregue"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.atualizarStatus(entrega.id, 'entregue');
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
                  tipo: TipoEvento.entregaStatusAlterado,
                  detalhe: 'NF ${entrega.numeroNota} → Entregue',
                );
              }
              Navigator.pop(context);
              AppNotif.show(
                context,
                titulo: 'Entregue',
                mensagem: 'Entrega marcada como "Entregue"',
                tipo: 'saida',
                cor: AppColors.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _cancelarEntrega(BuildContext context) {
    final provider = Provider.of<EntregaProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar Entrega'),
        content: Text(
          'Tem certeza que deseja cancelar esta entrega? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.atualizarStatus(entrega.id, 'cancelada');
              Navigator.pop(context);
              AppNotif.show(
                context,
                titulo: 'Cancelada',
                mensagem: 'Entrega cancelada',
                tipo: 'alerta',
                cor: AppColors.danger,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _excluirEntrega(BuildContext context) {
    final provider = Provider.of<EntregaProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir Entrega'),
        content: Text(
          'Tem certeza que deseja excluir esta entrega? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removerEntrega(entrega.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _editarEntrega(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntregaFormScreen(entrega: entrega),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Detalhes da Entrega', style: AppTextStyles.h3),
        actions: [
          if (entrega.status != 'entregue' && entrega.status != 'cancelada')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editarEntrega(context),
              tooltip: 'Editar',
            ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () => _excluirEntrega(context),
            tooltip: 'Excluir',
            color: AppColors.danger,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Status Principal
            Card(
              color: _getStatusColor(entrega.status).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingLG),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      decoration: BoxDecoration(
                        color: _getStatusColor(entrega.status),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMD),
                      ),
                      child: Icon(
                        _getStatusIcon(entrega.status),
                        color: Colors.white,
                        size: Dimensions.iconXL,
                      ),
                    ),
                    SizedBox(width: Dimensions.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusLabel(entrega.status),
                            style: AppTextStyles.h3.copyWith(
                              color: _getStatusColor(entrega.status),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'NF: ${entrega.numeroNota}',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: Dimensions.spacingLG),

            // Informações do Cliente
            Text('Informações do Cliente', style: AppTextStyles.h3),
            SizedBox(height: Dimensions.spacingSM),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.person,
                      'Nome',
                      entrega.clienteNome,
                    ),
                    if (entrega.telefone != null &&
                        entrega.telefone!.isNotEmpty) ...[
                      Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.phone,
                              color: AppColors.primary,
                              size: Dimensions.iconMD),
                          SizedBox(width: Dimensions.spacingSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Telefone',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                                SizedBox(height: 4),
                                Text(entrega.telefone!,
                                    style: AppTextStyles.body),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_outlined, size: 18),
                            tooltip: 'Copiar número',
                            color: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: entrega.telefone!));
                              AppNotif.show(
                                context,
                                titulo: 'Copiado',
                                mensagem: 'Número copiado',
                                tipo: 'intervalo',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                    Divider(height: 24),
                    _buildInfoRow(
                      Icons.home,
                      'Endereço',
                      entrega.endereco,
                    ),
                    Divider(height: 24),
                    _buildInfoRow(
                      Icons.location_city,
                      'Bairro',
                      entrega.bairro,
                    ),
                    Divider(height: 24),
                    _buildInfoRow(
                      Icons.location_on,
                      'Cidade',
                      entrega.cidade,
                    ),
                    if (entrega.horarioMarcado != null) ...[
                      Divider(height: 24),
                      _buildInfoRow(
                        Icons.access_time,
                        'Horário Marcado',
                        _formatTime(entrega.horarioMarcado!),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: Dimensions.spacingLG),

            // Timeline da Entrega
            Text('Timeline', style: AppTextStyles.h3),
            SizedBox(height: Dimensions.spacingSM),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  children: [
                    _buildTimelineItem(
                      Icons.assignment,
                      'Separada',
                      _formatDateTime(entrega.separadoEm),
                      true,
                      AppColors.statusAtencao,
                    ),
                    if (entrega.saiuParaEntregaEm != null) ...[
                      _buildTimelineConnector(true),
                      _buildTimelineItem(
                        Icons.directions_car,
                        'Saiu para Entrega',
                        _formatDateTime(entrega.saiuParaEntregaEm!),
                        true,
                        AppColors.primary,
                      ),
                    ] else if (entrega.status != 'cancelada') ...[
                      _buildTimelineConnector(false),
                      _buildTimelineItem(
                        Icons.directions_car,
                        'Saiu para Entrega',
                        'Aguardando',
                        false,
                        AppColors.inactive,
                      ),
                    ],
                    if (entrega.entregueEm != null) ...[
                      _buildTimelineConnector(true),
                      _buildTimelineItem(
                        Icons.check_circle,
                        'Entregue',
                        _formatDateTime(entrega.entregueEm!),
                        true,
                        AppColors.success,
                      ),
                    ] else if (entrega.status != 'cancelada') ...[
                      _buildTimelineConnector(false),
                      _buildTimelineItem(
                        Icons.check_circle,
                        'Entregue',
                        'Aguardando',
                        false,
                        AppColors.inactive,
                      ),
                    ],
                    if (entrega.status == 'cancelada') ...[
                      _buildTimelineConnector(true),
                      _buildTimelineItem(
                        Icons.cancel,
                        'Cancelada',
                        'Entrega cancelada',
                        true,
                        AppColors.danger,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Observações
            if (entrega.observacoes != null &&
                entrega.observacoes!.isNotEmpty) ...[
              SizedBox(height: Dimensions.spacingLG),
              Text('Observações', style: AppTextStyles.h3),
              SizedBox(height: Dimensions.spacingSM),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, color: AppColors.textSecondary),
                      SizedBox(width: Dimensions.spacingSM),
                      Expanded(
                        child: Text(
                          entrega.observacoes!,
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: Dimensions.spacingXL),

            // Botões de Ação
            if (entrega.status == 'separada') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _marcarEmRota(context),
                  icon: Icon(Icons.directions_car),
                  label: Text('Marcar em Rota'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: Dimensions.spacingSM),
            ],

            if (entrega.status == 'em_rota') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _marcarEntregue(context),
                  icon: Icon(Icons.check_circle),
                  label: Text('Marcar Entregue'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: Dimensions.spacingSM),
            ],

            if (entrega.status != 'entregue' && entrega.status != 'cancelada')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelarEntrega(context),
                  icon: Icon(Icons.cancel),
                  label: Text('Cancelar Entrega'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: Dimensions.iconMD),
        SizedBox(width: Dimensions.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    IconData icon,
    String title,
    String subtitle,
    bool completed,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: completed ? color : Colors.transparent,
            border: Border.all(
              color: color,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: completed ? Colors.white : color,
            size: 20,
          ),
        ),
        SizedBox(width: Dimensions.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: completed ? color : AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: completed
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool completed) {
    return Padding(
      padding: const EdgeInsets.only(left: 19),
      child: Container(
        width: 2,
        height: 24,
        color: completed ? AppColors.primary : AppColors.inactive,
      ),
    );
  }
}
