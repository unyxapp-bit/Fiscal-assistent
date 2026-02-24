import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/procedimento_provider.dart';
import 'procedimento_form_screen.dart';
import 'procedimento_detail_screen.dart';

class ProcedimentosScreen extends StatelessWidget {
  const ProcedimentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProcedimentoProvider>(context);
    final favoritos = provider.favoritos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Procedimentos'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Botão de adicionar novo procedimento
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProcedimentoFormScreen(),
                ),
              );
            },
            tooltip: 'Novo procedimento',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favoritos.isNotEmpty) ...[
              const Text('Favoritos', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingSM),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: favoritos.length,
                itemBuilder: (context, index) {
                  final proc = favoritos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.orange),
                      title: Text(proc.titulo),
                      subtitle: Text(proc.categoria),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProcedimentoDetailScreen(
                              procedimento: proc,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: Dimensions.spacingLG),
            ],

            const Text('Todos os Procedimentos', style: AppTextStyles.h3),
            const SizedBox(height: Dimensions.spacingSM),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.procedimentos.length,
              itemBuilder: (context, index) {
                final proc = provider.procedimentos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoriaColor(proc.categoria),
                      child: Icon(
                        _getCategoriaIcon(proc.categoria),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(proc.titulo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          proc.categoria,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (proc.tempoEstimado != null)
                          Text(
                            '${proc.tempoEstimado} min',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        proc.favorito ? Icons.star : Icons.star_outline,
                        color: proc.favorito ? Colors.orange : null,
                      ),
                      onPressed: () => provider.toggleFavorito(proc.id),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProcedimentoDetailScreen(
                            procedimento: proc,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
}
