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
    return '$d/$m/${dt.year} as $h:$min';
  }

  void _copiar(BuildContext context, String valor, String label) {
    Clipboard.setData(ClipboardData(text: valor));
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: '$label copiado para area de transferencia',
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
      titulo: 'Ocorrencia resolvida',
      mensagem: 'A ocorrencia foi marcada como resolvida.',
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
        appBar: AppBar(title: const Text('Detalhes da Ocorrencia')),
        body: const Center(child: Text('Ocorrencia nao encontrada.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Detalhes da Ocorrencia', style: AppTextStyles.h3),
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      ocorrencia.gravidade.cor.withValues(alpha: 0.15),
                  child: Icon(
                    iconForTipo(ocorrencia.tipo),
                    color: ocorrencia.gravidade.cor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(ocorrencia.tipo, style: AppTextStyles.h3),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ocorrencia.gravidade.cor.withValues(alpha: 0.12),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    ocorrencia.resolvida
                        ? Icons.check_circle
                        : Icons.error_outline,
                    size: 16,
                    color: ocorrencia.resolvida
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  label: Text(ocorrencia.resolvida ? 'Resolvida' : 'Aberta'),
                  backgroundColor: ocorrencia.resolvida
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.danger.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Registrada em ${_formatDateTime(ocorrencia.registradaEm)}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (ocorrencia.resolvidaEm != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Resolvida em ${_formatDateTime(ocorrencia.resolvidaEm!)}',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.success),
                ),
              ),
            if (ocorrencia.caixaNome != null &&
                ocorrencia.caixaNome!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Caixa: ${ocorrencia.caixaNome!}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            if (ocorrencia.colaboradorNome != null &&
                ocorrencia.colaboradorNome!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Colaborador: ${ocorrencia.colaboradorNome!}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Descricao', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSection,
                borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                ocorrencia.descricao.isEmpty
                    ? 'Sem descricao.'
                    : ocorrencia.descricao,
                style: AppTextStyles.body,
              ),
            ),
            if ((ocorrencia.fotoUrl != null &&
                    ocorrencia.fotoUrl!.isNotEmpty) ||
                (ocorrencia.arquivoUrl != null &&
                    ocorrencia.arquivoUrl!.isNotEmpty)) ...[
              const SizedBox(height: 16),
              const Text('Anexos', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    if (ocorrencia.fotoUrl != null &&
                        ocorrencia.fotoUrl!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.photo_outlined),
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
          ],
        ),
      ),
    );
  }
}
