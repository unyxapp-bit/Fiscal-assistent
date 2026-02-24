import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/enums/tipo_lembrete.dart';
import '../../providers/nota_provider.dart';
import 'nota_form_screen.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotaProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Anotações e Lembretes'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Mostrar todos'),
              ),
              const PopupMenuItem(
                value: 'pendentes',
                child: Text('Apenas pendentes'),
              ),
              const PopupMenuItem(
                value: 'limpar',
                child: Text('Limpar filtros'),
              ),
            ],
            onSelected: (value) {
              if (value == 'todos') {
                provider.setMostrarApenasPendentes(false);
              } else if (value == 'pendentes') {
                provider.setMostrarApenasPendentes(true);
              } else if (value == 'limpar') {
                provider.limparFiltros();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Cards de resumo
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tarefas',
                    provider.totalTarefasPendentes.toString(),
                    TipoLembrete.tarefa.cor,
                    TipoLembrete.tarefa.icone,
                  ),
                ),
                const SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: _buildStatCard(
                    'Lembretes',
                    provider.totalLembretesAtivos.toString(),
                    TipoLembrete.lembrete.cor,
                    TipoLembrete.lembrete.icone,
                  ),
                ),
                const SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    provider.totalNotas.toString(),
                    AppColors.primary,
                    Icons.note,
                  ),
                ),
              ],
            ),
          ),

          // Filtros de tipo
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
              children: [
                _buildTipoChip('Todos', null, provider),
                const SizedBox(width: 8),
                ...TipoLembrete.values.map((tipo) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTipoChip(tipo.nome, tipo, provider),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Lista de notas
          Expanded(
            child: provider.notas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: AppColors.inactive,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma anotação',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    itemCount: provider.notas.length,
                    itemBuilder: (context, index) {
                      final nota = provider.notas[index];
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.spacingSM),
                        child: ListTile(
                          leading: Icon(
                            nota.tipo.icone,
                            color: nota.tipo.cor,
                          ),
                          title: Text(nota.titulo),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                nota.conteudo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (nota.importante)
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                  if (nota.importante)
                                    const SizedBox(width: 4),
                                  Text(
                                    DateFormat('HH:mm').format(nota.createdAt),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
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
                              if (nota.tipo == TipoLembrete.tarefa)
                                PopupMenuItem(
                                  value: 'toggle_concluida',
                                  child: Row(
                                    children: [
                                      Icon(
                                        nota.concluida
                                            ? Icons.undo
                                            : Icons.check_circle_outline,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        nota.concluida
                                            ? 'Marcar pendente'
                                            : 'Marcar concluída',
                                      ),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'toggle_importante',
                                child: Row(
                                  children: [
                                    Icon(
                                      nota.importante
                                          ? Icons.star_border
                                          : Icons.star,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      nota.importante
                                          ? 'Remover importante'
                                          : 'Marcar importante',
                                    ),
                                  ],
                                ),
                              ),
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
                              if (value == 'editar') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => NotaFormScreen(nota: nota),
                                  ),
                                );
                              } else if (value == 'toggle_concluida') {
                                provider.toggleConcluida(nota.id);
                              } else if (value == 'toggle_importante') {
                                provider.toggleImportante(nota.id);
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirmar exclusão'),
                                    content: Text('Deletar "${nota.titulo}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          provider.deletarNota(nota.id);
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
                                builder: (_) => NotaFormScreen(nota: nota),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotaFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSM),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoChip(
    String label,
    TipoLembrete? tipo,
    NotaProvider provider,
  ) {
    final isSelected = provider.filtroTipo == tipo;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setFiltroTipo(tipo),
      backgroundColor: Colors.white,
      selectedColor:
          tipo?.cor.withValues(alpha: 0.2) ?? AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? (tipo?.cor ?? AppColors.primary)
            : AppColors.textSecondary,
      ),
    );
  }

}
