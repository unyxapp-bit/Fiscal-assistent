import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Entregas'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _ordenacaoDescendente ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _ordenacaoDescendente
                ? 'Mais recentes primeiro'
                : 'Mais antigos primeiro',
            onPressed: () =>
                setState(() => _ordenacaoDescendente = !_ordenacaoDescendente),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EntregaFormScreen(),
                ),
              );
            },
            tooltip: 'Nova Entrega',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            Provider.of<EntregaProvider>(context, listen: false).load(),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.operationalHPad(constraints.maxWidth),
              vertical: Dimensions.paddingMD,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OperationalMetricGrid(
                  minTileWidth: 176,
                  metrics: [
                    OperationalMetricData(
                      label: 'Separadas',
                      value: provider.totalSeparadas.toString(),
                      color: AppColors.statusAtencao,
                      icon: Icons.inventory_2_outlined,
                    ),
                    OperationalMetricData(
                      label: 'Em rota',
                      value: provider.totalEmRota.toString(),
                      color: AppColors.primary,
                      icon: Icons.route_rounded,
                    ),
                    OperationalMetricData(
                      label: 'Entregues',
                      value: provider.totalEntregues.toString(),
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),

                const SizedBox(height: Dimensions.spacingMD),

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

                const SizedBox(height: Dimensions.spacingLG),

                // Lista de entregas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Entregas de Hoje', style: AppTextStyles.h3),
                    Text(
                      '${entregasFiltradas.length} resultado(s)',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spacingSM),

                if (entregasFiltradas.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppColors.inactive,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.entregas.isEmpty
                                ? 'Nenhuma entrega cadastrada'
                                : 'Nenhuma entrega com os filtros selecionados',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (provider.entregas.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EntregaFormScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Cadastrar Entrega'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entregasFiltradas.length,
                    itemBuilder: (context, index) {
                      final entrega = entregasFiltradas[index];
                      return Dismissible(
                        key: Key(entrega.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Excluir Entrega'),
                                  content: Text(
                                      'Deseja excluir a entrega de "${entrega.clienteNome}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
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
                        onDismissed: (_) => provider.removerEntrega(entrega.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(
                              bottom: Dimensions.spacingSM),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius:
                                BorderRadius.circular(Dimensions.borderRadius),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 28),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(
                              bottom: Dimensions.spacingSM),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(entrega.status),
                              child: Icon(
                                _getStatusIcon(entrega.status),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(entrega.clienteNome),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('NF: ${entrega.numeroNota}'),
                                Text('${entrega.bairro} - ${entrega.cidade}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(entrega.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusLabel(entrega.status),
                                style: AppTextStyles.caption.copyWith(
                                  color: _getStatusColor(entrega.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EntregaDetailScreen(entrega: entrega),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
