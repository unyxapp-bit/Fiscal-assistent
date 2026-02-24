import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/alocacao_provider.dart';

class ColaboradoresStatusScreen extends StatefulWidget {
  const ColaboradoresStatusScreen({super.key});

  @override
  State<ColaboradoresStatusScreen> createState() =>
      _ColaboradoresStatusScreenState();
}

class _ColaboradoresStatusScreenState extends State<ColaboradoresStatusScreen> {
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
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final caixaProvider = Provider.of<CaixaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Status dos Colaboradores'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          itemCount: colaboradorProvider.colaboradores.length,
          itemBuilder: (context, index) {
            final colaborador = colaboradorProvider.colaboradores[index];
            final alocacao = alocacaoProvider.alocacoes
                .where((a) => a.colaboradorId == colaborador.id)
                .firstOrNull;
            
            final caixa = alocacao != null
                ? caixaProvider.caixas
                    .where((c) => c.id == alocacao.caixaId)
                    .firstOrNull
                : null;

            return Card(
              margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: alocacao != null
                      ? AppColors.statusAtivo
                      : AppColors.inactive,
                  child: Text(
                    colaborador.iniciais,
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(colaborador.nome),
                subtitle: Text(colaborador.departamento.toString().split('.').last),
                trailing: caixa != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusAtivo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.statusAtivo),
                        ),
                        child: Text(
                          caixa.nomeExibicao,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.statusAtivo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Disponível',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
