import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../alocacao/alocacao_screen.dart';
import 'widgets/caixa_grid_item.dart';

/// Tela de mapa visual dos caixas
class MapaCaixasScreen extends StatefulWidget {
  const MapaCaixasScreen({super.key});

  @override
  State<MapaCaixasScreen> createState() => _MapaCaixasScreenState();
}

class _MapaCaixasScreenState extends State<MapaCaixasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final userId = authProvider.user!.id;

    await Future.wait([
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final caixaProvider = Provider.of<CaixaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mapa de Caixas'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legenda
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem('Ocupado', AppColors.statusAtivo),
                      _buildLegendItem('Disponível', AppColors.success),
                      _buildLegendItem('Inativo', AppColors.inactive),
                      _buildLegendItem('Manutenção', AppColors.statusAtencao),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Caixas Rápidos
              if (caixaProvider.caixasRapidos.isNotEmpty) ...[
                const Text('Caixas Rápidos', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingSM),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: Dimensions.spacingSM,
                    mainAxisSpacing: Dimensions.spacingSM,
                  ),
                  itemCount: caixaProvider.caixasRapidos.length,
                  itemBuilder: (context, index) {
                    final caixa = caixaProvider.caixasRapidos[index];
                    final alocacao = alocacaoProvider.alocacoes
                        .where((a) => a.caixaId == caixa.id)
                        .firstOrNull;
                    
                    return CaixaGridItem(
                      caixa: caixa,
                      alocacao: alocacao,
                    );
                  },
                ),
                const SizedBox(height: Dimensions.spacingLG),
              ],

              // Caixas Normais
              if (caixaProvider.caixasNormais.isNotEmpty) ...[
                const Text('Caixas Normais', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingSM),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: Dimensions.spacingSM,
                    mainAxisSpacing: Dimensions.spacingSM,
                  ),
                  itemCount: caixaProvider.caixasNormais.length,
                  itemBuilder: (context, index) {
                    final caixa = caixaProvider.caixasNormais[index];
                    final alocacao = alocacaoProvider.alocacoes
                        .where((a) => a.caixaId == caixa.id)
                        .firstOrNull;
                    
                    return CaixaGridItem(
                      caixa: caixa,
                      alocacao: alocacao,
                    );
                  },
                ),
                const SizedBox(height: Dimensions.spacingLG),
              ],

              // Self Checkouts
              if (caixaProvider.selfCheckouts.isNotEmpty) ...[
                const Text('Self Checkouts', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingSM),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: Dimensions.spacingSM,
                    mainAxisSpacing: Dimensions.spacingSM,
                  ),
                  itemCount: caixaProvider.selfCheckouts.length,
                  itemBuilder: (context, index) {
                    final caixa = caixaProvider.selfCheckouts[index];
                    final alocacao = alocacaoProvider.alocacoes
                        .where((a) => a.caixaId == caixa.id)
                        .firstOrNull;
                    
                    return CaixaGridItem(
                      caixa: caixa,
                      alocacao: alocacao,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlocacaoScreen(
                fiscalId: authProvider.user?.id ?? '',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Alocar'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
