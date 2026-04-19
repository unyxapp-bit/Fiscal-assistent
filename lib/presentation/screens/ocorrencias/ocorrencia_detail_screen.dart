import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_notif.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/ocorrencia_provider.dart';
import 'ocorrencia_form_screen.dart';

class OcorrenciaDetailScreen extends StatelessWidget {
  final String ocorrenciaId;
  final Ocorrencia? ocorrenciaInicial;

  const OcorrenciaDetailScreen({
    super.key,
    required this.ocorrenciaId,
    this.ocorrenciaInicial,
  });

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} às $h:$min';
  }

  void _copiar(BuildContext context, String valor, String label) {
    Clipboard.setData(ClipboardData(text: valor));
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: '$label copiado para a área de transferência',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  void _marcarComoResolvida(BuildContext context, Ocorrencia ocorrencia) {
    final provider = context.read<OcorrenciaProvider>();
    final eventoProvider = context.read<EventoTurnoProvider>();
    provider.resolver(ocorrencia.id);

    if (eventoProvider.turnoAtivo) {
      final fiscalId = context.read<AuthProvider>().user?.id ?? '';
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.ocorrenciaResolvida,
        detalhe: '${ocorrencia.tipo} - ${ocorrencia.gravidade.nome}',
      );
    }

    AppNotif.show(
      context,
      titulo: 'Ocorrência resolvida',
      mensagem: 'A ocorrência foi marcada como resolvida.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OcorrenciaProvider>(context);
    final ocorrencia = provider.obterPorId(ocorrenciaId) ?? ocorrenciaInicial;

    if (ocorrencia == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da Ocorrência')),
        body: const Center(child: Text('Ocorrência não encontrada.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Detalhes da Ocorrência', style: AppTextStyles.h3),
        actions: [
          if (!ocorrencia.resolvida)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Marcar como resolvida',
              onPressed: () => _marcarComoResolvida(context, ocorrencia),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OcorrenciaFormScreen(ocorrencia: ocorrencia),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho em Card ───────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              ocorrencia.gravidade.cor.withValues(alpha: 0.15),
                          child: Icon(
                            iconForTipo(ocorrencia.tipo),
                            color: ocorrencia.gravidade.cor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(ocorrencia.tipo, style: AppTextStyles.h3),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ocorrencia.gravidade.cor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ocorrencia.gravidade.nome,
                            style: TextStyle(
                              color: ocorrencia.gravidade.cor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (ocorrencia.resolvida
                                ? AppColors.success
                                : AppColors.danger)
                            .withValues(alpha: 0.1),
                        border: Border.all(
                          color: ocorrencia.resolvida
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ocorrencia.resolvida
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 14,
                            color: ocorrencia.resolvida
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            ocorrencia.resolvida ? 'Resolvida' : 'Aberta',
                            style: AppTextStyles.caption.copyWith(
                              color: ocorrencia.resolvida
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Dimensions.spacingMD),

            // ── Informações (metadados) ──────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informações',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    _InfoLinha(
                      icon: Icons.access_time,
                      label: 'Registrada em',
                      value: _formatDateTime(ocorrencia.registradaEm),
                      color: AppColors.primary,
                    ),
                    if (ocorrencia.resolvidaEm != null) ...[
                      const SizedBox(height: 8),
                      _InfoLinha(
                        icon: Icons.check_circle,
                        label: 'Resolvida em',
                        value: _formatDateTime(ocorrencia.resolvidaEm!),
                        color: AppColors.success,
                      ),
                    ],
                    if (ocorrencia.caixaNome != null &&
                        ocorrencia.caixaNome!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoLinha(
                        icon: Icons.point_of_sale,
                        label: 'Caixa',
                        value: ocorrencia.caixaNome!,
                        color: AppColors.primary,
                      ),
                    ],
                    if (ocorrencia.colaboradorNome != null &&
                        ocorrencia.colaboradorNome!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoLinha(
                        icon: Icons.person,
                        label: 'Colaborador',
                        value: ocorrencia.colaboradorNome!,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: Dimensions.spacingMD),

            // ── Descrição ───────────────────────────────────────────────
            Text('Descrição', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSection,
                borderRadius:
                    BorderRadius.circular(Dimensions.borderRadius),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                ocorrencia.descricao.isEmpty
                    ? 'Sem descrição.'
                    : ocorrencia.descricao,
                style: AppTextStyles.body,
              ),
            ),

            // ── Anexos ──────────────────────────────────────────────────
            if ((ocorrencia.fotoUrl != null &&
                    ocorrencia.fotoUrl!.isNotEmpty) ||
                (ocorrencia.arquivoUrl != null &&
                    ocorrencia.arquivoUrl!.isNotEmpty)) ...[
              const SizedBox(height: Dimensions.spacingMD),
              Text('Anexos', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    if (ocorrencia.fotoUrl != null &&
                        ocorrencia.fotoUrl!.isNotEmpty)
                      ListTile(
                        leading:
                            const Icon(Icons.photo_outlined),
                        title: const Text('Foto'),
                        subtitle: Text(
                          ocorrencia.fotoNome ?? 'arquivo de imagem',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => _copiar(
                              context, ocorrencia.fotoUrl!, 'URL da foto'),
                        ),
                      ),
                    if (ocorrencia.fotoUrl != null &&
                        ocorrencia.fotoUrl!.isNotEmpty &&
                        ocorrencia.arquivoUrl != null &&
                        ocorrencia.arquivoUrl!.isNotEmpty)
                      const Divider(height: 1),
                    if (ocorrencia.arquivoUrl != null &&
                        ocorrencia.arquivoUrl!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: const Text('Arquivo'),
                        subtitle: Text(
                          ocorrencia.arquivoNome ?? 'arquivo anexado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => _copiar(
                            context,
                            ocorrencia.arquivoUrl!,
                            'URL do arquivo',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: Dimensions.spacingXL),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar ──────────────────────────────────────────────────────────

class _InfoLinha extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoLinha({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
