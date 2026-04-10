import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/nota.dart';
import '../../../domain/enums/tipo_lembrete.dart';
import '../../providers/nota_provider.dart';
import 'nota_form_screen.dart';
import 'nota_detail_screen.dart';
import '../../../core/utils/app_notif.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Verifica se hÃƒÂ¡ filtros nÃƒÂ£o-padrÃƒÂ£o ativos Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  bool _filtroAtivo(NotaProvider provider) {
    return provider.filtroTipo != null ||
        provider.mostrarApenasPendentes ||
        provider.ordenacao != OrdenacaoNota.importancia;
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Bottom sheet para escolher tipo ao criar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  void _mostrarMenuCriar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Criar nova', style: AppTextStyles.h4),
            SizedBox(height: 8),
            ...TipoLembrete.values.map((tipo) {
              const descricoes = {
                TipoLembrete.anotacao: 'Texto livre para registros',
                TipoLembrete.tarefa: 'Item a fazer, com prazo opcional',
                TipoLembrete.lembrete: 'Alerta em data e hora especÃƒÂ­ficos',
              };
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tipo.cor.withValues(alpha: 0.15),
                  child: Icon(tipo.icone, color: tipo.cor),
                ),
                title: Text(tipo.nome),
                subtitle: Text(descricoes[tipo]!),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotaFormScreen(tipoInicial: tipo),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Bottom sheet de filtros / ordenaÃƒÂ§ÃƒÂ£o Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  void _abrirMenuFiltro(BuildContext context, NotaProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inactive,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text('Ordenar por', style: AppTextStyles.h4),
                SizedBox(height: 8),
                RadioGroup<OrdenacaoNota>(
                  groupValue: provider.ordenacao,
                  onChanged: (v) {
                    if (v != null) {
                      provider.setOrdenacao(v);
                      setModalState(() {});
                    }
                  },
                  child: Column(
                    children: OrdenacaoNota.values.map((o) {
                      const labels = {
                        OrdenacaoNota.importancia: 'ImportÃƒÂ¢ncia',
                        OrdenacaoNota.dataCriacao: 'Data de criaÃƒÂ§ÃƒÂ£o',
                        OrdenacaoNota.dataVencimento: 'Prazo / vencimento',
                        OrdenacaoNota.tipo: 'Tipo',
                      };
                      return RadioListTile<OrdenacaoNota>(
                        value: o,
                        title: Text(labels[o]!),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
                Divider(),
                SwitchListTile(
                  title: Text('Apenas pendentes'),
                  value: provider.mostrarApenasPendentes,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    provider.setMostrarApenasPendentes(v);
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      provider.limparFiltros();
                      _searchController.clear();
                      Navigator.pop(ctx);
                    },
                    child: Text('Limpar filtros'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ ConfirmaÃƒÂ§ÃƒÂ£o de delete Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Future<bool> _confirmarDelete(
      BuildContext context, Nota nota, NotaProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar exclusÃƒÂ£o'),
        content: Text('Deletar "${nota.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Deletar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) provider.deletarNota(nota.id);
    return false; // nÃƒÂ£o deixa o Dismissible remover o widget (jÃƒÂ¡ notifyListeners)
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Itens da lista com seÃƒÂ§ÃƒÂµes Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  List<Widget> _buildListItems(NotaProvider provider) {
    final notas = provider.notas;
    if (notas.isEmpty) return [];

    // Com busca ativa: lista plana sem seÃƒÂ§ÃƒÂµes
    if (provider.searchQuery.isNotEmpty) {
      return notas.map((n) => _buildNotaCard(n, provider)).toList();
    }

    final filtro = provider.filtroTipo;

    if (filtro == TipoLembrete.tarefa) {
      final pendentes = notas.where((n) => !n.concluida).toList();
      final concluidas = notas.where((n) => n.concluida).toList();
      return [
        if (pendentes.isNotEmpty) _sectionHeader('Pendentes', Colors.orange),
        ...pendentes.map((n) => _buildNotaCard(n, provider)),
        if (concluidas.isNotEmpty)
          _sectionHeader('ConcluÃƒÂ­das', AppColors.success),
        ...concluidas.map((n) => _buildNotaCard(n, provider)),
      ];
    }

    if (filtro == TipoLembrete.lembrete) {
      final vencidos = notas.where((n) => n.isVencido).toList();
      final ativos = notas.where((n) => !n.isVencido).toList();
      return [
        if (vencidos.isNotEmpty) _sectionHeader('Vencidos', AppColors.danger),
        ...vencidos.map((n) => _buildNotaCard(n, provider)),
        if (ativos.isNotEmpty) _sectionHeader('Ativos', AppColors.primary),
        ...ativos.map((n) => _buildNotaCard(n, provider)),
      ];
    }

    // Todos Ã¢â‚¬â€ vencidos no topo se houver
    final vencidos = notas.where((n) => n.isVencido).toList();
    final restante = notas.where((n) => !n.isVencido).toList();
    return [
      if (vencidos.isNotEmpty) _sectionHeader('Vencidos', AppColors.danger),
      ...vencidos.map((n) => _buildNotaCard(n, provider)),
      ...restante.map((n) => _buildNotaCard(n, provider)),
    ];
  }

  Widget _sectionHeader(String titulo, Color cor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            titulo.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: cor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Card de nota individual Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildNotaCard(Nota nota, NotaProvider provider) {
    final isTarefa = nota.tipo == TipoLembrete.tarefa;
    return Dismissible(
      key: Key(nota.id),
      direction:
          isTarefa ? DismissDirection.horizontal : DismissDirection.endToStart,
      background: isTarefa
          ? Container(
              color: Colors.green.shade400,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: Icon(Icons.check, color: Colors.white),
            )
          : const SizedBox.shrink(),
      secondaryBackground: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          provider.toggleConcluida(nota.id);
          return false;
        }
        return _confirmarDelete(context, nota, provider);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
        shape: nota.importante
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                side: BorderSide(color: Colors.orange, width: 1.5),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusMD),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotaDetailScreen(
                notaId: nota.id,
                notaInicial: nota,
              ),
            ),
          ),
          onLongPress: () => _copiarNota(nota),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: GestureDetector(
                onTap:
                    isTarefa ? () => provider.toggleConcluida(nota.id) : null,
                child: Icon(
                  isTarefa && nota.concluida
                      ? Icons.check_box
                      : isTarefa
                          ? Icons.check_box_outline_blank
                          : nota.tipo.icone,
                  color: nota.concluida ? AppColors.inactive : nota.tipo.cor,
                ),
              ),
              title: Text(
                nota.titulo,
                style: TextStyle(
                  decoration:
                      nota.concluida ? TextDecoration.lineThrough : null,
                  color: nota.concluida ? AppColors.textSecondary : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (nota.conteudo.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      nota.conteudo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (nota.importante) ...[
                        Icon(Icons.star, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                      ],
                      if (nota.dataLembrete != null) ...[
                        Icon(
                          Icons.alarm,
                          size: 12,
                          color: nota.isVencido
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          _formatData(nota.dataLembrete!),
                          style: AppTextStyles.caption.copyWith(
                            color: nota.isVencido
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (nota.isVencido) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Vencido',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                        SizedBox(width: 8),
                      ],
                      if (!nota.isVencido || nota.dataLembrete == null)
                        Text(
                          DateFormat('HH:mm').format(nota.createdAt),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _onMenuSelected(value, nota, provider),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  if (isTarefa)
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
                          SizedBox(width: 8),
                          Text(nota.concluida
                              ? 'Marcar pendente'
                              : 'Marcar concluÃƒÂ­da'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'toggle_importante',
                    child: Row(
                      children: [
                        Icon(
                          nota.importante ? Icons.star_border : Icons.star,
                          size: 18,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(nota.importante
                            ? 'Remover importante'
                            : 'Marcar importante'),
                      ],
                    ),
                  ),
                  if (nota.tipo == TipoLembrete.lembrete &&
                      nota.dataLembrete != null)
                    PopupMenuItem(
                      value: 'toggle_lembrete_ativo',
                      child: Row(
                        children: [
                          Icon(
                            nota.lembreteAtivo
                                ? Icons.notifications_off
                                : Icons.notifications_active,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(nota.lembreteAtivo
                              ? 'Desativar notificaÃƒÂ§ÃƒÂ£o'
                              : 'Ativar notificaÃƒÂ§ÃƒÂ£o'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'copiar',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Copiar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'compartilhar',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18),
                        SizedBox(width: 8),
                        Text('Compartilhar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Deletar',
                            style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onMenuSelected(String value, Nota nota, NotaProvider provider) {
    switch (value) {
      case 'editar':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NotaFormScreen(nota: nota)),
        );
        break;
      case 'toggle_concluida':
        provider.toggleConcluida(nota.id);
        break;
      case 'toggle_importante':
        provider.toggleImportante(nota.id);
        break;
      case 'toggle_lembrete_ativo':
        provider.toggleLembreteAtivo(nota.id);
        break;
      case 'copiar':
        _copiarNota(nota);
        break;
      case 'compartilhar':
        _compartilharNota(nota);
        break;
      case 'delete':
        _confirmarDelete(context, nota, provider);
        break;
    }
  }

  String _textoCompartilhamento(Nota nota) {
    final buf = StringBuffer();
    buf.writeln('*${nota.titulo}*');
    if (nota.conteudo.isNotEmpty) {
      buf.writeln();
      buf.writeln(nota.conteudo);
    }
    if (nota.dataLembrete != null) {
      final fmt = DateFormat('dd/MM/yyyy HH:mm').format(nota.dataLembrete!);
      buf.writeln();
      buf.write('Ã°Å¸â€œâ€¦ ${nota.tipo.nome}: $fmt');
    } else {
      buf.write('\n_${nota.tipo.nome}_');
    }
    return buf.toString();
  }

  Future<void> _copiarNota(Nota nota) async {
    await Clipboard.setData(ClipboardData(text: _textoCompartilhamento(nota)));
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Copiado para ÃƒÂ¡rea de transferÃƒÂªncia',
      tipo: 'intervalo',
    );
  }

  void _compartilharNota(Nota nota) {
    Share.share(_textoCompartilhamento(nota), subject: nota.titulo);
  }

  String _formatData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes ÃƒÂ s $h:$m';
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Chip de tipo Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
      selectedColor: tipo?.cor.withValues(alpha: 0.2) ??
          AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? (tipo?.cor ?? AppColors.primary)
            : AppColors.textSecondary,
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Build Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotaProvider>(context);
    final vencidos = provider.totalLembretesVencidos;
    final lembretesLabel = vencidos > 0
        ? 'Lembretes ($vencidosÃ¢Å¡Â )'
        : 'Lembretes (${provider.lembretes.length})';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AnotaÃƒÂ§ÃƒÂµes e Lembretes'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.filter_list),
                if (_filtroAtivo(provider))
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filtros e ordenaÃƒÂ§ÃƒÂ£o',
            onPressed: () => _abrirMenuFiltro(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ã¢â€â‚¬Ã¢â€â‚¬ Busca Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 8, Dimensions.paddingMD, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                ),
              ),
              onChanged: (v) {
                provider.setSearchQuery(v);
                setState(() {});
              },
            ),
          ),

          SizedBox(height: 8),

          // Ã¢â€â‚¬Ã¢â€â‚¬ Cards de resumo Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Tarefas',
                    value: provider.tarefas.isEmpty
                        ? '0'
                        : '${provider.tarefasConcluidas.length}/${provider.tarefas.length}',
                    color: TipoLembrete.tarefa.cor,
                    icon: TipoLembrete.tarefa.icone,
                    progresso: provider.tarefas.isEmpty
                        ? null
                        : provider.tarefasConcluidas.length /
                            provider.tarefas.length,
                  ),
                ),
                SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: _StatCard(
                    label: 'Lembretes',
                    value: provider.totalLembretesAtivos.toString(),
                    color: vencidos > 0
                        ? AppColors.danger
                        : TipoLembrete.lembrete.cor,
                    icon: vencidos > 0
                        ? Icons.alarm_off
                        : TipoLembrete.lembrete.icone,
                  ),
                ),
                SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: _StatCard(
                    label: 'Total',
                    value: provider.totalNotas.toString(),
                    color: AppColors.primary,
                    icon: Icons.note,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Ã¢â€â‚¬Ã¢â€â‚¬ Chips de filtro por tipo Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
              children: [
                _buildTipoChip(
                    'Todos (${provider.totalNotas})', null, provider),
                SizedBox(width: 8),
                _buildTipoChip('AnotaÃƒÂ§ÃƒÂµes (${provider.anotacoes.length})',
                    TipoLembrete.anotacao, provider),
                SizedBox(width: 8),
                _buildTipoChip('Tarefas (${provider.tarefas.length})',
                    TipoLembrete.tarefa, provider),
                SizedBox(width: 8),
                _buildTipoChip(lembretesLabel, TipoLembrete.lembrete, provider),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Ã¢â€â‚¬Ã¢â€â‚¬ Lista Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          Expanded(
            child: provider.notas.isEmpty
                ? RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 320,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_outlined,
                                    size: 64, color: AppColors.inactive),
                                SizedBox(height: 16),
                                Text(
                                  provider.searchQuery.isNotEmpty
                                      ? 'Nenhum resultado para "${provider.searchQuery}"'
                                      : 'Nenhuma anotaÃƒÂ§ÃƒÂ£o ainda',
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                if (provider.searchQuery.isEmpty) ...[
                                  SizedBox(height: 24),
                                  Text('Criar:', style: AppTextStyles.label),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: TipoLembrete.values
                                        .map((tipo) => OutlinedButton.icon(
                                              icon: Icon(tipo.icone,
                                                  size: 16, color: tipo.cor),
                                              label: Text(tipo.nome,
                                                  style: TextStyle(
                                                      color: tipo.cor)),
                                              style: OutlinedButton.styleFrom(
                                                side:
                                                    BorderSide(color: tipo.cor),
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      NotaFormScreen(
                                                          tipoInicial: tipo),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(Dimensions.paddingMD,
                          0, Dimensions.paddingMD, Dimensions.paddingMD),
                      children: _buildListItems(provider),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarMenuCriar(context),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Stat card Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final double? progresso;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.progresso,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSM),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.h3
                  .copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            Text(label,
                style: AppTextStyles.caption, textAlign: TextAlign.center),
            if (progresso != null) ...[
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
