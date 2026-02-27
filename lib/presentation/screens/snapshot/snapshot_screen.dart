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
import '../../providers/caixa_provider.dart';
import '../../providers/pacote_plantao_provider.dart';

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

  String _nomeColaborador(String colaboradorId) {
    final colabs =
        Provider.of<ColaboradorProvider>(context, listen: false).colaboradores;
    try {
      return colabs.firstWhere((c) => c.id == colaboradorId).nome;
    } catch (_) {
      return colaboradorId.substring(0, 6).toUpperCase();
    }
  }

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

                final isPendente = presenca.status == StatusPresenca.pendente;

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
                    onTap: isPendente && !snapshot.finalizado
                        ? () => _mostrarAcoesPresenca(
                            context, presenca, snapshotProvider)
                        : null,
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
                          _horarioSubtitle(presenca),
                          style: AppTextStyles.caption.copyWith(
                            color: _horarioSubtitleColor(presenca),
                            fontWeight: _horarioSubtitleBold(presenca)
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
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

  // ── Helpers de horário ──────────────────────────────────────────────────

  String _horarioSubtitle(dynamic presenca) {
    final hora =
        _timeFormat.format(presenca.horarioEsperado.toLocal());

    if (presenca.status == StatusPresenca.confirmado) {
      if (presenca.confirmadoEm != null) {
        return 'Chegou às ${_timeFormat.format(presenca.confirmadoEm!.toLocal())}';
      }
      return 'Confirmado · esperado às $hora';
    }

    if (presenca.status == StatusPresenca.atrasado) {
      return 'Chegou atrasado · esperado às $hora';
    }

    if (presenca.status == StatusPresenca.ausente) {
      return 'Ausente · esperado às $hora';
    }

    final diff =
        presenca.horarioEsperado.toLocal().difference(DateTime.now());
    final minutos = diff.inMinutes;

    if (minutos > 0) {
      if (minutos >= 60) {
        final h = minutos ~/ 60;
        final m = minutos % 60;
        final resto = m > 0 ? ' ${m}min' : '';
        return 'Chega às $hora · em ${h}h$resto';
      }
      return 'Chega às $hora · em $minutos min';
    } else if (minutos == 0) {
      return 'Deveria chegar agora ($hora)';
    } else {
      final atraso = minutos.abs();
      if (atraso >= 60) {
        final h = atraso ~/ 60;
        final m = atraso % 60;
        final resto = m > 0 ? ' ${m}min' : '';
        return 'Esperado às $hora · ${h}h$resto de atraso';
      }
      return 'Esperado às $hora · $atraso min de atraso';
    }
  }

  Color _horarioSubtitleColor(dynamic presenca) {
    if (presenca.status == StatusPresenca.confirmado) {
      return AppColors.success;
    }
    if (presenca.status == StatusPresenca.atrasado) {
      return AppColors.statusAtencao;
    }
    if (presenca.status == StatusPresenca.ausente) {
      return AppColors.danger;
    }
    final diff =
        presenca.horarioEsperado.toLocal().difference(DateTime.now());
    if (diff.inMinutes < 0) return AppColors.statusAtencao;
    return AppColors.textSecondary;
  }

  bool _horarioSubtitleBold(dynamic presenca) {
    if (presenca.status == StatusPresenca.confirmado ||
        presenca.status == StatusPresenca.ausente ||
        presenca.status == StatusPresenca.atrasado) {
      return false;
    }
    final diff =
        presenca.horarioEsperado.toLocal().difference(DateTime.now());
    return diff.inMinutes < 0;
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

    if (presenca.status == StatusPresenca.atrasado) {
      return const Icon(Icons.schedule,
          color: AppColors.statusAtencao, size: 28);
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

    // pendente — seta indicando que o tile é tappable
    return const Icon(Icons.chevron_right,
        color: AppColors.textSecondary, size: 20);
  }

  // ── Sheet de ações (pendente) ────────────────────────────────────────────

  void _mostrarAcoesPresenca(
    BuildContext context,
    dynamic presenca,
    SnapshotProvider provider,
  ) {
    final nome = _nomeColaborador(presenca.colaboradorId);
    final dept = _departamentoColaborador(presenca.colaboradorId);
    final hora = _timeFormat.format(presenca.horarioEsperado.toLocal());
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final pacoteProvider =
        Provider.of<PacotePlantaoProvider>(context, listen: false);
    final fiscalId = authProvider.user?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Avatar + info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    nome
                        .split(' ')
                        .take(2)
                        .map((w) => w[0])
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: AppTextStyles.h4),
                      Text(
                        '${dept?.nome ?? ''} · esperado às $hora',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),

            _AcaoBtn(
              icon: Icons.check_circle_outline,
              label: 'Confirmar presente',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(sheetCtx);
                provider.confirmarPresenca(presenca.colaboradorId);
              },
            ),

            const SizedBox(height: 8),

            _AcaoBtn(
              icon: Icons.person_pin,
              label: 'Confirmar + Alocar em caixa',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(sheetCtx);
                provider.confirmarPresenca(presenca.colaboradorId);
                _mostrarPickerCaixas(context, presenca.colaboradorId,
                    fiscalId, alocacaoProvider);
              },
            ),

            const SizedBox(height: 8),

            _AcaoBtn(
              icon: Icons.hourglass_top,
              label: 'Aguardando caixa',
              color: const Color(0xFF009688),
              onTap: () {
                Navigator.pop(sheetCtx);
                provider.confirmarPresenca(presenca.colaboradorId,
                    observacao: 'Aguardando caixa');
              },
            ),

            if (dept == DepartamentoTipo.pacote) ...[
              const SizedBox(height: 8),
              _AcaoBtn(
                icon: Icons.shopping_bag,
                label: 'Presente + Em trabalho (Pacotes)',
                color: const Color(0xFF795548),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await provider.confirmarPresenca(presenca.colaboradorId);
                  await pacoteProvider.adicionar(
                      fiscalId, presenca.colaboradorId);
                },
              ),
            ],

            const SizedBox(height: 8),

            _AcaoBtn(
              icon: Icons.schedule,
              label: 'Chegou atrasado',
              color: AppColors.statusAtencao,
              onTap: () {
                Navigator.pop(sheetCtx);
                provider.marcarAtrasado(presenca.colaboradorId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marcado como atrasado'),
                    backgroundColor: AppColors.statusAtencao,
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _AcaoBtn(
              icon: Icons.cancel_outlined,
              label: 'Marcar ausente',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(sheetCtx);
                _mostrarDialogoAusencia(context, presenca, provider);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Picker inline de caixas disponíveis ─────────────────────────────────

  void _mostrarPickerCaixas(
    BuildContext context,
    String colaboradorId,
    String fiscalId,
    AlocacaoProvider alocacaoProvider,
  ) {
    final caixaProvider =
        Provider.of<CaixaProvider>(context, listen: false);

    final disponiveis = caixaProvider.caixas
        .where((c) =>
            c.ativo &&
            !c.emManutencao &&
            alocacaoProvider.getAlocacaoCaixa(c.id) == null)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (pickerCtx) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(pickerCtx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Alocar em caixa',
                    style: AppTextStyles.subtitle
                        .copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(pickerCtx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (disponiveis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('Nenhum caixa disponível no momento')),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(pickerCtx).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: disponiveis.length,
                  itemBuilder: (_, i) {
                    final caixa = disponiveis[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          '${caixa.numero}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(caixa.nomeExibicao),
                      subtitle: Text(caixa.tipo.nome),
                      onTap: () async {
                        Navigator.pop(pickerCtx);
                        await alocacaoProvider.alocarColaborador(
                          colaboradorId: colaboradorId,
                          caixaId: caixa.id,
                          fiscalId: fiscalId,
                        );
                        if (alocacaoProvider.error != null &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(alocacaoProvider.error!),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Alocado em ${caixa.nomeExibicao}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
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
        .where((c) => c.id != colaboradorId)
        .where((c) => !idsNoSnapshot.contains(c.id))
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

// ── Botão de ação no sheet ─────────────────────────────────────────────────────

class _AcaoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AcaoBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
