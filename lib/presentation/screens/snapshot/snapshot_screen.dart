import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../../domain/enums/status_presenca.dart';
import '../../providers/snapshot_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/cafe_provider.dart';

class SnapshotScreen extends StatefulWidget {
  const SnapshotScreen({super.key});

  @override
  State<SnapshotScreen> createState() => _SnapshotScreenState();
}

class _SnapshotScreenState extends State<SnapshotScreen> {
  final _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _criarSnapshot());
  }

  Future<void> _criarSnapshot() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final snapshotProvider =
        Provider.of<SnapshotProvider>(context, listen: false);
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);

    if (authProvider.user != null && !snapshotProvider.temSnapshotAtivo) {
      await snapshotProvider.criarSnapshot(
        authProvider.user!.id,
        DateTime.now(),
        colaboradorProvider.colaboradores,
      );
    }
  }

  /// Retorna o nome do colaborador a partir do ColaboradorProvider.
  String _nomeColaborador(String colaboradorId) {
    final colabs =
        Provider.of<ColaboradorProvider>(context, listen: false).colaboradores;
    try {
      return colabs.firstWhere((c) => c.id == colaboradorId).nome;
    } catch (_) {
      return colaboradorId.substring(0, 6).toUpperCase();
    }
  }

  /// Retorna o departamento do colaborador via ColaboradorProvider.
  DepartamentoTipo? _departamentoColaborador(String colaboradorId) {
    final colabs =
        Provider.of<ColaboradorProvider>(context, listen: false).colaboradores;
    try {
      return colabs.firstWhere((c) => c.id == colaboradorId).departamento;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshotProvider = Provider.of<SnapshotProvider>(context);
    final snapshot = snapshotProvider.snapshotAtual;

    if (snapshot == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            'Snapshot — ${_timeFormat.format(snapshot.dataHora)}'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!snapshot.finalizado)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Novo snapshot',
              onPressed: _criarSnapshot,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Resumo ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 0, Dimensions.paddingMD, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Atualizado: ${_timeFormat.format(DateTime.now())}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCard(
                      '${snapshot.totalConfirmados}/${snapshot.totalAtivos}',
                      'Confirmados',
                      StatusPresenca.confirmado.cor,
                      StatusPresenca.confirmado.icone,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      '${snapshot.totalPendentes}',
                      'Pendentes',
                      StatusPresenca.pendente.cor,
                      StatusPresenca.pendente.icone,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      '${snapshot.totalAusentes}',
                      'Ausências',
                      StatusPresenca.ausente.cor,
                      StatusPresenca.ausente.icone,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      '${snapshotProvider.totalComAtraso}',
                      'Atrasos',
                      AppColors.statusAtencao,
                      Icons.schedule_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: snapshot.percentualPresenca / 100,
                  backgroundColor: AppColors.inactive.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${snapshot.percentualPresenca.toStringAsFixed(0)}% de presença',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Lista ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD, vertical: 8),
              itemCount: snapshot.presencas.length,
              itemBuilder: (context, index) {
                final presenca = snapshot.presencas[index];

                // Folgas aparecem agrupadas no final com estilo diferente
                if (presenca.status == StatusPresenca.folga) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    color: AppColors.inactive.withValues(alpha: 0.08),
                    elevation: 0,
                    child: ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.beach_access,
                            color: AppColors.inactive, size: 20),
                      ),
                      title: Text(
                        _nomeColaborador(presenca.colaboradorId),
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.inactive),
                      ),
                      trailing: const Text('FOLGA',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.inactive,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }

                final isAtrasado = presenca.status == StatusPresenca.pendente &&
                    presenca.minutosAtraso != null &&
                    presenca.minutosAtraso! > 10;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isAtrasado
                        ? const BorderSide(
                            color: AppColors.statusAtencao, width: 1)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              presenca.status.cor.withValues(alpha: 0.18),
                          child: Text(
                            _nomeColaborador(presenca.colaboradorId)
                                .split(' ')
                                .take(2)
                                .map((w) => w[0])
                                .join()
                                .toUpperCase(),
                            style: TextStyle(
                              color: presenca.status.cor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isAtrasado)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.statusAtencao,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_rounded,
                                  size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      _nomeColaborador(presenca.colaboradorId),
                      style: AppTextStyles.h4,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          'Deveria estar desde ${_timeFormat.format(presenca.horarioEsperado.toLocal())}',
                          style: AppTextStyles.caption,
                        ),
                        if (isAtrasado) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${presenca.minutosAtraso} min de atraso',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.statusAtencao,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (presenca.foiSubstituido) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.swap_horiz,
                                  size: 12,
                                  color: AppColors.statusAtencao),
                              const SizedBox(width: 3),
                              Text(
                                'Substituído',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.statusAtencao),
                              ),
                            ],
                          ),
                        ],
                        if (presenca.observacao != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            presenca.observacao!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing:
                        _buildAcoes(context, presenca, snapshotProvider),
                  ),
                );
              },
            ),
          ),

          // ── Botão finalizar ────────────────────────────────────
          if (!snapshot.finalizado)
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              child: ElevatedButton.icon(
                onPressed: () {
                  snapshotProvider.finalizar();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Snapshot finalizado!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finalizar Check-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers de UI ───────────────────────────────────────────────────────

  Widget _buildStatCard(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(value,
                style: AppTextStyles.h4
                    .copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(label,
                style: AppTextStyles.caption.copyWith(fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAcoes(
    BuildContext context,
    dynamic presenca,
    SnapshotProvider provider,
  ) {
    if (presenca.status == StatusPresenca.confirmado) {
      return const Icon(Icons.check_circle, color: AppColors.success, size: 28);
    }

    if (presenca.status == StatusPresenca.ausente) {
      return IconButton(
        icon: const Icon(Icons.group_add, color: AppColors.primary),
        onPressed: () => _mostrarSubstitutos(context, presenca, provider),
        tooltip: 'Sugerir substituto',
      );
    }

    if (presenca.status == StatusPresenca.folga) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'confirmar',
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('Confirmar Presente'),
          ]),
        ),
        const PopupMenuItem(
          value: 'atrasado',
          child: Row(children: [
            Icon(Icons.schedule, color: AppColors.statusAtencao),
            SizedBox(width: 8),
            Text('Chegou Atrasado'),
          ]),
        ),
        const PopupMenuItem(
          value: 'ausente',
          child: Row(children: [
            Icon(Icons.cancel, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Marcar Ausente'),
          ]),
        ),
      ],
      onSelected: (value) {
        if (value == 'confirmar') {
          provider.confirmarPresenca(presenca.colaboradorId);
        } else if (value == 'atrasado') {
          provider.marcarAtrasado(presenca.colaboradorId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marcado como atrasado'),
              backgroundColor: AppColors.statusAtencao,
            ),
          );
        } else if (value == 'ausente') {
          _mostrarDialogoAusencia(context, presenca, provider);
        }
      },
    );
  }

  void _mostrarDialogoAusencia(
    BuildContext context,
    dynamic presenca,
    SnapshotProvider provider,
  ) {
    final obsController = TextEditingController();
    final nome = _nomeColaborador(presenca.colaboradorId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Ausente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(nome, style: AppTextStyles.h4),
            const SizedBox(height: 16),
            TextField(
              controller: obsController,
              decoration: const InputDecoration(
                labelText: 'Motivo da ausência (opcional)',
                hintText: 'Ex: Atestado, Falta justificada…',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.marcarAusente(
                presenca.colaboradorId,
                obsController.text.trim().isNotEmpty
                    ? obsController.text.trim()
                    : null,
              );
              Navigator.pop(ctx);
              _mostrarSubstitutos(context, presenca, provider);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('Confirmar Ausência'),
          ),
        ],
      ),
    );
  }

  // ── Substitutos reais ───────────────────────────────────────────────────

  List<Colaborador> _buscarSubstitutosReais(String colaboradorId) {
    final dept = _departamentoColaborador(colaboradorId);
    final colabProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final alocProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final cafeProvider = Provider.of<CafeProvider>(context, listen: false);
    final snapshot =
        Provider.of<SnapshotProvider>(context, listen: false).snapshotAtual;

    // IDs que já estão no snapshot (evitar duplicar)
    final idsNoSnapshot = snapshot?.presencas
            .where((p) =>
                p.status != StatusPresenca.ausente &&
                p.status != StatusPresenca.folga)
            .map((p) => p.colaboradorId)
            .toSet() ??
        <String>{};

    return colabProvider.colaboradores
        .where((c) => c.ativo)
        .where((c) => dept == null || c.departamento == dept)
        .where((c) => c.id != colaboradorId) // não ele mesmo
        .where((c) => !idsNoSnapshot.contains(c.id)) // não no snapshot ativo
        .where((c) => alocProvider.getAlocacaoColaborador(c.id) == null)
        .where((c) => !cafeProvider.colaboradorEmPausa(c.id))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  void _mostrarSubstitutos(
    BuildContext context,
    dynamic presenca,
    SnapshotProvider provider,
  ) {
    final sugestoes = _buscarSubstitutosReais(presenca.colaboradorId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: sugestoes.isEmpty ? 0.35 : 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.25,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.group_add, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Substitutos para ${_nomeColaborador(presenca.colaboradorId)}',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (sugestoes.isEmpty) ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off,
                            size: 48, color: AppColors.inactive),
                        SizedBox(height: 8),
                        Text(
                          'Nenhum colaborador disponível\ndo mesmo departamento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  '${sugestoes.length} disponíveis no mesmo setor',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: sugestoes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final c = sugestoes[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              c.iniciais,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(c.nome),
                          subtitle: Text(c.departamento.nome),
                          trailing: ElevatedButton(
                            onPressed: () {
                              provider.substituir(
                                presenca.colaboradorId,
                                c.id,
                                c.nome,
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${c.nome} alocado como substituto!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                            ),
                            child: const Text('Alocar'),
                          ),
                        ),
                      );
                    },
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
