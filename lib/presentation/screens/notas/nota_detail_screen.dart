import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/nota.dart';
import '../../../domain/enums/tipo_lembrete.dart';
import '../../providers/nota_provider.dart';
import 'nota_form_screen.dart';
import '../../../core/utils/app_notif.dart';

class NotaDetailScreen extends StatelessWidget {
  final String notaId;
  final Nota? notaInicial;

  const NotaDetailScreen({
    super.key,
    required this.notaId,
    this.notaInicial,
  });

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm').format(dt);

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotaProvider>(context);
    final nota = provider.obterPorId(notaId) ?? notaInicial;

    if (nota == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da Nota')),
        body: const Center(
          child: Text('Nota nao encontrada.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Detalhes da Nota', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NotaFormScreen(nota: nota)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nota.titulo, style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(nota.tipo.icone, size: 16, color: nota.tipo.cor),
                  label: Text(nota.tipo.nome),
                  backgroundColor: nota.tipo.cor.withValues(alpha: 0.12),
                ),
                if (nota.importante)
                  const Chip(
                    avatar: Icon(Icons.star, size: 16, color: Colors.orange),
                    label: Text('Importante'),
                  ),
                if (nota.concluida)
                  const Chip(
                    avatar: Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    label: Text('Concluida'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Criada em ${_formatDateTime(nota.createdAt)}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Atualizada em ${_formatDateTime(nota.updatedAt)}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (nota.dataLembrete != null) ...[
              const SizedBox(height: 4),
              Text(
                'Prazo/Lembrete: ${_formatDateTime(nota.dataLembrete!)}',
                style: AppTextStyles.caption.copyWith(
                  color: nota.isVencido
                      ? AppColors.danger
                      : AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Conteudo', style: AppTextStyles.h4),
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
                nota.conteudo.isEmpty ? 'Sem conteudo.' : nota.conteudo,
                style: AppTextStyles.body,
              ),
            ),
            if ((nota.fotoUrl != null && nota.fotoUrl!.isNotEmpty) ||
                (nota.arquivoUrl != null && nota.arquivoUrl!.isNotEmpty)) ...[
              const SizedBox(height: 16),
              const Text('Anexos', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    if (nota.fotoUrl != null && nota.fotoUrl!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.photo_outlined),
                        title: const Text('Foto'),
                        subtitle: Text(
                          nota.fotoNome ?? 'arquivo de imagem',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () =>
                              _copiar(context, nota.fotoUrl!, 'URL da foto'),
                        ),
                      ),
                    if (nota.fotoUrl != null &&
                        nota.fotoUrl!.isNotEmpty &&
                        nota.arquivoUrl != null &&
                        nota.arquivoUrl!.isNotEmpty)
                      const Divider(height: 1),
                    if (nota.arquivoUrl != null && nota.arquivoUrl!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: const Text('Arquivo'),
                        subtitle: Text(
                          nota.arquivoNome ?? 'arquivo anexado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => _copiar(
                              context, nota.arquivoUrl!, 'URL do arquivo'),
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
