import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../../domain/entities/registro_ponto.dart';
import '../../../data/datasources/remote/supabase_client.dart';
import '../../../data/models/registro_ponto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/ocorrencia_provider.dart';
import '../../../core/utils/app_notif.dart';

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CafeProvider>(
      builder: (context, provider, _) {
        final colaboradorProvider =
            Provider.of<ColaboradorProvider>(context, listen: false);
        final escalaProvider =
            Provider.of<EscalaProvider>(context, listen: false);

        // Turnos de hoje válidos para intervalo (sem folga/feriado e com horários)
        final turnosDisponiveis = escalaProvider.turnosHoje
            .where((t) =>
                !t.folga &&
                !t.feriado &&
                (t.intervalo?.isNotEmpty == true) &&
                (t.retorno?.isNotEmpty == true))
            .toList();
        final turnosById = {
          for (final t in turnosDisponiveis) t.colaboradorId: t
        };
        final idsEscalaHoje = turnosById.keys.toSet();

        // IDs em pausa ativa
        final emPausaAtiva =
            provider.pausasAtivas.map((p) => p.colaboradorId).toSet();

        // IDs que já fizeram café hoje
        final jaFizeramCafe = provider.pausasFinalizadas
            .where((p) => p.isCafe)
            .map((p) => p.colaboradorId)
            .toSet();

        final totalDisponiveis = colaboradorProvider.colaboradores
            .where((c) =>
                idsEscalaHoje.contains(c.id) &&
                !emPausaAtiva.contains(c.id) &&
                !jaFizeramCafe.contains(c.id))
            .length;

        final temAlertas = provider.totalEmAtraso > 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Café / Intervalos'),
            backgroundColor: AppColors.background,
            elevation: 0,
            actions: [
              if (provider.pausasFinalizadas.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _confirmarLimpar(context, provider),
                  icon: const Icon(Icons.cleaning_services, size: 16),
                  label: const Text('Limpar'),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: const Icon(Icons.people_outline, size: 18),
                  text: 'Disponíveis ($totalDisponiveis)',
                ),
                Tab(
                  icon: const Icon(Icons.coffee, size: 18),
                  text: 'Em Intervalo (${provider.pausasAtivas.length})',
                ),
                Tab(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  text: 'Já fez (${provider.pausasFinalizadas.length})',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Banner de alerta — visível em qualquer aba; clique vai para "Em Intervalo"
              if (temAlertas)
                GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(
                        Dimensions.paddingMD, 12, Dimensions.paddingMD, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: AppStyles.softTile(
                      tint: AppColors.danger,
                      radius: Dimensions.borderRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${provider.totalEmAtraso} colaborador(es) excederam o tempo de intervalo!',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppColors.danger),
                      ],
                    ),
                  ),
                ),

              // Conteúdo das abas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TabDisponiveis(
                      provider: provider,
                      idsEscalaHoje: idsEscalaHoje,
                      turnosById: turnosById,
                    ),
                    _TabEmIntervalo(provider: provider),
                    _TabHistorico(provider: provider),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _mostrarSeletorPausa(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Iniciar Café'),
            backgroundColor: AppColors.statusCafe,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  void _confirmarLimpar(BuildContext context, CafeProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text(
            'Deseja remover todas as pausas finalizadas do histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.limparHistorico();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Limpar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSeletorPausa(BuildContext context, CafeProvider cafeProvider) {
    final escalaProvider = Provider.of<EscalaProvider>(context, listen: false);
    final turnosDisponiveis = escalaProvider.turnosHoje
        .where((t) =>
            !t.folga &&
            !t.feriado &&
            (t.intervalo?.isNotEmpty == true) &&
            (t.retorno?.isNotEmpty == true))
        .toList();
    final turnosById = {for (final t in turnosDisponiveis) t.colaboradorId: t};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => _SeletorPausaSheet(
        cafeProvider: cafeProvider,
        turnosById: turnosById,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aba 1: Disponíveis para Pausa
// ---------------------------------------------------------------------------
class _TabDisponiveis extends StatelessWidget {
  final CafeProvider provider;
  final Set<String> idsEscalaHoje;
  final Map<String, TurnoLocal> turnosById;

  const _TabDisponiveis({
    required this.provider,
    required this.idsEscalaHoje,
    required this.turnosById,
  });

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);

    // IDs em pausa ativa
    final emPausaAtiva =
        provider.pausasAtivas.map((p) => p.colaboradorId).toSet();

    // IDs que já fizeram intervalo e café hoje
    final jaFizeramIntervalo = provider.pausasFinalizadas
        .where((p) => p.isIntervalo)
        .map((p) => p.colaboradorId)
        .toSet();
    // Inclui os marcados manualmente em memória (mesmo sem alocação ativa).
    final intervalosMarcadosManualmente = colaboradorProvider.colaboradores
        .where((c) => alocacaoProvider.isIntervaloMarcado(c.id))
        .map((c) => c.id)
        .toSet();
    jaFizeramIntervalo.addAll(intervalosMarcadosManualmente);
    final jaFizeramCafe = provider.pausasFinalizadas
        .where((p) => p.isCafe)
        .map((p) => p.colaboradorId)
        .toSet();

    // Disponíveis = na escala (com intervalo) + não em pausa ativa + não fez café ainda
    final disponiveis = colaboradorProvider.colaboradores
        .where((c) =>
            idsEscalaHoje.contains(c.id) &&
            !emPausaAtiva.contains(c.id) &&
            !jaFizeramCafe.contains(c.id))
        .toList();
    disponiveis.sort((a, b) {
      int? toMin(String? hhmm) {
        if (hhmm == null || hhmm.isEmpty) return null;
        final parts = hhmm.split(':');
        if (parts.length < 2) return null;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return h * 60 + m;
      }

      final aMin = toMin(turnosById[a.id]?.intervalo) ?? 9999;
      final bMin = toMin(turnosById[b.id]?.intervalo) ?? 9999;
      final comp = aMin.compareTo(bMin);
      if (comp != 0) return comp;
      return a.nome.compareTo(b.nome);
    });

    if (disponiveis.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.success.withValues(alpha: 0.55)),
              const SizedBox(height: 16),
              Text(
                'Nenhum colaborador disponível para pausa agora.',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Verifique escala, pausas ativas e cafés já realizados.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= Dimensions.breakpointTablet;
        Widget itemBuilder(BuildContext _, int i) {
          final c = disponiveis[i];
          final turno = turnosById[c.id];
          final paraIntervalo = !jaFizeramIntervalo.contains(c.id);
          // Quem já fez intervalo mas não café → só café (10 min)
          final soDez = !paraIntervalo;
          final intervaloLabel = (turno?.intervalo?.isNotEmpty == true &&
                  turno?.retorno?.isNotEmpty == true)
              ? '${turno!.intervalo} - ${turno.retorno}'
              : 'Intervalo não definido';

          return Card(
            margin: isTablet
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: Dimensions.spacingSM),
            child: ListTile(
              onTap: soDez
                  ? () => _abrirSeletorRapido(context, c, soDez)
                  : () => _abrirDetalheIntervalo(context, c),
              leading: CircleAvatar(
                backgroundColor: soDez
                    ? AppColors.statusCafe.withValues(alpha: 0.10)
                    : AppColors.backgroundSection,
                child: Icon(
                  soDez ? Icons.coffee : Icons.restaurant,
                  color: soDez ? AppColors.statusCafe : AppColors.textSecondary,
                  size: 18,
                ),
              ),
              title: Text(c.nome, style: AppTextStyles.body),
              subtitle: Text(
                soDez
                    ? 'Disponível para café (10 min)'
                    : 'Intervalo previsto: $intervaloLabel',
                style: AppTextStyles.caption.copyWith(
                  color: soDez ? AppColors.statusCafe : AppColors.textSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: soDez
                        ? () => _abrirSeletorRapido(context, c, soDez)
                        : () => _abrirDetalheIntervalo(context, c),
                    icon:
                        Icon(soDez ? Icons.coffee : Icons.restaurant, size: 16),
                    label: Text(soDez ? 'Café' : 'Pausa'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.statusCafe,
                    ),
                  ),
                  if (!soDez)
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        }

        if (isTablet) {
          return GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.hPad(constraints.maxWidth),
              vertical: Dimensions.paddingMD,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: Dimensions.spacingSM,
              mainAxisSpacing: Dimensions.spacingSM,
              childAspectRatio: 3.2,
            ),
            itemCount: disponiveis.length,
            itemBuilder: itemBuilder,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          itemCount: disponiveis.length,
          itemBuilder: itemBuilder,
        );
      },
    );
  }

  void _abrirSeletorRapido(
      BuildContext context, Colaborador colaborador, bool soDez) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _SeletorRapidoSheet(
        colaborador: colaborador,
        cafeProvider: provider,
        forcaDuracaoDez: soDez,
      ),
    );
  }

  void _abrirDetalheIntervalo(BuildContext context, Colaborador colaborador) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _ColaboradorIntervaloSheet(
        colaborador: colaborador,
        cafeProvider: provider,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aba 2: Em Intervalo agora
// ---------------------------------------------------------------------------
class _TabEmIntervalo extends StatelessWidget {
  final CafeProvider provider;

  const _TabEmIntervalo({required this.provider});

  Future<_RetornoIntervaloEscolha?> _selecionarRetornoIntervalo(
    BuildContext context,
    PausaCafe pausa,
    AlocacaoProvider alocacaoProvider,
    CaixaProvider caixaProvider,
  ) async {
    final caixasAtivos = caixaProvider.caixas
        .where((c) => c.ativo && !c.emManutencao)
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));

    final caixasLivres = caixasAtivos
        .where((c) => alocacaoProvider.getAlocacaoCaixa(c.id) == null)
        .toList();
    if (caixasLivres.isEmpty) {
      if (context.mounted) {
        AppNotif.show(
          context,
          titulo: 'Sem caixa disponivel',
          mensagem:
              'Nao ha caixa livre para o retorno pos-intervalo neste momento.',
          tipo: 'alerta',
          cor: AppColors.warning,
        );
      }
      return null;
    }

    String? caixaSelecionadoId = caixasLivres
        .where((c) => c.id != pausa.caixaId)
        .map((c) => c.id)
        .firstOrNull;
    caixaSelecionadoId ??= caixasLivres.first.id;
    bool permitirMesmoCaixa = false;
    final justificativaCtrl = TextEditingController();

    final resultado = await showDialog<_RetornoIntervaloEscolha>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final mesmoCaixaSelecionado = pausa.caixaId != null &&
                pausa.caixaId!.isNotEmpty &&
                caixaSelecionadoId == pausa.caixaId;
            final precisaJustificativa =
                mesmoCaixaSelecionado && permitirMesmoCaixa;
            final podeConfirmar = caixaSelecionadoId != null &&
                (!precisaJustificativa ||
                    justificativaCtrl.text.trim().isNotEmpty);

            return AlertDialog(
              title: const Text('Retorno do intervalo'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: RadioGroup<String>(
                    groupValue: caixaSelecionadoId,
                    onChanged: (v) =>
                        setStateDialog(() => caixaSelecionadoId = v),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecione o caixa de retorno. Regra padrao: caixa diferente.',
                        ),
                        const SizedBox(height: 12),
                        ...caixasAtivos.map((caixa) {
                          final ocupado =
                              alocacaoProvider.getAlocacaoCaixa(caixa.id) !=
                                  null;
                          Widget tile = RadioListTile<String>(
                            value: caixa.id,
                            title: Text(caixa.nomeExibicao),
                            subtitle:
                                Text(ocupado ? 'Ocupado agora' : 'Disponivel'),
                            dense: true,
                          );
                          if (ocupado) {
                            tile = Opacity(
                              opacity: 0.5,
                              child: IgnorePointer(child: tile),
                            );
                          }
                          return tile;
                        }),
                        if (mesmoCaixaSelecionado) ...[
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: permitirMesmoCaixa,
                            onChanged: (v) => setStateDialog(
                              () => permitirMesmoCaixa = v ?? false,
                            ),
                            title: const Text('Permitir mesmo caixa (excecao)'),
                            subtitle: const Text(
                              'Use somente quando necessario na operacao.',
                            ),
                          ),
                          if (permitirMesmoCaixa) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: justificativaCtrl,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Justificativa da excecao *',
                                hintText:
                                    'Ex: falta de operador para cobertura',
                              ),
                              onChanged: (_) => setStateDialog(() {}),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: !podeConfirmar
                      ? null
                      : () => Navigator.pop(
                            ctx,
                            _RetornoIntervaloEscolha(
                              caixaDestinoId: caixaSelecionadoId!,
                              permitirMesmoCaixa: permitirMesmoCaixa,
                              justificativaMesmoCaixa:
                                  justificativaCtrl.text.trim().isEmpty
                                      ? null
                                      : justificativaCtrl.text.trim(),
                            ),
                          ),
                  child: const Text('Confirmar retorno'),
                ),
              ],
            );
          },
        );
      },
    );

    justificativaCtrl.dispose();
    return resultado;
  }

  Future<void> _finalizarComRegras(
    BuildContext context,
    PausaCafe pausa,
    EventoTurnoProvider eventoProvider,
    AlocacaoProvider alocacaoProvider,
    CaixaProvider caixaProvider,
    String fiscalId,
  ) async {
    if (pausa.isCafe) {
      final erro = await provider.finalizarPausaComRegra(
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        fiscalId: fiscalId,
      );

      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.cafeEncerrado,
        colaboradorNome: pausa.colaboradorNome,
        detalhe: '${pausa.duracaoMinutos} min',
      );

      if (!context.mounted) return;
      if (erro == null) {
        final caixa = caixaProvider.caixas
            .where((c) => c.id == pausa.caixaId)
            .firstOrNull;
        AppNotif.show(
          context,
          titulo: 'Retorno do cafe',
          mensagem:
              '${pausa.colaboradorNome} voltou ao ${caixa?.nomeExibicao ?? 'caixa'}',
          tipo: 'saida',
          cor: AppColors.success,
        );
      } else {
        AppNotif.show(
          context,
          titulo: 'Retorno do cafe',
          mensagem: erro,
          tipo: 'alerta',
          cor: AppColors.warning,
        );
      }
      return;
    }

    final escolha = await _selecionarRetornoIntervalo(
      context,
      pausa,
      alocacaoProvider,
      caixaProvider,
    );
    if (escolha == null) return;

    final erro = await provider.finalizarPausaComRegra(
      pausa: pausa,
      alocacaoProvider: alocacaoProvider,
      fiscalId: fiscalId,
      caixaDestinoIntervaloId: escolha.caixaDestinoId,
      permitirMesmoCaixaNoIntervalo: escolha.permitirMesmoCaixa,
      justificativaMesmoCaixa: escolha.justificativaMesmoCaixa,
    );

    eventoProvider.registrar(
      fiscalId: fiscalId,
      tipo: TipoEvento.intervaloEncerrado,
      colaboradorNome: pausa.colaboradorNome,
      detalhe: '${pausa.duracaoMinutos} min',
    );

    if (!context.mounted) return;
    if (erro == null) {
      final caixaDestino = caixaProvider.caixas
          .where((c) => c.id == escolha.caixaDestinoId)
          .firstOrNull;
      final usouExcecao = pausa.caixaId == escolha.caixaDestinoId;
      AppNotif.show(
        context,
        titulo: 'Retorno do intervalo',
        mensagem:
            '${pausa.colaboradorNome} realocado(a) para ${caixaDestino?.nomeExibicao ?? 'caixa'}'
            '${usouExcecao ? ' (excecao registrada)' : ''}.',
        tipo: 'saida',
        cor: AppColors.success,
      );
    } else {
      AppNotif.show(
        context,
        titulo: 'Intervalo finalizado',
        mensagem: erro,
        tipo: 'alerta',
        cor: AppColors.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (provider.pausasAtivas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.coffee_outlined,
                  size: 64, color: AppColors.inactive.withValues(alpha: 0.55)),
              const SizedBox(height: 16),
              Text(
                'Nenhum colaborador em intervalo no momento',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final eventoProvider =
            Provider.of<EventoTurnoProvider>(context, listen: false);
        final alocacaoProvider =
            Provider.of<AlocacaoProvider>(context, listen: false);
        final caixaProvider =
            Provider.of<CaixaProvider>(context, listen: false);
        final fiscalId =
            Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

        final isTablet = constraints.maxWidth >= Dimensions.breakpointTablet;
        if (isTablet) {
          return GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.hPad(constraints.maxWidth),
              vertical: Dimensions.paddingMD,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: Dimensions.spacingSM,
              mainAxisSpacing: Dimensions.spacingSM,
              childAspectRatio: 1.6,
            ),
            itemCount: provider.pausasAtivas.length,
            itemBuilder: (_, i) {
              final pausa = provider.pausasAtivas[i];
              return _PausaAtivaCard(
                pausa: pausa,
                onFinalizar: () => _finalizarComRegras(
                  context,
                  pausa,
                  eventoProvider,
                  alocacaoProvider,
                  caixaProvider,
                  fiscalId,
                ),
              );
            },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          itemCount: provider.pausasAtivas.length,
          itemBuilder: (_, i) {
            final pausa = provider.pausasAtivas[i];
            return _PausaAtivaCard(
              pausa: pausa,
              onFinalizar: () => _finalizarComRegras(
                context,
                pausa,
                eventoProvider,
                alocacaoProvider,
                caixaProvider,
                fiscalId,
              ),
            );
          },
        );
      },
    );
  }
}

