import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';
import '../../../core/utils/app_notif.dart';

class FormularioRespostasScreen extends StatelessWidget {
  final Formulario formulario;

  const FormularioRespostasScreen({
    super.key,
    required this.formulario,
  });

  // Ã¢â€â‚¬Ã¢â€â‚¬ Helper: campo pelo label Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  CampoFormulario? _findCampo(String label) {
    try {
      return formulario.campos.firstWhere((c) => c.label == label);
    } catch (_) {
      return null;
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Formato de data Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  String _formatDateTime(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} ÃƒÂ s $hora:$min';
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Texto formatado para clipboard Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  String _respostaParaTexto(RespostaFormulario resposta) {
    final buf = StringBuffer();
    buf.writeln(formulario.titulo);
    buf.writeln(_formatDateTime(resposta.preenchidoEm));
    buf.writeln('Ã¢â€â‚¬' * 30);
    for (final e in resposta.valores.entries) {
      final val = e.value?.toString().isNotEmpty == true
          ? e.value.toString()
          : '(nÃƒÂ£o preenchido)';
      buf.writeln('${e.key}: $val');
    }
    return buf.toString().trim();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Delete com confirmaÃƒÂ§ÃƒÂ£o Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  void _confirmarDelete(
    BuildContext context,
    RespostaFormulario resposta,
    FormularioProvider provider,
    int numero,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir resposta'),
        content: Text('Excluir a Resposta #$numero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletarResposta(resposta.id);
              Navigator.pop(ctx);
            },
            child: Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

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
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: respostas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: AppColors.inactive),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma resposta ainda',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Preencha o formulÃƒÂ¡rio para ver\nas respostas aqui',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              itemCount: respostas.length,
              itemBuilder: (context, index) {
                final resposta = respostas[index];
                final numero = respostas.length - index;
                return Card(
                  margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
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
                        '$numero',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Resposta #$numero', style: AppTextStyles.h4),
                    subtitle: Text(
                      _formatDateTime(resposta.preenchidoEm),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copiar
                        IconButton(
                          icon: Icon(Icons.copy,
                              size: 18, color: AppColors.textSecondary),
                          tooltip: 'Copiar resposta',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: _respostaParaTexto(resposta)));
                            AppNotif.show(
                              context,
                              titulo: 'Copiado',
                              mensagem:
                                  'Resposta copiada para ÃƒÂ¡rea de transferÃƒÂªncia',
                              tipo: 'intervalo',
                            );
                          },
                        ),
                        // Deletar
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: AppColors.danger),
                          tooltip: 'Excluir resposta',
                          onPressed: () => _confirmarDelete(
                              context, resposta, provider, numero),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                      ],
                    ),
                    onTap: () => _mostrarDetalhes(context, resposta, numero),
                  ),
                );
              },
            ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Bottom sheet de detalhes Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  void _mostrarDetalhes(
    BuildContext context,
    RespostaFormulario resposta,
    int numero,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
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

            // CabeÃƒÂ§alho
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formulario.titulo, style: AppTextStyles.h3),
                        Text(
                          _formatDateTime(resposta.preenchidoEm),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Copiar tudo
                  IconButton(
                    icon: Icon(Icons.copy),
                    tooltip: 'Copiar tudo',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _respostaParaTexto(resposta)));
                      AppNotif.show(
                        context,
                        titulo: 'Copiado',
                        mensagem: 'Copiado para ÃƒÂ¡rea de transferÃƒÂªncia',
                        tipo: 'intervalo',
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            Divider(),

            // ConteÃƒÂºdo
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: resposta.valores.length,
                separatorBuilder: (_, __) => Divider(height: 24),
                itemBuilder: (ctx, i) {
                  final entry = resposta.valores.entries.elementAt(i);
                  final campo = _findCampo(entry.key);
                  final valStr = entry.value?.toString().isNotEmpty == true
                      ? entry.value.toString()
                      : '(nÃƒÂ£o preenchido)';
                  final preenchido = entry.value?.toString().isNotEmpty == true;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      // ExibiÃƒÂ§ÃƒÂ£o especial para Sim/NÃƒÂ£o
                      if (campo?.tipo == TipoCampo.simNao && preenchido)
                        Row(
                          children: [
                            Icon(
                              valStr == 'Sim'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: valStr == 'Sim'
                                  ? AppColors.success
                                  : AppColors.danger,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              valStr,
                              style: AppTextStyles.body.copyWith(
                                color: valStr == 'Sim'
                                    ? AppColors.success
                                    : AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          valStr,
                          style: AppTextStyles.body.copyWith(
                            color: preenchido
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
}
