import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/procedimento_provider.dart';
import 'procedimento_form_screen.dart';
import '../../../core/utils/app_notif.dart';

class ProcedimentoDetailScreen extends StatefulWidget {
  final Procedimento procedimento;

  const ProcedimentoDetailScreen({
    super.key,
    required this.procedimento,
  });

  @override
  State<ProcedimentoDetailScreen> createState() =>
      _ProcedimentoDetailScreenState();
}

class _ProcedimentoDetailScreenState extends State<ProcedimentoDetailScreen> {
  // Passos marcados como concluÃƒÂ­dos (estado apenas em memÃƒÂ³ria)
  final Set<int> _passosConcluidos = {};

  void _copiar(BuildContext context, Procedimento proc) {
    final buf = StringBuffer();
    buf.writeln(proc.titulo);
    if (proc.descricao.isNotEmpty) {
      buf.writeln();
      buf.writeln(proc.descricao);
    }
    buf.writeln();
    for (var i = 0; i < proc.passos.length; i++) {
      buf.writeln('${i + 1}. ${proc.passos[i]}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString().trim()));
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Copiado para ÃƒÂ¡rea de transferÃƒÂªncia',
      tipo: 'intervalo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProcedimentoProvider>(context);
    final proc = provider.procedimentos.firstWhere(
      (p) => p.id == widget.procedimento.id,
      orElse: () => widget.procedimento,
    );

    final total = proc.passos.length;
    final concluidos = _passosConcluidos.length;
    final progresso = total > 0 ? concluidos / total : 0.0;
    final tudo = progresso == 1.0 && total > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Detalhes', style: AppTextStyles.h3),
        actions: [
          // Copiar
          IconButton(
            icon: Icon(Icons.copy),
            tooltip: 'Copiar procedimento',
            onPressed: () => _copiar(context, proc),
          ),
          // Reiniciar execuÃƒÂ§ÃƒÂ£o (sÃƒÂ³ se algum passo foi marcado)
          if (_passosConcluidos.isNotEmpty)
            IconButton(
              icon: Icon(Icons.restart_alt),
              tooltip: 'Reiniciar execuÃƒÂ§ÃƒÂ£o',
              onPressed: () => setState(() => _passosConcluidos.clear()),
            ),
          // Editar
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Editar procedimento',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProcedimentoFormScreen(procedimento: proc),
            )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ã¢â€â‚¬Ã¢â€â‚¬ CabeÃƒÂ§alho Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
            Card(
              elevation: Dimensions.cardElevation,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(proc.titulo, style: AppTextStyles.h2),
                        ),
                        IconButton(
                          icon: Icon(
                            proc.favorito ? Icons.star : Icons.star_outline,
                            color: proc.favorito
                                ? Colors.orange
                                : AppColors.textSecondary,
                            size: Dimensions.iconXL,
                          ),
                          onPressed: () => provider.toggleFavorito(proc.id),
                          tooltip: proc.favorito
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spacingSM),

                    // Badge categoria
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSM,
                        vertical: Dimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: proc.categoria.categoriaColor,
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            proc.categoria.categoriaIcon,
                            color: Colors.white,
                            size: Dimensions.iconSM,
                          ),
                          SizedBox(width: Dimensions.spacingXXS),
                          Text(
                            proc.categoria.categoriaNome,
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tempo estimado
                    if (proc.tempoEstimado != null) ...[
                      SizedBox(height: Dimensions.spacingSM),
                      Row(
                        children: [
                          Icon(Icons.timer,
                              size: Dimensions.iconMD,
                              color: AppColors.textSecondary),
                          SizedBox(width: Dimensions.spacingXS),
                          Text(
                            'Tempo estimado: ${proc.tempoEstimado} minutos',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: Dimensions.spacingLG),

            // Ã¢â€â‚¬Ã¢â€â‚¬ DescriÃƒÂ§ÃƒÂ£o Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
            if (proc.descricao.isNotEmpty) ...[
              Text('DescriÃƒÂ§ÃƒÂ£o', style: AppTextStyles.h4),
              SizedBox(height: Dimensions.spacingSM),
              Card(
                elevation: Dimensions.cardElevation,
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  child: Text(proc.descricao, style: AppTextStyles.body),
                ),
              ),
              SizedBox(height: Dimensions.spacingLG),
            ],

            // Ã¢â€â‚¬Ã¢â€â‚¬ Passos com progresso Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
            Row(
              children: [
                Text('Passos', style: AppTextStyles.h4),
                const Spacer(),
                if (total > 0)
                  Text(
                    '$concluidos/$total',
                    style: AppTextStyles.caption.copyWith(
                      color: tudo ? AppColors.success : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            SizedBox(height: Dimensions.spacingSM),

            // Barra de progresso
            if (total > 0) ...[
              LinearProgressIndicator(
                value: progresso,
                backgroundColor: AppColors.inactive.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  tudo ? AppColors.success : AppColors.primary,
                ),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              SizedBox(height: Dimensions.spacingMD),
            ],

            // Lista de passos com checkboxes
            Card(
              elevation: Dimensions.cardElevation,
              child: Column(
                children: proc.passos.asMap().entries.map((entry) {
                  final i = entry.key;
                  final passo = entry.value;
                  final concluido = _passosConcluidos.contains(i);
                  return Column(
                    children: [
                      CheckboxListTile(
                        value: concluido,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _passosConcluidos.add(i);
                          } else {
                            _passosConcluidos.remove(i);
                          }
                        }),
                        title: Text(
                          passo,
                          style: AppTextStyles.body.copyWith(
                            decoration:
                                concluido ? TextDecoration.lineThrough : null,
                            color: concluido
                                ? AppColors.inactive
                                : AppColors.textPrimary,
                          ),
                        ),
                        secondary: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: concluido
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: AppTextStyles.caption.copyWith(
                                color: concluido
                                    ? AppColors.success
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                        activeColor: AppColors.success,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingMD,
                          vertical: Dimensions.paddingXS,
                        ),
                      ),
                      if (i < proc.passos.length - 1)
                        Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Banner de conclusÃƒÂ£o
            if (tudo) ...[
              SizedBox(height: Dimensions.spacingMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Procedimento concluÃƒÂ­do!',
                      style:
                          AppTextStyles.h4.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: Dimensions.spacingXL),
          ],
        ),
      ),
    );
  }
}