class _RetornoIntervaloEscolha {
  final String caixaDestinoId;
  final bool permitirMesmoCaixa;
  final String? justificativaMesmoCaixa;

  const _RetornoIntervaloEscolha({
    required this.caixaDestinoId,
    required this.permitirMesmoCaixa,
    this.justificativaMesmoCaixa,
  });
}

// ---------------------------------------------------------------------------
// Aba 3: Histórico (já fez pausa)
// ---------------------------------------------------------------------------
class _TabHistorico extends StatelessWidget {
  final CafeProvider provider;

  const _TabHistorico({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.pausasFinalizadas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history,
                  size: 64, color: AppColors.inactive.withValues(alpha: 0.55)),
              const SizedBox(height: 16),
              Text(
                'Nenhuma pausa finalizada hoje',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final finalizadas = provider.pausasFinalizadas.reversed.toList();

    return LayoutBuilder(
      builder: (context, constraints) => ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.hPad(constraints.maxWidth),
          vertical: Dimensions.paddingMD,
        ),
        itemCount: finalizadas.length,
        itemBuilder: (_, i) {
          final pausa = finalizadas[i];
          return _PausaHistoricoCard(
            pausa: pausa,
            onRemover: () => provider.removerRegistro(pausa.id),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card: pausa ativa com countdown e progress bar
// ---------------------------------------------------------------------------
class _PausaAtivaCard extends StatelessWidget {
  final PausaCafe pausa;
  final VoidCallback onFinalizar;

  const _PausaAtivaCard({required this.pausa, required this.onFinalizar});

  @override
  Widget build(BuildContext context) {
    final emAtraso = pausa.emAtraso;
    final cor = emAtraso ? AppColors.danger : AppColors.statusCafe;
    final progresso = emAtraso
        ? 1.0
        : pausa.tempoDecorrido.inSeconds /
            Duration(minutes: pausa.duracaoMinutos).inSeconds;

    final retornoPrevisto =
        pausa.iniciadoEm.add(Duration(minutes: pausa.duracaoMinutos));

    final restante = pausa.tempoRestante;
    final label = emAtraso
        ? '+${pausa.minutosExcedidos} min em atraso'
        : '${restante.inMinutes.toString().padLeft(2, "0")}:${(restante.inSeconds % 60).toString().padLeft(2, "0")} restantes';

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      decoration: AppStyles.softCard(
        tint: cor,
        radius: Dimensions.borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.10),
                  child: Icon(
                    emAtraso ? Icons.timer_off : Icons.coffee,
                    color: cor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pausa.colaboradorNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            'Saiu às ${DateFormat("HH:mm").format(pausa.iniciadoEm)}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            '·',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            'Retorna ${DateFormat("HH:mm").format(retornoPrevisto)}',
                            style: AppTextStyles.caption.copyWith(
                              color: emAtraso
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onFinalizar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: AppTextStyles.caption,
                ),
                child: const Text('Finalizar'),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresso.clamp(0.0, 1.0),
                backgroundColor: cor.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(cor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: cor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card: histórico de pausa finalizada
// ---------------------------------------------------------------------------
class _PausaHistoricoCard extends StatelessWidget {
  final PausaCafe pausa;
  final VoidCallback onRemover;

  const _PausaHistoricoCard({required this.pausa, required this.onRemover});

  @override
  Widget build(BuildContext context) {
    final duracao = pausa.tempoDecorrido;
    final foiEmAtraso = pausa.minutosExcedidos > 0 ||
        (pausa.finalizadoEm != null &&
            pausa.tempoDecorrido.inMinutes > pausa.duracaoMinutos);
    final cor = foiEmAtraso ? AppColors.danger : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      decoration: AppStyles.softCard(
        tint: foiEmAtraso ? AppColors.danger : AppColors.success,
        radius: Dimensions.borderRadius,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.10),
          child: Icon(Icons.coffee_outlined, color: cor),
        ),
        title: Text(pausa.colaboradorNome, style: AppTextStyles.body),
        subtitle: Text(
          '${DateFormat("HH:mm").format(pausa.iniciadoEm)} → ${DateFormat("HH:mm").format(pausa.finalizadoEm!)} · ${duracao.inMinutes} min',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (foiEmAtraso)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Atrasou',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.danger, fontSize: 10),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemover,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seletor rápido: escolhe só a duração para um colaborador pré-definido
// ---------------------------------------------------------------------------
class _SeletorRapidoSheet extends StatelessWidget {
  final Colaborador colaborador;
  final CafeProvider cafeProvider;

  /// Quando true, só exibe a opção de 10 min (café pós-intervalo)
  final bool forcaDuracaoDez;

  const _SeletorRapidoSheet({
    required this.colaborador,
    required this.cafeProvider,
    this.forcaDuracaoDez = false,
  });

  @override
  Widget build(BuildContext context) {
    final duracoes = [10];
    final alocacaoProvider = Provider.of<AlocacaoProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Iniciar café para',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(colaborador.nome, style: AppTextStyles.h3),
          Text(
            colaborador.departamento.nome,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          if (forcaDuracaoDez) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusCafe.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Já fez o intervalo — disponível somente para café (10 min)',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.statusCafe),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Duração:', style: AppTextStyles.label),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: duracoes.map((d) {
              final isCafe = d <= 15;
              return ElevatedButton.icon(
                onPressed: () async {
                  final eventoProvider =
                      Provider.of<EventoTurnoProvider>(context, listen: false);
                  final fiscalId =
                      Provider.of<AuthProvider>(context, listen: false)
                              .user
                              ?.id ??
                          '';
                  final alocacaoAtiva = alocacaoProvider.getAlocacaoColaborador(
                    colaborador.id,
                  );
                  final caixaOrigemId = alocacaoAtiva?.caixaId;
                  if (alocacaoAtiva != null) {
                    await alocacaoProvider.liberarAlocacao(
                      alocacaoAtiva.id,
                      isCafe ? 'cafe' : 'intervalo',
                    );
                  }
                  cafeProvider.iniciarPausa(
                    colaboradorId: colaborador.id,
                    colaboradorNome: colaborador.nome,
                    duracaoMinutos: d,
                    caixaId: caixaOrigemId,
                  );
                  eventoProvider.registrar(
                    fiscalId: fiscalId,
                    tipo: isCafe
                        ? TipoEvento.cafeIniciado
                        : TipoEvento.intervaloIniciado,
                    colaboradorNome: colaborador.nome,
                    detalhe: '$d min',
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                icon: Icon(
                  isCafe ? Icons.coffee : Icons.restaurant,
                  size: 16,
                ),
                label: Text('$d min'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusCafe,
                  foregroundColor: Colors.white,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet de detalhe: envia colaborador para intervalo com base no RegistroPonto
// ---------------------------------------------------------------------------
class _ColaboradorIntervaloSheet extends StatefulWidget {
  final Colaborador colaborador;
  final CafeProvider cafeProvider;

  const _ColaboradorIntervaloSheet({
    required this.colaborador,
    required this.cafeProvider,
  });

  @override
  State<_ColaboradorIntervaloSheet> createState() =>
      _ColaboradorIntervaloSheetState();
}

class _ColaboradorIntervaloSheetState
    extends State<_ColaboradorIntervaloSheet> {
  RegistroPonto? _ponto;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPonto();
  }

  Future<void> _carregarPonto() async {
    try {
      final hoje = DateTime.now();
      final hojeStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

      final rows = await SupabaseClientManager.client
          .from('registros_ponto')
          .select()
          .eq('colaborador_id', widget.colaborador.id)
          .eq('data', hojeStr)
          .limit(1);

      if (mounted) {
        setState(() {
          _ponto = (rows as List).isNotEmpty
              ? RegistroPontoModel.fromJson(rows.first)
              : null;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  DateTime? _parseHorario(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final hoje = DateTime.now();
    return DateTime(hoje.year, hoje.month, hoje.day, h, m);
  }

  Future<int?> _escolherDuracaoIntervaloSemEscala() {
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duracao do intervalo'),
        content: const Text(
          'Sem horario cadastrado no ponto de hoje. Qual duracao do intervalo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 60),
            child: const Text('60 min'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 120),
            child: const Text('120 min'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarParaIntervalo() async {
    final saidaDT = _parseHorario(_ponto?.intervaloSaida);
    final retornoDT = _parseHorario(_ponto?.intervaloRetorno);
    final now = DateTime.now();
    DateTime iniciadoEm;
    int duracaoMinutos;

    if (saidaDT != null && retornoDT != null) {
      final diffAgendada = retornoDT.difference(saidaDT);
      final duracaoAgendada =
          diffAgendada.inMinutes > 0 ? diffAgendada.inMinutes : 60;
      if (now.isAfter(saidaDT)) {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: saidaDT.hour, minute: saidaDT.minute),
          helpText: 'Horario que ${widget.colaborador.nome} saiu',
        );
        if (picked == null || !mounted) return;
        iniciadoEm =
            DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        duracaoMinutos = duracaoAgendada;
      } else {
        duracaoMinutos = duracaoAgendada;
        iniciadoEm = now;
      }
    } else {
      final duracaoEscolhida = await _escolherDuracaoIntervaloSemEscala();
      if (duracaoEscolhida == null) return;
      iniciadoEm = now;
      duracaoMinutos = duracaoEscolhida;
    }

    if (!mounted) return;
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    final alocacaoAtiva =
        alocacaoProvider.getAlocacaoColaborador(widget.colaborador.id);
    final caixaOrigemId = alocacaoAtiva?.caixaId;
    if (alocacaoAtiva != null) {
      await alocacaoProvider.liberarAlocacao(alocacaoAtiva.id, 'intervalo');
    }

    widget.cafeProvider.iniciarPausa(
      colaboradorId: widget.colaborador.id,
      colaboradorNome: widget.colaborador.nome,
      duracaoMinutos: duracaoMinutos,
      caixaId: caixaOrigemId,
      iniciadoEm: iniciadoEm,
    );
    eventoProvider.registrar(
      fiscalId: fiscalId,
      tipo: TipoEvento.intervaloIniciado,
      colaboradorNome: widget.colaborador.nome,
      detalhe: '$duracaoMinutos min',
    );

    if (mounted) Navigator.pop(context);
  }

  Future<bool?> _perguntarSeFezTempoCompleto() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Intervalo já realizado?'),
        content: const Text(
          'Esse colaborador fez o tempo completo do intervalo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  Future<String?> _perguntarMotivoIncompleto() async {
    final controller = TextEditingController();
    String? resultado;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final podeSalvar = controller.text.trim().isNotEmpty;
            return AlertDialog(
              title: const Text('Motivo do intervalo incompleto'),
              content: TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Descreva o motivo...',
                ),
                onChanged: (_) => setStateDialog(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: !podeSalvar
                      ? null
                      : () {
                          resultado = controller.text.trim();
                          Navigator.pop(ctx);
                        },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return resultado;
  }

  Future<void> _marcarIntervaloJaFeito() async {
    final fezCompleto = await _perguntarSeFezTempoCompleto();
    if (!mounted || fezCompleto == null) return;

    String? motivoIncompleto;
    if (!fezCompleto) {
      motivoIncompleto = await _perguntarMotivoIncompleto();
      if (!mounted || motivoIncompleto == null) return;
    }

    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final caixaProvider = Provider.of<CaixaProvider>(context, listen: false);
    final ocorrenciaProvider =
        Provider.of<OcorrenciaProvider>(context, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    final alocacao = alocacaoProvider.getAlocacaoColaborador(
      widget.colaborador.id,
    );
    final caixa = caixaProvider.caixas
        .where((c) => c.id == alocacao?.caixaId)
        .firstOrNull;

    if (!fezCompleto) {
      ocorrenciaProvider.registrar(
        tipo: 'Intervalo incompleto',
        caixaId: alocacao?.caixaId,
        caixaNome: caixa?.nomeExibicao,
        colaboradorId: widget.colaborador.id,
        colaboradorNome: widget.colaborador.nome,
        descricao: motivoIncompleto!,
        gravidade: GravidadeOcorrencia.media,
      );
      if (eventoProvider.turnoAtivo && fiscalId.isNotEmpty) {
        eventoProvider.registrar(
          fiscalId: fiscalId,
          tipo: TipoEvento.ocorrenciaRegistrada,
          colaboradorNome: widget.colaborador.nome,
          caixaNome: caixa?.nomeExibicao,
          detalhe: 'Intervalo incompleto — Média',
        );
      }
    }

    await alocacaoProvider.marcarIntervaloFeito(widget.colaborador.id);
    alocacaoProvider.desmarcarAguardandoIntervalo(widget.colaborador.id);

    if (fiscalId.isNotEmpty) {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.intervaloMarcadoFeito,
        colaboradorNome: widget.colaborador.nome,
        caixaNome: caixa?.nomeExibicao,
        detalhe: fezCompleto
            ? 'Marcado manualmente: tempo completo'
            : 'Marcado manualmente: tempo incompleto',
      );
    }

    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Intervalo atualizado',
      mensagem: fezCompleto
          ? '${widget.colaborador.nome} foi marcado(a) com intervalo feito.'
          : 'Ocorrência registrada e intervalo marcado como feito.',
      tipo: 'saida',
      cor: AppColors.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final intervaloJaFeito =
        alocacaoProvider.isIntervaloMarcado(widget.colaborador.id) ||
            widget.cafeProvider.colaboradorJaFezIntervaloHoje(
              widget.colaborador.id,
            );

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Intervalo',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(widget.colaborador.nome, style: AppTextStyles.h3),
          Text(
            widget.colaborador.departamento.nome,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildPontoInfo(),
            const SizedBox(height: 24),
            if (!intervaloJaFeito) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _marcarIntervaloJaFeito,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Já fez intervalo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _enviarParaIntervalo,
                icon: const Icon(Icons.restaurant),
                label: const Text('Enviar para Intervalo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusCafe,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPontoInfo() {
    final saida = _ponto?.intervaloSaida;
    final retorno = _ponto?.intervaloRetorno;

    if (saida == null && retorno == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSection,
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sem horário de intervalo no registro de ponto. '
                'Sera necessario escolher 60 ou 120 min.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final saidaDT = _parseHorario(saida);
    final jaSaiu = saidaDT != null && DateTime.now().isAfter(saidaDT);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSection,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
      ),
      child: Column(
        children: [
          if (saida != null)
            _InfoRow(
              icon: Icons.logout,
              label: 'Saída agendada',
              valor: saida,
              destaque: jaSaiu,
            ),
          if (saida != null && retorno != null) const Divider(height: 16),
          if (retorno != null)
            _InfoRow(
              icon: Icons.login,
              label: 'Retorno agendado',
              valor: retorno,
            ),
          if (jaSaiu) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'O horário de saída já passou — informe quando saiu.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final bool destaque;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.valor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: destaque ? AppColors.warning : AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          valor,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: destaque ? AppColors.warning : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seletor completo (FAB): escolhe colaborador + duração
// ---------------------------------------------------------------------------
class _SeletorPausaSheet extends StatefulWidget {
  final CafeProvider cafeProvider;
  final Map<String, TurnoLocal> turnosById;

  const _SeletorPausaSheet({
    required this.cafeProvider,
    required this.turnosById,
  });

  @override
  State<_SeletorPausaSheet> createState() => _SeletorPausaSheetState();
}

class _SeletorPausaSheetState extends State<_SeletorPausaSheet> {
  int _duracaoSelecionada = 10;
  String? _colaboradorSelecionadoId;
  String? _colaboradorSelecionadoNome;

  int _duracaoCafePadrao() => 10;

  @override
  void initState() {
    super.initState();
    _duracaoSelecionada = _duracaoCafePadrao();
  }

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final jaFizeramCafe = widget.cafeProvider.pausasFinalizadas
        .where((p) => p.isCafe)
        .map((p) => p.colaboradorId)
        .toSet();
    // Exclui: não está na escala, em pausa ativa, ou já fez café
    final colaboradores = colaboradorProvider.colaboradores
        .where(
          (c) =>
              widget.turnosById.containsKey(c.id) &&
              !widget.cafeProvider.colaboradorEmPausa(c.id) &&
              !jaFizeramCafe.contains(c.id),
        )
        .toList();
    colaboradores.sort((a, b) {
      int? toMin(String? hhmm) {
        if (hhmm == null || hhmm.isEmpty) return null;
        final parts = hhmm.split(':');
        if (parts.length < 2) return null;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return h * 60 + m;
      }

      final aMin = toMin(widget.turnosById[a.id]?.intervalo) ?? 9999;
      final bMin = toMin(widget.turnosById[b.id]?.intervalo) ?? 9999;
      final comp = aMin.compareTo(bMin);
      if (comp != 0) return comp;
      return a.nome.compareTo(b.nome);
    });

    final duracoes = [_duracaoCafePadrao()];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Novo Café', style: AppTextStyles.h3),
            const SizedBox(height: 16),

            // Duração
            const Text('Duração do café', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: duracoes.map((d) {
                final selecionado = d == _duracaoSelecionada;
                return ChoiceChip(
                  label: Text('$d min'),
                  selected: selecionado,
                  selectedColor: AppColors.statusCafe,
                  labelStyle: TextStyle(
                    color: selecionado ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        selecionado ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _duracaoSelecionada = d),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Text('Colaborador', style: AppTextStyles.label),
            const SizedBox(height: 8),

            // Colaboradores disponíveis
            Expanded(
              child: colaboradores.isEmpty
                  ? Center(
                      child: Text(
                        'Todos os colaboradores já fizeram ou estão em pausa',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: colaboradores.length,
                      itemBuilder: (_, i) {
                        final c = colaboradores[i];
                        final turno = widget.turnosById[c.id];
                        final intervaloLabel =
                            (turno?.intervalo?.isNotEmpty == true &&
                                    turno?.retorno?.isNotEmpty == true)
                                ? '${turno!.intervalo} - ${turno.retorno}'
                                : 'Intervalo não definido';
                        final selecionado = _colaboradorSelecionadoId == c.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: selecionado
                                ? AppColors.statusCafe
                                : AppColors.backgroundSection,
                            child: Text(
                              c.nome.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: selecionado
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(c.nome),
                          subtitle: Text(
                            '${c.departamento.nome} - $intervaloLabel',
                          ),
                          selected: selecionado,
                          selectedTileColor:
                              AppColors.statusCafe.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () => setState(() {
                            _colaboradorSelecionadoId = c.id;
                            _colaboradorSelecionadoNome = c.nome;
                          }),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _colaboradorSelecionadoId == null
                    ? null
                    : () async {
                        final eventoProvider = Provider.of<EventoTurnoProvider>(
                            context,
                            listen: false);
                        final fiscalId =
                            Provider.of<AuthProvider>(context, listen: false)
                                    .user
                                    ?.id ??
                                '';
                        final alocacaoAtiva =
                            alocacaoProvider.getAlocacaoColaborador(
                          _colaboradorSelecionadoId!,
                        );
                        final caixaOrigemId = alocacaoAtiva?.caixaId;
                        if (alocacaoAtiva != null) {
                          await alocacaoProvider.liberarAlocacao(
                            alocacaoAtiva.id,
                            'cafe',
                          );
                        }
                        widget.cafeProvider.iniciarPausa(
                          colaboradorId: _colaboradorSelecionadoId!,
                          colaboradorNome: _colaboradorSelecionadoNome!,
                          duracaoMinutos: _duracaoSelecionada,
                          caixaId: caixaOrigemId,
                        );
                        eventoProvider.registrar(
                          fiscalId: fiscalId,
                          tipo: TipoEvento.cafeIniciado,
                          colaboradorNome: _colaboradorSelecionadoNome!,
                          detalhe: '$_duracaoSelecionada min',
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.coffee),
                label: Text('Iniciar $_duracaoSelecionada min de café'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusCafe,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
