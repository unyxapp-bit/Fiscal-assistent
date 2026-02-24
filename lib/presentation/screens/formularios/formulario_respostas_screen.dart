import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';

/// Tela de histórico de respostas de um formulário
class FormularioRespostasScreen extends StatelessWidget {
  final Formulario formulario;

  const FormularioRespostasScreen({
    super.key,
    required this.formulario,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FormularioProvider>(context);
    final respostas = provider.respostasPorFormulario(formulario.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formulario.titulo, style: AppTextStyles.h4),
            Text(
              '${respostas.length} resposta(s)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: respostas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.inactive,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma resposta ainda',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha o formulário para ver\nas respostas aqui',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              itemCount: respostas.length,
              itemBuilder: (context, index) {
                final resposta = respostas[index];
                return Card(
                  margin:
                      const EdgeInsets.only(bottom: Dimensions.spacingSM),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${respostas.length - index}',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      'Resposta #${respostas.length - index}',
                      style: AppTextStyles.h4,
                    ),
                    subtitle: Text(
                      _formatDateTime(resposta.preenchidoEm),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => _mostrarDetalhes(context, resposta),
                  ),
                );
              },
            ),
    );
  }

  void _mostrarDetalhes(BuildContext context, RespostaFormulario resposta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formulario.titulo, style: AppTextStyles.h3),
                      Text(
                        _formatDateTime(resposta.preenchidoEm),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Conteúdo
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: resposta.valores.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (ctx, index) {
                  final entrada = resposta.valores.entries.elementAt(index);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrada.key,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entrada.value?.toString().isNotEmpty == true
                            ? entrada.value.toString()
                            : '(não preenchido)',
                        style: AppTextStyles.body.copyWith(
                          color: entrada.value?.toString().isNotEmpty == true
                              ? AppColors.textPrimary
                              : AppColors.inactive,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} às $hora:$min';
  }
}
