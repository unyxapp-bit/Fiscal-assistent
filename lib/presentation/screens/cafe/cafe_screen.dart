import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/colaborador_provider.dart';

class CafeScreen extends StatelessWidget {
  const CafeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CafeProvider>(
      builder: (context, provider, _) {
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _StatsCard(
                        label: 'No Café',
                        value: provider.totalAtivos.toString(),
                        icon: Icons.coffee,
                        color: AppColors.statusCafe,
                      ),
                    ),
                    const SizedBox(width: Dimensions.spacingSM),
                    Expanded(
                      child: _StatsCard(
                        label: 'Em Atraso',
                        value: provider.totalEmAtraso.toString(),
                        icon: Icons.timer_off,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: Dimensions.spacingSM),
                    Expanded(
                      child: _StatsCard(
                        label: 'Pausas Hoje',
                        value: provider.totalHoje.toString(),
                        icon: Icons.history,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                // Alert banner
                if (temAlertas) ...[
                  const SizedBox(height: Dimensions.spacingMD),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
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
                      ],
                    ),
                  ),
                ],

                // Active breaks
                if (provider.pausasAtivas.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.spacingLG),
                  const Text('Em Intervalo Agora', style: AppTextStyles.h3),
                  const SizedBox(height: Dimensions.spacingSM),
                  ...provider.pausasAtivas.map(
                    (pausa) => _PausaAtivaCard(
                      pausa: pausa,
                      onFinalizar: () =>
                          provider.finalizarPausa(pausa.colaboradorId),
                    ),
                  ),
                ],

                const SizedBox(height: Dimensions.spacingLG),

                // History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Histórico de Hoje', style: AppTextStyles.h3),
                    Text(
                      '${provider.pausasFinalizadas.length} pausas',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spacingSM),

                if (provider.pausasFinalizadas.isEmpty &&
                    provider.pausasAtivas.isEmpty)
                  const _EmptyState()
                else if (provider.pausasFinalizadas.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhuma pausa finalizada ainda',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...provider.pausasFinalizadas.reversed.map(
                    (pausa) => _PausaHistoricoCard(
                      pausa: pausa,
                      onRemover: () => provider.removerRegistro(pausa.id),
                    ),
                  ),
              ],
            ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SeletorPausaSheet(cafeProvider: cafeProvider),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats Card
// ---------------------------------------------------------------------------
class _StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.h2.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Break Card with countdown
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
                  child: Icon(Icons.coffee, color: cor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pausa.colaboradorNome, style: AppTextStyles.h4),
                      Text(
                        '${pausa.duracaoMinutos} min • iniciado ${DateFormat("HH:mm").format(pausa.iniciadoEm)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
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
// History Card
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
          '${DateFormat("HH:mm").format(pausa.iniciadoEm)} → ${DateFormat("HH:mm").format(pausa.finalizadoEm!)} • ${duracao.inMinutes} min',
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
// Empty State
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.coffee_outlined,
              size: 64,
              color: AppColors.inactive,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma pausa para café hoje',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Iniciar Pausa" para registrar um intervalo',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet: Selecionar colaborador e duração
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
    final colaboradores = colaboradorProvider.colaboradores
        .where(
          (c) => !widget.cafeProvider.colaboradorEmPausa(c.id),
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
                    color: selecionado ? Colors.white : AppColors.textPrimary,
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

            // Colaboradores
            Expanded(
              child: colaboradores.isEmpty
                  ? Center(
                      child: Text(
                        'Todos os colaboradores estão em pausa',
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
                        widget.cafeProvider.iniciarPausa(
                          colaboradorId: _colaboradorSelecionadoId!,
                          colaboradorNome: _colaboradorSelecionadoNome!,
                          duracaoMinutos: _duracaoSelecionada,
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
