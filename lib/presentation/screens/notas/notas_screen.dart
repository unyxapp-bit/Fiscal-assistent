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
  final _quickCreateCtrl = TextEditingController();
  bool _filtroImportantes = false;

  @override
  void dispose() {
    _searchController.dispose();
    _quickCreateCtrl.dispose();
    super.dispose();
  }

  // ── Filtro ativo ──────────────────────────────────────────────────────────
  bool _filtroAtivo(NotaProvider provider) {
    return provider.filtroTipo != null ||
        provider.mostrarApenasPendentes ||
        provider.ordenacao != OrdenacaoNota.importancia ||
        _filtroImportantes;
  }

  // ── Quick create ──────────────────────────────────────────────────────────
  void _criarRapido(NotaProvider provider) {
    final titulo = _quickCreateCtrl.text.trim();
    if (titulo.isEmpty) return;
    provider.adicionarNota(titulo, '', TipoLembrete.anotacao);
    _quickCreateCtrl.clear();
    setState(() {});
  }

  // ── Menu criar ────────────────────────────────────────────────────────────
  void _mostrarMenuCriar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusSheet)),
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
            const SizedBox(height: 16),
            Text('Criar nova', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            ...TipoLembrete.values.map((tipo) {
              const descricoes = {
                TipoLembrete.anotacao: 'Texto livre para registros',
                TipoLembrete.tarefa: 'Item a fazer, com prazo opcional',
                TipoLembrete.lembrete: 'Alerta em data e hora específicos',
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

  // ── Menu filtros ──────────────────────────────────────────────────────────
  void _abrirMenuFiltro(BuildContext context, NotaProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusSheet)),
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
                const SizedBox(height: 16),
                Text('Ordenar por', style: AppTextStyles.h4),
                const SizedBox(height: 8),
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
                        OrdenacaoNota.importancia: 'Importância',
                        OrdenacaoNota.dataCriacao: 'Data de criação',
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
                const Divider(),
                SwitchListTile(
                  title: const Text('Apenas pendentes'),
                  value: provider.mostrarApenasPendentes,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    provider.setMostrarApenasPendentes(v);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      provider.limparFiltros();
                      _searchController.clear();
                      setState(() => _filtroImportantes = false);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Limpar filtros'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<bool> _confirmarDelete(
      BuildContext context, Nota nota, NotaProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deletar "${nota.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Deletar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) provider.deletarNota(nota.id);
    return false;
  }

  // ── Lista com seções ──────────────────────────────────────────────────────
  List<Widget> _buildListItems(NotaProvider provider) {
    var notas = provider.notas;

    // Filtro de importantes aplicado client-side
    if (_filtroImportantes) {
      notas = notas.where((n) => n.importante).toList();
    }

    if (notas.isEmpty) return [];

    // Com busca ativa: lista plana
    if (provider.searchQuery.isNotEmpty) {
      return notas.map((n) => _buildNotaCard(n, provider)).toList();
    }

    final filtro = provider.filtroTipo;

    if (filtro == TipoLembrete.tarefa) {
      final pendentes = notas.where((n) => !n.concluida).toList();
      final concluidas = notas.where((n) => n.concluida).toList();
      return [
        if (pendentes.isNotEmpty)
          _sectionHeader('Pendentes', AppColors.warning),
        ...pendentes.map((n) => _buildNotaCard(n, provider)),
        if (concluidas.isNotEmpty)
          _sectionHeader('Concluídas', AppColors.success),
        ...concluidas.map((n) => _buildNotaCard(n, provider)),
      ];
    }

    if (filtro == TipoLembrete.lembrete) {
      final now = DateTime.now();
      final hoje = DateTime(now.year, now.month, now.day);
      final amanha = hoje.add(const Duration(days: 1));
      final semana = hoje.add(const Duration(days: 7));

      DateTime diaAlvo(Nota n) => DateTime(
          n.dataLembrete!.year, n.dataLembrete!.month, n.dataLembrete!.day);

      bool noIntervalo(Nota n, DateTime inicio, DateTime fim) =>
          n.dataLembrete != null &&
          !n.isVencido &&
          !diaAlvo(n).isBefore(inicio) &&
          diaAlvo(n).isBefore(fim);

      final vencidos = notas.where((n) => n.isVencido).toList();
      final hojeList = notas.where((n) => noIntervalo(n, hoje, amanha)).toList();
      final amanhaList = notas
          .where((n) => noIntervalo(
              n, amanha, amanha.add(const Duration(days: 1))))
          .toList();
      final semanaList = notas
          .where((n) => noIntervalo(
              n, amanha.add(const Duration(days: 1)), semana.add(const Duration(days: 1))))
          .toList();
      final futuros = notas
          .where((n) =>
              n.dataLembrete != null &&
              !n.isVencido &&
              diaAlvo(n).isAfter(semana))
          .toList();
      final semData = notas
          .where((n) => !n.isVencido && n.dataLembrete == null)
          .toList();

      return [
        if (vencidos.isNotEmpty)
          _sectionHeader('Vencidos', AppColors.danger),
        ...vencidos.map((n) => _buildNotaCard(n, provider)),
        if (hojeList.isNotEmpty)
          _sectionHeader('Hoje', AppColors.warning),
        ...hojeList.map((n) => _buildNotaCard(n, provider)),
        if (amanhaList.isNotEmpty)
          _sectionHeader('Amanhã', AppColors.primary),
        ...amanhaList.map((n) => _buildNotaCard(n, provider)),
        if (semanaList.isNotEmpty)
          _sectionHeader('Esta semana', AppColors.success),
        ...semanaList.map((n) => _buildNotaCard(n, provider)),
        if (futuros.isNotEmpty)
          _sectionHeader('Futuros', AppColors.textSecondary),
        ...futuros.map((n) => _buildNotaCard(n, provider)),
        if (semData.isNotEmpty)
          _sectionHeader('Sem data', AppColors.textSecondary),
        ...semData.map((n) => _buildNotaCard(n, provider)),
      ];
    }

    // Todos — vencidos no topo
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
          const SizedBox(width: 8),
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

  // ── Card de nota ──────────────────────────────────────────────────────────
  Widget _buildNotaCard(Nota nota, NotaProvider provider) {
    final isTarefa = nota.tipo == TipoLembrete.tarefa;
    return Dismissible(
      key: Key(nota.id),
      direction: isTarefa
          ? DismissDirection.horizontal
          : DismissDirection.endToStart,
      background: isTarefa
          ? Container(
              color: AppColors.success,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Colors.white),
            )
          : const SizedBox.shrink(),
      secondaryBackground: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
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
                side: BorderSide(color: AppColors.warning, width: 1.5),
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
                onTap: isTarefa
                    ? () => provider.toggleConcluida(nota.id)
                    : null,
                child: Icon(
                  isTarefa && nota.concluida
                      ? Icons.check_box
                      : isTarefa
                          ? Icons.check_box_outline_blank
                          : nota.tipo.icone,
                  color:
                      nota.concluida ? AppColors.inactive : nota.tipo.cor,
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
                    const SizedBox(height: 2),
                    Text(
                      nota.conteudo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (nota.importante) ...[
                        Icon(Icons.star,
                            size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                      ],
                      if (nota.dataLembrete != null) ...[
                        Icon(
                          Icons.alarm,
                          size: 12,
                          color: nota.isVencido
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _prazoRelativo(nota.dataLembrete!),
                          style: AppTextStyles.caption.copyWith(
                            color: nota.isVencido
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (nota.isVencido) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Vencido',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
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
                onSelected: (value) =>
                    _onMenuSelected(value, nota, provider),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: const [
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
                          const SizedBox(width: 8),
                          Text(nota.concluida
                              ? 'Marcar pendente'
                              : 'Marcar concluída'),
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
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
                          Text(nota.lembreteAtivo
                              ? 'Desativar notificação'
                              : 'Ativar notificação'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'copiar',
                    child: Row(
                      children: const [
                        Icon(Icons.copy_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Copiar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'compartilhar',
                    child: Row(
                      children: const [
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
                        const SizedBox(width: 8),
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
      final fmt =
          DateFormat('dd/MM/yyyy HH:mm').format(nota.dataLembrete!);
      buf.writeln();
      buf.write('📅 ${nota.tipo.nome}: $fmt');
    } else {
      buf.write('\n_${nota.tipo.nome}_');
    }
    return buf.toString();
  }

  Future<void> _copiarNota(Nota nota) async {
    await Clipboard.setData(
        ClipboardData(text: _textoCompartilhamento(nota)));
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Copiado para área de transferência',
      tipo: 'intervalo',
    );
  }

  void _compartilharNota(Nota nota) {
    Share.share(_textoCompartilhamento(nota), subject: nota.titulo);
  }

  // ── Formatos de data ──────────────────────────────────────────────────────
  String _prazoRelativo(DateTime dt) {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final alvo = DateTime(dt.year, dt.month, dt.day);
    final diff = alvo.difference(hoje).inDays;
    final hora =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (diff == 0) return 'Hoje às $hora';
    if (diff == 1) return 'Amanhã às $hora';
    if (diff > 1 && diff <= 7) return 'Em $diff dias às $hora';
    if (diff < 0) {
      final abs = diff.abs();
      return abs == 1 ? 'Ontem' : 'Há $abs dias';
    }
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return '$dia/$mes às $hora';
  }

  // ── Chip de tipo ──────────────────────────────────────────────────────────
  Widget _buildTipoChip(
    String label,
    TipoLembrete? tipo,
    NotaProvider provider, {
    IconData? icon,
    bool isImportantes = false,
  }) {
    final isSelected = isImportantes
        ? _filtroImportantes
        : provider.filtroTipo == tipo && !_filtroImportantes;
    final chipColor =
        isImportantes ? AppColors.warning : (tipo?.cor ?? AppColors.primary);

    return FilterChip(
      avatar: icon != null
          ? Icon(icon,
              size: 14,
              color: isSelected ? chipColor : AppColors.textSecondary)
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        if (isImportantes) {
          setState(() => _filtroImportantes = !_filtroImportantes);
        } else {
          setState(() => _filtroImportantes = false);
          provider.setFiltroTipo(tipo);
        }
      },
      backgroundColor: AppColors.cardBackground,
      selectedColor: chipColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotaProvider>(context);
    final vencidos = provider.totalLembretesVencidos;
    final lembretesLabel = vencidos > 0
        ? 'Lembretes ($vencidos⚠)'
        : 'Lembretes (${provider.lembretes.length})';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Anotações e Lembretes'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list),
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
            tooltip: 'Filtros e ordenação',
            onPressed: () => _abrirMenuFiltro(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Busca ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 8, Dimensions.paddingMD, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                ),
              ),
              onChanged: (v) {
                provider.setSearchQuery(v);
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Cards de resumo ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingMD),
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
                    onTap: () {
                      setState(() => _filtroImportantes = false);
                      provider.setFiltroTipo(TipoLembrete.tarefa);
                    },
                  ),
                ),
                const SizedBox(width: Dimensions.spacingSM),
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
                    onTap: () {
                      setState(() => _filtroImportantes = false);
                      provider.setFiltroTipo(TipoLembrete.lembrete);
                    },
                  ),
                ),
                const SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: _StatCard(
                    label: 'Anotações',
                    value: provider.anotacoes.length.toString(),
                    color: TipoLembrete.anotacao.cor,
                    icon: TipoLembrete.anotacao.icone,
                    onTap: () {
                      setState(() => _filtroImportantes = false);
                      provider.setFiltroTipo(TipoLembrete.anotacao);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Chips de filtro ────────────────────────────────────────────
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD),
              children: [
                _buildTipoChip(
                    'Todos (${provider.totalNotas})', null, provider,
                    icon: Icons.list),
                const SizedBox(width: 8),
                _buildTipoChip(
                    'Anotações (${provider.anotacoes.length})',
                    TipoLembrete.anotacao,
                    provider,
                    icon: TipoLembrete.anotacao.icone),
                const SizedBox(width: 8),
                _buildTipoChip(
                    'Tarefas (${provider.tarefas.length})',
                    TipoLembrete.tarefa,
                    provider,
                    icon: TipoLembrete.tarefa.icone),
                const SizedBox(width: 8),
                _buildTipoChip(lembretesLabel, TipoLembrete.lembrete,
                    provider,
                    icon: TipoLembrete.lembrete.icone),
                const SizedBox(width: 8),
                _buildTipoChip(
                    'Importantes (${provider.importantes.length})',
                    null,
                    provider,
                    icon: Icons.star,
                    isImportantes: true),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Criação rápida de anotação ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 0, Dimensions.paddingMD, 4),
            child: TextField(
              controller: _quickCreateCtrl,
              decoration: InputDecoration(
                hintText: 'Criar anotação rápida...',
                prefixIcon: Icon(Icons.note_add_outlined,
                    color: AppColors.textSecondary, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                ),
                suffixIcon: _quickCreateCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.add_circle,
                            color: AppColors.primary),
                        onPressed: () => _criarRapido(provider),
                        tooltip: 'Criar anotação',
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _criarRapido(provider),
            ),
          ),

          // ── Lista ──────────────────────────────────────────────────────
          Expanded(
            child: provider.notas.isEmpty
                ? RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 280,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_outlined,
                                    size: 64, color: AppColors.inactive),
                                const SizedBox(height: 16),
                                Text(
                                  provider.searchQuery.isNotEmpty
                                      ? 'Nenhum resultado para "${provider.searchQuery}"'
                                      : 'Nenhuma anotação ainda',
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                if (provider.searchQuery.isEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text('Criar:',
                                      style: AppTextStyles.label),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: TipoLembrete.values
                                        .map(
                                          (tipo) => OutlinedButton.icon(
                                            icon: Icon(tipo.icone,
                                                size: 16, color: tipo.cor),
                                            label: Text(tipo.nome,
                                                style: TextStyle(
                                                    color: tipo.cor)),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: tipo.cor),
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    NotaFormScreen(
                                                        tipoInicial: tipo),
                                              ),
                                            ),
                                          ),
                                        )
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
                      padding: const EdgeInsets.fromLTRB(
                          Dimensions.paddingMD,
                          0,
                          Dimensions.paddingMD,
                          Dimensions.paddingMD),
                      children: _buildListItems(provider),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarMenuCriar(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final double? progresso;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.progresso,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSM),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.h3
                    .copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              Text(label,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center),
              if (progresso != null) ...[
                const SizedBox(height: 6),
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
      ),
    );
  }
}
