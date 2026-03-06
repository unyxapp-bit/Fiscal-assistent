import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/evento_turno_provider.dart';

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

        // IDs que já passaram por pausa hoje (ativa ou finalizada)
        final jaFizeramPausa = {
          ...provider.pausasAtivas.map((p) => p.colaboradorId),
          ...provider.pausasFinalizadas.map((p) => p.colaboradorId),
        };

        final totalDisponiveis = colaboradorProvider.colaboradores
            .where((c) => c.ativo && !jaFizeramPausa.contains(c.id))
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
                    decoration: BoxDecoration(
                      color: AppColors.alertCritical,
                      borderRadius:
                          BorderRadius.circular(Dimensions.borderRadius),
                      border: Border.all(color: AppColors.danger),
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
                    _TabDisponiveis(provider: provider),
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
            label: const Text('Iniciar Pausa'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => _SeletorPausaSheet(cafeProvider: cafeProvider),
    );
  }
}

// ---------------------------------------------------------------------------
// Aba 1: Disponíveis para Pausa
// ---------------------------------------------------------------------------
class _TabDisponiveis extends StatelessWidget {
  final CafeProvider provider;

  const _TabDisponiveis({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);

    final jaFizeramPausa = {
      ...provider.pausasAtivas.map((p) => p.colaboradorId),
      ...provider.pausasFinalizadas.map((p) => p.colaboradorId),
    };

    final disponiveis = colaboradorProvider.colaboradores
        .where((c) => c.ativo && !jaFizeramPausa.contains(c.id))
        .toList();

    if (disponiveis.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.success.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(
                'Todos os colaboradores já fizeram o intervalo hoje!',
                style: AppTextStyles.body
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
          return Card(
            margin: isTablet
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: Dimensions.spacingSM),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.backgroundSection,
                child: Text(
                  c.iniciais.isNotEmpty ? c.iniciais[0] : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(c.nome, style: AppTextStyles.body),
              subtitle: Text(
                c.departamento.nome,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              trailing: TextButton.icon(
                onPressed: () => _abrirSeletorRapido(context, c),
                icon: const Icon(Icons.coffee, size: 16),
                label: const Text('Pausa'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusCafe,
                ),
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

  void _abrirSeletorRapido(BuildContext context, Colaborador colaborador) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _SeletorRapidoSheet(
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
                  size: 64, color: AppColors.inactive.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(
                'Nenhum colaborador em intervalo no momento',
                style: AppTextStyles.body
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
        final eventoProvider =
            Provider.of<EventoTurnoProvider>(context, listen: false);
        final fiscalId =
            Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

        void finalizarComEvento(PausaCafe pausa) {
          final tipo = pausa.duracaoMinutos <= 15
              ? TipoEvento.cafeEncerrado
              : TipoEvento.intervaloEncerrado;
          eventoProvider.registrar(
            fiscalId: fiscalId,
            tipo: tipo,
            colaboradorNome: pausa.colaboradorNome,
            detalhe: '${pausa.duracaoMinutos} min',
          );
          provider.finalizarPausa(pausa.colaboradorId);
        }

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
                onFinalizar: () => finalizarComEvento(pausa),
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
              onFinalizar: () => finalizarComEvento(pausa),
            );
          },
        );
      },
    );
  }
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
                  size: 64, color: AppColors.inactive.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(
                'Nenhuma pausa finalizada hoje',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
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

    final retornoPrevisto = pausa.iniciadoEm
        .add(Duration(minutes: pausa.duracaoMinutos));

    final restante = pausa.tempoRestante;
    final label = emAtraso
        ? '+${pausa.minutosExcedidos} min em atraso'
        : '${restante.inMinutes.toString().padLeft(2, "0")}:${(restante.inSeconds % 60).toString().padLeft(2, "0")} restantes';

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(color: cor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.15),
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
                      Text(pausa.colaboradorNome, style: AppTextStyles.h4),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Saiu às ${DateFormat("HH:mm").format(pausa.iniciadoEm)}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text('·',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                          Text(
                            'Retorna ${DateFormat("HH:mm").format(retornoPrevisto)}',
                            style: AppTextStyles.caption.copyWith(
                                color: emAtraso
                                    ? AppColors.danger
                                    : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onFinalizar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: AppTextStyles.caption,
                  ),
                  child: const Text('Finalizar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresso.clamp(0.0, 1.0),
                backgroundColor: cor.withValues(alpha: 0.15),
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

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.15),
          child: Icon(Icons.coffee_outlined, color: cor),
        ),
        title: Text(pausa.colaboradorNome, style: AppTextStyles.body),
        subtitle: Text(
          '${DateFormat("HH:mm").format(pausa.iniciadoEm)} → ${DateFormat("HH:mm").format(pausa.finalizadoEm!)} · ${duracao.inMinutes} min',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (foiEmAtraso)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  const _SeletorRapidoSheet({
    required this.colaborador,
    required this.cafeProvider,
  });

  @override
  Widget build(BuildContext context) {
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
            'Iniciar pausa para',
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
          const SizedBox(height: 24),
          const Text('Escolha a duração:', style: AppTextStyles.label),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [10, 15, 20, 30].map((d) {
              final isCafe = d <= 15;
              return ElevatedButton.icon(
                onPressed: () {
                  final eventoProvider = Provider.of<EventoTurnoProvider>(
                      context,
                      listen: false);
                  final fiscalId =
                      Provider.of<AuthProvider>(context, listen: false)
                              .user
                              ?.id ??
                          '';
                  cafeProvider.iniciarPausa(
                    colaboradorId: colaborador.id,
                    colaboradorNome: colaborador.nome,
                    duracaoMinutos: d,
                  );
                  eventoProvider.registrar(
                    fiscalId: fiscalId,
                    tipo: isCafe
                        ? TipoEvento.cafeIniciado
                        : TipoEvento.intervaloIniciado,
                    colaboradorNome: colaborador.nome,
                    detalhe: '$d min',
                  );
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
// Seletor completo (FAB): escolhe colaborador + duração
// ---------------------------------------------------------------------------
class _SeletorPausaSheet extends StatefulWidget {
  final CafeProvider cafeProvider;

  const _SeletorPausaSheet({required this.cafeProvider});

  @override
  State<_SeletorPausaSheet> createState() => _SeletorPausaSheetState();
}

class _SeletorPausaSheetState extends State<_SeletorPausaSheet> {
  int _duracaoSelecionada = 15;
  String? _colaboradorSelecionadoId;
  String? _colaboradorSelecionadoNome;

  final _duracoes = [10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);

    // Exclui: quem está em pausa ativa OU quem já finalizou uma pausa hoje
    final colaboradores = colaboradorProvider.colaboradores
        .where(
          (c) =>
              !widget.cafeProvider.colaboradorEmPausa(c.id) &&
              !widget.cafeProvider.pausasFinalizadas
                  .any((p) => p.colaboradorId == c.id),
        )
        .toList();

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
            const Text('Nova Pausa', style: AppTextStyles.h3),
            const SizedBox(height: 16),

            // Duração
            const Text('Duração', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _duracoes.map((d) {
                final selecionado = d == _duracaoSelecionada;
                return ChoiceChip(
                  label: Text('$d min'),
                  selected: selecionado,
                  selectedColor: AppColors.statusCafe,
                  labelStyle: TextStyle(
                    color:
                        selecionado ? Colors.white : AppColors.textPrimary,
                    fontWeight: selecionado
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (_) =>
                      setState(() => _duracaoSelecionada = d),
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
                        final selecionado =
                            _colaboradorSelecionadoId == c.id;
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
                          subtitle: Text(c.departamento.nome),
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
                    : () {
                        final eventoProvider = Provider.of<EventoTurnoProvider>(
                            context,
                            listen: false);
                        final fiscalId =
                            Provider.of<AuthProvider>(context, listen: false)
                                    .user
                                    ?.id ??
                                '';
                        widget.cafeProvider.iniciarPausa(
                          colaboradorId: _colaboradorSelecionadoId!,
                          colaboradorNome: _colaboradorSelecionadoNome!,
                          duracaoMinutos: _duracaoSelecionada,
                        );
                        eventoProvider.registrar(
                          fiscalId: fiscalId,
                          tipo: _duracaoSelecionada <= 15
                              ? TipoEvento.cafeIniciado
                              : TipoEvento.intervaloIniciado,
                          colaboradorNome: _colaboradorSelecionadoNome!,
                          detalhe: '$_duracaoSelecionada min',
                        );
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.coffee),
                label: Text('Iniciar $_duracaoSelecionada min de pausa'),
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
