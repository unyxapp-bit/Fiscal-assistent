import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/entrega_provider.dart';
import 'entrega_form_screen.dart';

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
        title: const Text('Confirmar'),
        content: const Text('Marcar esta entrega como "Em Rota"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.atualizarStatus(entrega.id, 'em_rota');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entrega marcada como "Em Rota"'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
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
        title: const Text('Confirmar'),
        content: const Text('Marcar esta entrega como "Entregue"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.atualizarStatus(entrega.id, 'entregue');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entrega marcada como "Entregue"'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
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
        title: const Text('Cancelar Entrega'),
        content: const Text(
          'Tem certeza que deseja cancelar esta entrega? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.atualizarStatus(entrega.id, 'cancelada');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entrega cancelada'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
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
        title: const Text('Detalhes da Entrega', style: AppTextStyles.h3),
        actions: [
          if (entrega.status != 'entregue' && entrega.status != 'cancelada')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editarEntrega(context),
              tooltip: 'Editar',
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
                        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                      ),
                      child: Icon(
                        _getStatusIcon(entrega.status),
                        color: Colors.white,
                        size: Dimensions.iconXL,
                      ),
                    ),
                    const SizedBox(width: Dimensions.spacingMD),
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
                          const SizedBox(height: 4),
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

            const SizedBox(height: Dimensions.spacingLG),

            // Informações do Cliente
            const Text('Informações do Cliente', style: AppTextStyles.h3),
            const SizedBox(height: Dimensions.spacingSM),

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
                    if (entrega.telefone != null && entrega.telefone!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.phone,
                        'Telefone',
                        entrega.telefone!,
                      ),
                    ],
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.home,
                      'Endereço',
                      entrega.endereco,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.location_city,
                      'Bairro',
                      entrega.bairro,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.location_on,
                      'Cidade',
                      entrega.cidade,
                    ),
                    if (entrega.horarioMarcado != null) ...[
                      const Divider(height: 24),
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

            const SizedBox(height: Dimensions.spacingLG),

            // Timeline da Entrega
            const Text('Timeline', style: AppTextStyles.h3),
            const SizedBox(height: Dimensions.spacingSM),

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
            if (entrega.observacoes != null && entrega.observacoes!.isNotEmpty) ...[
              const SizedBox(height: Dimensions.spacingLG),
              const Text('Observações', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingSM),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, color: AppColors.textSecondary),
                      const SizedBox(width: Dimensions.spacingSM),
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

            const SizedBox(height: Dimensions.spacingXL),

            // Botões de Ação
            if (entrega.status == 'separada') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _marcarEmRota(context),
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Marcar em Rota'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spacingSM),
            ],

            if (entrega.status == 'em_rota') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _marcarEntregue(context),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Marcar Entregue'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spacingSM),
            ],

            if (entrega.status != 'entregue' && entrega.status != 'cancelada')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelarEntrega(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar Entrega'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
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
        const SizedBox(width: Dimensions.spacingSM),
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
              const SizedBox(height: 4),
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
        const SizedBox(width: Dimensions.spacingMD),
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
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: completed ? AppColors.textPrimary : AppColors.textSecondary,
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
