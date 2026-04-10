import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'caixa_form_screen.dart';
import 'widgets/caixa_card.dart';

/// Tela de lista de caixas
class CaixasListScreen extends StatefulWidget {
  const CaixasListScreen({super.key});

  @override
  State<CaixasListScreen> createState() => _CaixasListScreenState();
}

class _CaixasListScreenState extends State<CaixasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCaixas();
    });
  }

  Future<void> _loadCaixas() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final caixaProvider = Provider.of<CaixaProvider>(context, listen: false);

    if (authProvider.user != null) {
      await caixaProvider.loadCaixas(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caixaProvider = Provider.of<CaixaProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Caixas'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (caixaProvider.caixas.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadCaixas,
            ),
        ],
      ),
      body: caixaProvider.isLoading
          ? const LoadingWidget(message: 'Carregando caixas...')
          : Column(
              children: [
                // Stats
                _buildStatsBar(caixaProvider),

                // Filtro
                _buildFilterBar(caixaProvider),

                // Lista
                Expanded(
                  child: caixaProvider.caixas.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.point_of_sale,
                          title: 'Nenhum caixa',
                          message: 'Você não possui caixas cadastrados',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCaixas,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingMD,
                            ),
                            itemCount: caixaProvider.caixas.length,
                            itemBuilder: (context, index) {
                              final caixa = caixaProvider.caixas[index];
                              return CaixaCard(caixa: caixa);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CaixaFormScreen(),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Novo Caixa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsBar(CaixaProvider provider) {
    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            label: 'Ativos',
            value: provider.totalAtivos.toString(),
            color: AppColors.success,
          ),
          _buildStatItem(
            label: 'Manutenção',
            value: provider.totalEmManutencao.toString(),
            color: Colors.orange,
          ),
          _buildStatItem(
            label: 'Inativos',
            value: provider.totalInativos.toString(),
            color: AppColors.textSecondary,
          ),
          _buildStatItem(
            label: 'Total',
            value: provider.totalCaixas.toString(),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(CaixaProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => provider.toggleFiltroAtivos(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD,
                  vertical: Dimensions.paddingSM,
                ),
                decoration: BoxDecoration(
                  color: provider.mostrarApenasAtivos
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  border: Border.all(
                    color: provider.mostrarApenasAtivos
                        ? AppColors.primary
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: provider.mostrarApenasAtivos
                          ? Colors.white
                          : AppColors.textPrimary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      provider.mostrarApenasAtivos
                          ? 'Apenas Ativos'
                          : 'Ver Todos',
                      style: AppTextStyles.label.copyWith(
                        color: provider.mostrarApenasAtivos
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: provider.mostrarApenasAtivos
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
