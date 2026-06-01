import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/operational_widgets.dart';
import '../../providers/entrega_provider.dart';
import 'entrega_form_screen.dart';
import 'entrega_detail_screen.dart';

class EntregasScreen extends StatefulWidget {
  const EntregasScreen({super.key});

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen> {
  final _searchCtrl = TextEditingController();
  String _filtroStatus = 'todos';
  String _filtroCidade = 'todas';
  String _busca = '';
  bool _ordenacaoDescendente = true;

  static const _statusOptions = [
    ('todos', 'Todos'),
    ('separada', 'Separada'),
    ('em_rota', 'Em Rota'),
    ('entregue', 'Entregue'),
    ('cancelada', 'Cancelada'),
  ];

  List<String> _getCidades(List<Entrega> entregas) {
    final cidades = entregas.map((e) => e.cidade).toSet().toList()..sort();
    return cidades;
  }

  List<Entrega> _aplicarFiltros(List<Entrega> entregas) {
    final filtradas = entregas.where((e) {
      final statusOk = _filtroStatus == 'todos' || e.status == _filtroStatus;
      final cidadeOk = _filtroCidade == 'todas' || e.cidade == _filtroCidade;
      final buscaOk = _busca.isEmpty ||
          e.numeroNota.toLowerCase().contains(_busca) ||
          e.clienteNome.toLowerCase().contains(_busca) ||
          e.bairro.toLowerCase().contains(_busca) ||
          e.cidade.toLowerCase().contains(_busca);
      return statusOk && cidadeOk && buscaOk;
    }).toList();
    filtradas.sort((a, b) => _ordenacaoDescendente
        ? b.separadoEm.compareTo(a.separadoEm)
        : a.separadoEm.compareTo(b.separadoEm));
    return filtradas;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntregaProvider>(context);
    final cidades = _getCidades(provider.entregas);
    final entregasFiltradas = _aplicarFiltros(provider.entregas);
    final abertas = provider.totalSeparadas + provider.totalEmRota;
    final canceladas =
        provider.entregas.where((e) => e.status == 'cancelada').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EntregaFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova entrega'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            Provider.of<EntregaProvider>(context, listen: false).load(),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              Dimensions.operationalHPad(constraints.maxWidth),
              14,
              Dimensions.operationalHPad(constraints.maxWidth),
              110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OperationalReferenceHeader(
                  eyebrow: 'Operação',
                  title: 'Entregas',
                  statusLabel: abertas > 0
                      ? _pluralize(
                          abertas,
                          'entrega em andamento',
                          'entregas em andamento',
                        )
                      : 'Entregas em dia',
                  subtitle: '${provider.entregas.length} registro(s) hoje',
                  statusIcon: abertas > 0
                      ? Icons.local_shipping_outlined
                      : Icons.check_circle_rounded,
                  statusColor:
                      abertas > 0 ? AppColors.statusAtencao : AppColors.success,
                  alertCount: abertas,
                  onBack: Navigator.of(context).canPop()
                      ? () => Navigator.pop(context)
                      : null,
                  actions: [
                    IconButton.filledTonal(
                      icon: Icon(
                        _ordenacaoDescendente
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                      ),
                      tooltip: _ordenacaoDescendente
                          ? 'Mais recentes primeiro'
                          : 'Mais antigos primeiro',
                      onPressed: () => setState(
                        () => _ordenacaoDescendente = !_ordenacaoDescendente,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OperationalHeroPanel(
                  title: 'Central de entregas',
                  subtitle:
                      'Acompanhe separação, rota e conclusão das entregas do turno.',
                  icon: Icons.local_shipping_outlined,
                  metrics: [
                    OperationalHeroMetric(
                      value: provider.totalSeparadas.toString(),
                      label: 'Separadas',
                      icon: Icons.inventory_2_outlined,
                    ),
                    OperationalHeroMetric(
                      value: provider.totalEmRota.toString(),
                      label: 'Em rota',
                      icon: Icons.route_rounded,
                    ),
                    OperationalHeroMetric(
                      value: provider.totalEntregues.toString(),
                      label: 'Entregues',
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ReferenceKpiRows(
                  children: [
                    OperationalReferenceKpiCard(
                      icon: Icons.inventory_2_outlined,
                      value: provider.totalSeparadas.toString(),
                      title: 'Separadas',
                      subtitle: 'Aguardando rota',
                      color: AppColors.statusAtencao,
                      onTap: () => setState(() => _filtroStatus = 'separada'),
                    ),
                    OperationalReferenceKpiCard(
                      icon: Icons.route_rounded,
                      value: provider.totalEmRota.toString(),
                      title: 'Em rota',
                      subtitle: 'Saiu para entrega',
                      color: AppColors.primary,
                      onTap: () => setState(() => _filtroStatus = 'em_rota'),
                    ),
                    OperationalReferenceKpiCard(
                      icon: Icons.check_circle_outline,
                      value: provider.totalEntregues.toString(),
                      title: 'Entregues',
                      subtitle: 'Finalizadas',
                      color: AppColors.success,
                      onTap: () => setState(() => _filtroStatus = 'entregue'),
                    ),
                    OperationalReferenceKpiCard(
                      icon: Icons.cancel_outlined,
                      value: canceladas.toString(),
                      title: 'Canceladas',
                      subtitle: 'Sem conclusão',
                      color: AppColors.danger,
                      onTap: () => setState(() => _filtroStatus = 'cancelada'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppSurface(
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OperationalSearchField(
                        controller: _searchCtrl,
                        hintText: 'Buscar nota, cliente, bairro ou cidade',
                        showClear: _busca.isNotEmpty,
                        onClear: () {
                          _searchCtrl.clear();
                          setState(() => _busca = '');
                        },
                        onChanged: (v) =>
                            setState(() => _busca = v.toLowerCase().trim()),
                      ),
                      const SizedBox(height: Dimensions.spacingSM),
                      OperationalFilterChips<String>(
                        selected: _filtroStatus,
                        onSelected: (value) =>
                            setState(() => _filtroStatus = value),
                        options: [
                          for (final opt in _statusOptions)
                            OperationalChipOption<String>(
                              value: opt.$1,
                              label: opt.$2,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                      if (cidades.isNotEmpty) ...[
                        const SizedBox(height: Dimensions.spacingXS),
                        OperationalFilterChips<String>(
                          selected: _filtroCidade,
                          onSelected: (value) =>
                              setState(() => _filtroCidade = value),
                          options: [
                            const OperationalChipOption<String>(
                              value: 'todas',
                              label: 'Todas cidades',
                              icon: Icons.location_city_outlined,
                            ),
                            for (final cidade in cidades)
                              OperationalChipOption<String>(
                                value: cidade,
                                label: cidade,
                                icon: Icons.place_outlined,
                                color: AppColors.statusIntervalo,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ReferenceSectionTitle(
                  title: 'Entregas de hoje',
                  action: '${entregasFiltradas.length} resultado(s)',
                ),
                const SizedBox(height: 12),
                if (entregasFiltradas.isEmpty)
                  OperationalEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: provider.entregas.isEmpty
                        ? 'Nenhuma entrega cadastrada'
                        : 'Nada encontrado',
                    message: provider.entregas.isEmpty
                        ? 'Cadastre a primeira entrega para acompanhar a rota.'
                        : 'Ajuste os filtros ou limpe a busca para ver mais entregas.',
                    actionLabel:
                        provider.entregas.isEmpty ? 'Cadastrar entrega' : null,
                    onAction: provider.entregas.isEmpty
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EntregaFormScreen(),
                              ),
                            )
                        : null,
                  )
                else
                  Column(
                    children: [
                      for (final entrega in entregasFiltradas)
                        Dismissible(
                          key: Key(entrega.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir Entrega'),
                                    content: Text(
                                      'Deseja excluir a entrega de "${entrega.clienteNome}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) =>
                              provider.removerEntrega(entrega.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(
                              bottom: Dimensions.spacingSM,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusMD),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: _EntregaReferenceCard(
                            entrega: entrega,
                            statusColor: _getStatusColor(entrega.status),
                            statusIcon: _getStatusIcon(entrega.status),
                            statusLabel: _getStatusLabel(entrega.status),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EntregaDetailScreen(entrega: entrega),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                if (entregasFiltradas.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const ReferenceSectionTitle(
                    title: 'Últimas movimentações',
                    action: 'Hoje',
                  ),
                  const SizedBox(height: 12),
                  OperationalTimelineCard(
                    entries: entregasFiltradas.take(4).map((entrega) {
                      return OperationalTimelineEntry(
                        time: _formatHour(entrega.separadoEm),
                        icon: _getStatusIcon(entrega.status),
                        title: entrega.clienteNome,
                        subtitle:
                            'NF ${entrega.numeroNota} - ${_getStatusLabel(entrega.status)}',
                        color: _getStatusColor(entrega.status),
                      );
                    }).toList(),
                    emptyTitle: 'Sem movimentações',
                    emptySubtitle: 'As entregas do turno aparecem aqui.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatHour(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _pluralize(int value, String singular, String plural) {
    return '$value ${value == 1 ? singular : plural}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'separada':
        return AppColors.statusAtencao;
      case 'em_rota':
        return AppColors.primary;
      case 'entregue':
        return AppColors.success;
      case 'cancelada':
        return AppColors.danger;
      default:
        return AppColors.inactive;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'separada':
        return Icons.assignment;
      case 'em_rota':
        return Icons.directions_car;
      case 'entregue':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'separada':
        return 'Separada';
      case 'em_rota':
        return 'Em Rota';
      case 'entregue':
        return 'Entregue';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }
}

class _ReferenceKpiRows extends StatelessWidget {
  final List<Widget> children;

  const _ReferenceKpiRows({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final spacing = columns == 4 ? 12.0 : 10.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _EntregaReferenceCard extends StatelessWidget {
  final Entrega entrega;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final VoidCallback onTap;

  const _EntregaReferenceCard({
    required this.entrega,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: AppStyles.softCard(
              context: context,
              tint: statusColor,
              radius: 20,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrega.clienteNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h4.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NF ${entrega.numeroNota} - ${entrega.bairro} - ${entrega.cidade}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((entrega.observacoes ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entrega.observacoes!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusPill(
                      label: statusLabel,
                      color: statusColor,
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: tokens.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
