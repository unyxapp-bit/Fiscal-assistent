import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/procedimento_provider.dart';
import 'procedimento_form_screen.dart';

/// Tela de Detalhes do Procedimento
/// Exibe informações completas de um procedimento
class ProcedimentoDetailScreen extends StatelessWidget {
  final Procedimento procedimento;

  const ProcedimentoDetailScreen({
    super.key,
    required this.procedimento,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProcedimentoProvider>(context);
    final proc = provider.procedimentos.firstWhere(
      (p) => p.id == procedimento.id,
      orElse: () => procedimento,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Detalhes do Procedimento', style: AppTextStyles.h3),
        actions: [
          // Botão de editar
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProcedimentoFormScreen(procedimento: proc),
                ),
              );
            },
            tooltip: 'Editar procedimento',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com título e favorito
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
                          child: Text(
                            proc.titulo,
                            style: AppTextStyles.h2,
                          ),
                        ),
                        // Botão de favoritar
                        IconButton(
                          icon: Icon(
                            proc.favorito ? Icons.star : Icons.star_outline,
                            color: proc.favorito ? Colors.orange : AppColors.textSecondary,
                            size: Dimensions.iconXL,
                          ),
                          onPressed: () => provider.toggleFavorito(proc.id),
                          tooltip: proc.favorito
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spacingSM),

                    // Badge da categoria
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSM,
                        vertical: Dimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoriaColor(proc.categoria),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoriaIcon(proc.categoria),
                            color: Colors.white,
                            size: Dimensions.iconSM,
                          ),
                          const SizedBox(width: Dimensions.spacingXXS),
                          Text(
                            _getCategoriaNome(proc.categoria),
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
                      const SizedBox(height: Dimensions.spacingSM),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            size: Dimensions.iconMD,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: Dimensions.spacingXS),
                          Text(
                            'Tempo estimado: ${proc.tempoEstimado} minutos',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // Descrição
            if (proc.descricao.isNotEmpty) ...[
              const Text('Descrição', style: AppTextStyles.h4),
              const SizedBox(height: Dimensions.spacingSM),
              Card(
                elevation: Dimensions.cardElevation,
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  child: Text(
                    proc.descricao,
                    style: AppTextStyles.body,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spacingLG),
            ],

            // Passos
            const Text('Passos', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),

            // Lista de passos numerados
            Card(
              elevation: Dimensions.cardElevation,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: proc.passos.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: Dimensions.spacingLG,
                  ),
                  itemBuilder: (context, index) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Número do passo
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.spacingMD),

                        // Texto do passo
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: Dimensions.paddingXS,
                            ),
                            child: Text(
                              proc.passos[index],
                              style: AppTextStyles.body,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'abertura':
        return AppColors.success;
      case 'fechamento':
        return AppColors.danger;
      case 'emergencia':
        return AppColors.statusAtencao;
      case 'rotina':
        return AppColors.primary;
      case 'fiscal':
        return Colors.purple;
      case 'caixa':
        return AppColors.statusCafe;
      default:
        return AppColors.inactive;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'abertura':
        return Icons.lock_open;
      case 'fechamento':
        return Icons.lock;
      case 'emergencia':
        return Icons.warning;
      case 'rotina':
        return Icons.checklist;
      case 'fiscal':
        return Icons.person;
      case 'caixa':
        return Icons.point_of_sale;
      default:
        return Icons.help;
    }
  }

  String _getCategoriaNome(String categoria) {
    switch (categoria) {
      case 'abertura':
        return 'Abertura';
      case 'fechamento':
        return 'Fechamento';
      case 'emergencia':
        return 'Emergência';
      case 'rotina':
        return 'Rotina';
      case 'fiscal':
        return 'Fiscal';
      case 'caixa':
        return 'Caixa';
      default:
        return categoria;
    }
  }
}
