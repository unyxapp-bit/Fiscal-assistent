import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';
import 'formulario_editor_screen.dart';
import 'formulario_preenchimento_screen.dart';
import 'formulario_respostas_screen.dart';

class FormulariosScreen extends StatelessWidget {
  const FormulariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FormularioProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Formulários'),
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Templates', icon: Icon(Icons.library_books)),
              Tab(text: 'Personalizados', icon: Icon(Icons.edit_note)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Templates
            _buildListaFormularios(context, provider.templates, true),

            // Tab 2: Personalizados
            _buildListaFormularios(context, provider.personalizados, false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FormularioEditorScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Criar Formulário'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildListaFormularios(
    BuildContext context,
    List<Formulario> formularios,
    bool isTemplate,
  ) {
    if (formularios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.inactive,
            ),
            const SizedBox(height: 16),
            Text(
              isTemplate
                  ? 'Nenhum template disponível'
                  : 'Nenhum formulário personalizado',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      itemCount: formularios.length,
      itemBuilder: (context, index) {
        final formulario = formularios[index];
        final provider = Provider.of<FormularioProvider>(context);
        final totalRespostas =
            provider.totalRespostasPorFormulario(formulario.id);

        return Card(
          margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description,
                color: AppColors.primary,
              ),
            ),
            title: Text(formulario.titulo, style: AppTextStyles.h4),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  formulario.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formulario.campos.length} campos • $totalRespostas respostas',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'preencher',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, size: 18),
                      SizedBox(width: 8),
                      Text('Preencher'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'respostas',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18),
                      SizedBox(width: 8),
                      Text('Ver Respostas'),
                    ],
                  ),
                ),
                if (!isTemplate)
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                if (!isTemplate)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Deletar', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'preencher') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FormularioPreenchimentoScreen(
                        formulario: formulario,
                      ),
                    ),
                  );
                } else if (value == 'respostas') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FormularioRespostasScreen(
                        formulario: formulario,
                      ),
                    ),
                  );
                } else if (value == 'editar') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FormularioEditorScreen(
                        formulario: formulario,
                      ),
                    ),
                  );
                } else if (value == 'delete') {
                  final respostas = Provider.of<FormularioProvider>(context, listen: false)
                      .totalRespostasPorFormulario(formulario.id);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar exclusão'),
                      content: Text(
                        respostas > 0
                            ? 'Deletar "${formulario.titulo}"? Isso também excluirá $respostas resposta(s).'
                            : 'Deletar "${formulario.titulo}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<FormularioProvider>(context, listen: false)
                                .deletarFormulario(formulario.id);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Deletar',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FormularioPreenchimentoScreen(
                    formulario: formulario,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
