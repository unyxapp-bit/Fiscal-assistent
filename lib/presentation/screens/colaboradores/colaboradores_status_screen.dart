import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
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

class _ColaboradoresStatusScreenState
    extends State<ColaboradoresStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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

    final todos = colaboradorProvider.colaboradores
        .where((c) => c.ativo)
        .toList();

    final disponiveis = todos
        .where((c) => alocacaoProvider.getAlocacaoColaborador(c.id) == null)
        .toList();

    final emCaixa = todos
        .where((c) => alocacaoProvider.getAlocacaoColaborador(c.id) != null)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Status dos Colaboradores'),
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 6),
                    Text('Disponíveis (${disponiveis.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.point_of_sale, size: 18),
                    const SizedBox(width: 6),
                    Text('Em Caixa (${emCaixa.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── ABA 1: DISPONÍVEIS ─────────────────────────────────────────
            RefreshIndicator(
              onRefresh: _loadData,
              child: disponiveis.isEmpty
                  ? const _EmptyState(
                      icon: Icons.people_outline,
                      mensagem: 'Nenhum colaborador disponível',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      itemCount: disponiveis.length,
                      itemBuilder: (context, index) {
                        return _CardDisponivel(
                            colaborador: disponiveis[index]);
                      },
                    ),
            ),

            // ── ABA 2: EM CAIXA ────────────────────────────────────────────
            RefreshIndicator(
              onRefresh: _loadData,
              child: emCaixa.isEmpty
                  ? const _EmptyState(
                      icon: Icons.point_of_sale,
                      mensagem: 'Nenhum colaborador alocado',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      itemCount: emCaixa.length,
                      itemBuilder: (context, index) {
                        final colaborador = emCaixa[index];
                        final alocacao = alocacaoProvider
                            .getAlocacaoColaborador(colaborador.id);
                        final caixa = alocacao != null
                            ? caixaProvider.caixas
                                .where((c) => c.id == alocacao.caixaId)
                                .firstOrNull
                            : null;
                        return _CardEmCaixa(
                          colaborador: colaborador,
                          nomeCaixa: caixa?.nomeExibicao,
                          localizacao: caixa?.localizacao,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _CardDisponivel extends StatelessWidget {
  final Colaborador colaborador;

  const _CardDisponivel({required this.colaborador});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          child: Text(
            colaborador.iniciais,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(colaborador.nome, style: AppTextStyles.h4),
        subtitle: Text(
          colaborador.departamento.nome,
          style: AppTextStyles.caption,
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Disponível',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardEmCaixa extends StatelessWidget {
  final Colaborador colaborador;
  final String? nomeCaixa;
  final String? localizacao;

  const _CardEmCaixa({
    required this.colaborador,
    this.nomeCaixa,
    this.localizacao,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.statusAtivo.withValues(alpha: 0.15),
          child: Text(
            colaborador.iniciais,
            style: const TextStyle(
              color: AppColors.statusAtivo,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(colaborador.nome, style: AppTextStyles.h4),
        subtitle: Text(
          colaborador.departamento.nome,
          style: AppTextStyles.caption,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusAtivo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.statusAtivo),
              ),
              child: Text(
                nomeCaixa ?? 'Caixa',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.statusAtivo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (localizacao != null) ...[
              const SizedBox(height: 3),
              Text(
                localizacao!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String mensagem;

  const _EmptyState({required this.icon, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.inactive),
          const SizedBox(height: 12),
          Text(
            mensagem,
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
