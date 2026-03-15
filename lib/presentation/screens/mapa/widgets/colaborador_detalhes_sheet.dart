// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../../domain/entities/alocacao.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/entities/registro_ponto.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/escala_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/evento_turno_provider.dart';
import '../../../providers/registro_ponto_provider.dart';
import '../../../../domain/entities/evento_turno.dart';
import '../../alocacao/alocacao_screen.dart';
import '../../../../data/services/notification_service.dart';
import '../../../providers/ocorrencia_provider.dart';
import '../../../../core/utils/app_notif.dart';

// ─────────────────────────────────────────────
// Resultado do cálculo de jornada
// ─────────────────────────────────────────────
class JornadaResult {
  final String? entrada;
  final Duration liquida;
  final String status;

  const JornadaResult({
    required this.entrada,
    required this.liquida,
    required this.status,
  });

  factory JornadaResult.semPonto() => const JornadaResult(
        entrada: null,
        liquida: Duration.zero,
        status: 'sem_ponto',
      );
}

// ─────────────────────────────────────────────
// Bottom sheet com carregamento de registro_ponto
// ─────────────────────────────────────────────
class ColaboradorDetalhesSheet extends StatefulWidget {
  final Caixa caixa;
  final Colaborador? colaborador;
  final Alocacao? alocacao;
  final TurnoLocal? turno;
  final dynamic pausa;
  final AlocacaoProvider alocacaoProvider;
  final BuildContext providerContext;
  final String liberarLabel;

  const ColaboradorDetalhesSheet({
    super.key,
    required this.caixa,
    required this.colaborador,
    required this.alocacao,
    required this.turno,
    required this.pausa,
    required this.alocacaoProvider,
    required this.providerContext,
    this.liberarLabel = 'Liberar Caixa',
  });

  @override
  State<ColaboradorDetalhesSheet> createState() =>
      ColaboradorDetalhesSheetState();
}

class ColaboradorDetalhesSheetState extends State<ColaboradorDetalhesSheet> {
  RegistroPonto? _registroHoje;
  bool _carregando = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.colaborador != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _carregarRegistro());
    }
    // Atualiza countdown a cada 30 s quando há horário de intervalo na escala
    if (widget.turno?.intervalo != null) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarRegistro() async {
    setState(() => _carregando = true);
    try {
      final provider = Provider.of<RegistroPontoProvider>(
          widget.providerContext,
          listen: false);
      await provider.loadRegistros(widget.colaborador!.id);

      if (!mounted) return;

      final now = DateTime.now();
      final registro = provider.registros
          .where((r) =>
              r.data.year == now.year &&
              r.data.month == now.month &&
              r.data.day == now.day)
          .firstOrNull;

      setState(() {
        _registroHoje = registro;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  JornadaResult _calcJornada() {
    final r = _registroHoje;

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);

    DateTime? parse(String? s) {
      if (s == null || s.isEmpty) return null;
      final parts = s.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return DateTime(base.year, base.month, base.day, h, m);
    }

    // Sem registro de ponto — tenta usar horário de escala como estimativa
    if (r == null || r.entrada == null || r.entrada!.isEmpty) {
      final turnoEntrada = parse(widget.turno?.entrada);
      if (turnoEntrada == null) return JornadaResult.semPonto();
      final liquida = now.difference(turnoEntrada);
      return JornadaResult(
        entrada: widget.turno!.entrada,
        liquida: liquida.isNegative ? Duration.zero : liquida,
        status: 'escala',
      );
    }

    final entrada = parse(r.entrada)!;
    final intSaida = parse(r.intervaloSaida);
    final intRetorno = parse(r.intervaloRetorno);
    final saida = parse(r.saida);

    String status;
    DateTime fimCalculo;

    if (saida != null && now.isAfter(saida)) {
      status = 'encerrado';
      fimCalculo = saida;
    } else if (intSaida != null &&
        now.isAfter(intSaida) &&
        (intRetorno == null || now.isBefore(intRetorno))) {
      status = 'intervalo';
      fimCalculo = intSaida;
    } else {
      status = 'trabalhando';
      fimCalculo = now;
    }

    final bruta = fimCalculo.difference(entrada);

    Duration desconto = Duration.zero;
    if (intSaida != null &&
        intRetorno != null &&
        fimCalculo.isAfter(intRetorno)) {
      desconto = intRetorno.difference(intSaida);
    }

    final liquida = bruta - desconto;

    return JornadaResult(
      entrada: r.entrada,
      liquida: liquida.isNegative ? Duration.zero : liquida,
      status: status,
    );
  }

  String _formatDuracao(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final jornada = _calcJornada();

    final ocorrenciasCaixa = Provider.of<OcorrenciaProvider>(
      widget.providerContext,
      listen: false,
    ).todas.where((o) => o.caixaId == widget.caixa.id).toList()
      ..sort((a, b) => b.registradaEm.compareTo(a.registradaEm));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingXL,
        Dimensions.paddingXL,
        Dimensions.paddingXL,
        Dimensions.paddingXL,
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

          // Cabeçalho
          Row(
            children: [
              Icon(widget.caixa.tipo.icone,
                  color: widget.caixa.tipo.cor, size: 22),
              const SizedBox(width: 8),
              Text(widget.caixa.nomeExibicao, style: AppTextStyles.h2),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.caixa.tipo.cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.caixa.tipo.nome,
                  style: AppTextStyles.caption
                      .copyWith(color: widget.caixa.tipo.cor),
                ),
              ),
              if (widget.caixa.localizacao != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSection,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        widget.caixa.localizacao!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const Divider(height: 24),

          // ── INFO DO CAIXA ─────────────────────────────────────────────────
          _SobreCaixaSection(
            caixa: widget.caixa,
            ocorrencias: ocorrenciasCaixa,
            providerContext: widget.providerContext,
          ),

          if (widget.colaborador != null && widget.alocacao != null) ...[
            // Avatar + nome + departamento
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    widget.colaborador!.iniciais,
                    style: const TextStyle(
                      color: Colors.white,
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
                      Text(widget.colaborador!.nome,
                          style: AppTextStyles.h4),
                      Text(
                        widget.colaborador!.departamento.nome,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Alerta de pausa de café
            if (widget.pausa != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.coffee,
                        color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Em pausa de café — ${widget.pausa.minutosDecorridos}min decorridos'
                      '${widget.pausa.emAtraso ? ' (${widget.pausa.minutosExcedidos}min em atraso)' : ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Jornada baseada no ponto
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Carregando ponto...'),
                  ],
                ),
              )
            else if (jornada.status == 'sem_ponto')
              InfoRow(
                icon: Icons.access_time,
                label: 'Alocado às',
                value:
                    '${widget.alocacao!.alocadoEm.hour.toString().padLeft(2, '0')}:'
                    '${widget.alocacao!.alocadoEm.minute.toString().padLeft(2, '0')} '
                    '(sem registro de ponto hoje)',
                iconColor: AppColors.textSecondary,
              )
            else if (jornada.status == 'escala') ...[
              InfoRow(
                icon: Icons.schedule,
                label: 'Ativo desde',
                value: '${jornada.entrada} (escala)',
                iconColor: AppColors.statusAtencao,
              ),
              const SizedBox(height: 6),
              InfoRow(
                icon: Icons.timer_outlined,
                label: 'Jornada estimada',
                value: _formatDuracao(jornada.liquida),
                iconColor: AppColors.statusAtencao,
              ),
              const SizedBox(height: 6),
              const StatusBadge(status: 'trabalhando'),
            ] else ...[
              InfoRow(
                icon: Icons.fingerprint,
                label: 'Ativo desde',
                value: '${jornada.entrada} (ponto)',
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 6),
              InfoRow(
                icon: Icons.timer_outlined,
                label: 'Jornada líquida',
                value: _formatDuracao(jornada.liquida),
                iconColor: _corJornada(jornada.status),
              ),
              const SizedBox(height: 6),
              StatusBadge(status: jornada.status),
            ],

            const SizedBox(height: 12),

            // Banner de countdown / aguardando intervalo
            _buildIntervaloStatusBanner(),

            if (widget.turno != null) ...[
              const Text('Escala de hoje', style: AppTextStyles.label),
              const SizedBox(height: 8),
              HorarioGrid(turno: widget.turno!),
            ],

            const SizedBox(height: 20),

            // ── AÇÕES RÁPIDAS ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder),
                  bottom: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AÇÕES RÁPIDAS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.swap_horiz,
                          label: 'Trocar',
                          color: Colors.blue,
                          onTap: _trocarColaborador,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.coffee,
                          label: 'Café',
                          color: const Color(0xFF8D6E63),
                          onTap: _enviarParaCafe,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.restaurant,
                          label: 'Intervalo',
                          color: Colors.orange,
                          onTap: _enviarParaIntervalo,
                        ),
                      ),
                    ],
                  ),
                  // ── Botão "Intervalo já feito" ─────────────────────────
                  Builder(builder: (context) {
                    if (widget.turno?.intervalo == null) return const SizedBox.shrink();
                    final parts = widget.turno!.intervalo!.split(':');
                    if (parts.length < 2) return const SizedBox.shrink();
                    final agora = DateTime.now();
                    final agoraMin = agora.hour * 60 + agora.minute;
                    final intervaloMin = (int.tryParse(parts[0]) ?? 0) * 60 +
                        (int.tryParse(parts[1]) ?? 0);
                    final minPassado = agoraMin - intervaloMin;
                    if (minPassado <= 0) return const SizedBox.shrink();
                    final jaMarcado = widget.alocacaoProvider
                        .isIntervaloMarcado(widget.colaborador!.id);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: jaMarcado
                            ? () {
                                // Intervalo já feito no horário correto:
                                // remove o estado "aguardando liberação" e fecha
                                widget.alocacaoProvider
                                    .desmarcarAguardandoIntervalo(
                                        widget.colaborador!.id);
                                Navigator.of(context).pop();
                              }
                            : () async {
                                final eventoProvider =
                                    Provider.of<EventoTurnoProvider>(
                                        widget.providerContext,
                                        listen: false);
                                final fiscalId =
                                    Provider.of<AuthProvider>(
                                            widget.providerContext,
                                            listen: false)
                                        .user
                                        ?.id ??
                                    '';
                                await widget.alocacaoProvider
                                    .marcarIntervaloFeito(
                                        widget.colaborador!.id);
                                eventoProvider.registrar(
                                  fiscalId: fiscalId,
                                  tipo: TipoEvento.intervaloMarcadoFeito,
                                  colaboradorNome: widget.colaborador!.nome,
                                  caixaNome: widget.caixa.nomeExibicao,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        icon: Icon(
                          jaMarcado
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(jaMarcado
                            ? 'Intervalo já registrado'
                            : 'Intervalo já feito'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(
                              color: jaMarcado
                                  ? Colors.green.shade200
                                  : Colors.green.shade700),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    );
                  }),

                  // ── Botão "Aguardando liberação para intervalo" ────────
                  Builder(builder: (context) {
                    final cafeProvider = Provider.of<CafeProvider>(
                        widget.providerContext, listen: false);
                    // Não mostrar se já está em pausa ou intervalo marcado
                    if (cafeProvider
                        .colaboradorEmPausa(widget.colaborador!.id)) {
                      return const SizedBox.shrink();
                    }
                    if (widget.alocacaoProvider
                        .isIntervaloMarcado(widget.colaborador!.id)) {
                      return const SizedBox.shrink();
                    }
                    final aguardando = widget.alocacaoProvider
                        .isAguardandoIntervalo(widget.colaborador!.id);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: aguardando
                            ? () {
                                widget.alocacaoProvider
                                    .desmarcarAguardandoIntervalo(
                                        widget.colaborador!.id);
                                setState(() {});
                              }
                            : () {
                                widget.alocacaoProvider
                                    .marcarAguardandoIntervalo(
                                        widget.colaborador!.id);
                                // Registrar na timeline
                                final eventoProvider =
                                    Provider.of<EventoTurnoProvider>(
                                        widget.providerContext,
                                        listen: false);
                                final fiscalId =
                                    Provider.of<AuthProvider>(
                                            widget.providerContext,
                                            listen: false)
                                        .user
                                        ?.id ??
                                    '';
                                eventoProvider.registrar(
                                  fiscalId: fiscalId,
                                  tipo: TipoEvento
                                      .intervaloAguardandoLiberacao,
                                  colaboradorNome:
                                      widget.colaborador!.nome,
                                  caixaNome: widget.caixa.nomeExibicao,
                                  detalhe: widget.turno?.intervalo != null
                                      ? 'previsto ${widget.turno!.intervalo}'
                                      : null,
                                );
                                setState(() {});
                              },
                        icon: Icon(
                          aguardando
                              ? Icons.pending_actions
                              : Icons.access_time,
                          size: 18,
                        ),
                        label: Text(aguardando
                            ? 'Aguardando liberação (toque para cancelar)'
                            : 'Aguardando liberação para intervalo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: aguardando
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          side: BorderSide(
                            color: aguardando
                                ? AppColors.warning
                                : AppColors.cardBorder,
                          ),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () async {
                final providerCtx = widget.providerContext;
                final eventoProvider = Provider.of<EventoTurnoProvider>(
                    providerCtx,
                    listen: false);
                final fiscalId =
                    Provider.of<AuthProvider>(providerCtx,
                            listen: false)
                        .user
                        ?.id ??
                    '';
                final navigator = Navigator.of(context);

                navigator.pop();
                await widget.alocacaoProvider.liberarAlocacao(
                  widget.alocacao!.id,
                  'Liberado pelo mapa visual',
                );
                eventoProvider.registrar(
                  fiscalId: fiscalId,
                  tipo: TipoEvento.colaboradorLiberado,
                  colaboradorNome: widget.colaborador?.nome,
                  caixaNome: widget.caixa.nomeExibicao,
                );
                AppNotif.show(
                  providerCtx,
                  titulo: 'Colaborador Liberado',
                  mensagem: 'Colaborador liberado!',
                  tipo: 'saida',
                  cor: AppColors.success,
                );
              },
              icon: const Icon(Icons.exit_to_app),
              label: Text(widget.liberarLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ] else ...[
            Text(
              widget.caixa.emManutencao
                  ? 'Caixa em manutenção'
                  : !widget.caixa.ativo
                      ? 'Caixa inativo'
                      : 'Caixa disponível',
              style: AppTextStyles.body,
            ),

            if (widget.caixa.ativo && !widget.caixa.emManutencao) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  final fiscalId =
                      Provider.of<AuthProvider>(widget.providerContext,
                              listen: false)
                          .user
                          ?.id ??
                          '';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AlocacaoScreen(fiscalId: fiscalId),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Alocar Colaborador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Botão de ação compacto ──────────────────────────────────────────────────

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trocar Colaborador ─────────────────────────────────────────────────────

  void _trocarColaborador() {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(
        widget.providerContext,
        listen: false);
    final cafeProvider =
        Provider.of<CafeProvider>(widget.providerContext, listen: false);
    final escalaProvider =
        Provider.of<EscalaProvider>(widget.providerContext, listen: false);
    final idsAlocados = widget.alocacaoProvider
        .getAlocacoesAtivas()
        .map((a) => a.colaboradorId)
        .toSet()
      ..remove(widget.colaborador!.id);

    final agora = DateTime.now();
    final agoraTotalMin = agora.hour * 60 + agora.minute;

    final disponiveis = colaboradorProvider.colaboradores.where((c) {
      if (!c.ativo) return false;
      if (idsAlocados.contains(c.id)) return false;
      // Excluir quem está em pausa de café
      if (cafeProvider.colaboradorEmPausa(c.id)) return false;
      // Excluir quem sai em menos de 30 minutos
      final turno = escalaProvider.getTurno(c.id, agora);
      if (turno?.saida != null) {
        final parts = turno!.saida!.split(':');
        if (parts.length == 2) {
          final saidaMin = (int.tryParse(parts[0]) ?? 0) * 60 +
              (int.tryParse(parts[1]) ?? 0);
          if (saidaMin - agoraTotalMin < 30) return false;
        }
      }
      return true;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Trocar Colaborador', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Substituto para ${widget.caixa.nomeExibicao}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: disponiveis.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhum colaborador disponível'),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: disponiveis.length,
                      itemBuilder: (_, i) {
                        final c = disponiveis[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.blue.withValues(alpha: 0.15),
                            child: Text(
                              c.iniciais,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(c.nome, style: AppTextStyles.body),
                          subtitle: Text(c.departamento.nome,
                              style: AppTextStyles.caption),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14),
                          onTap: () => _confirmarTroca(sheetCtx, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarTroca(
      BuildContext sheetCtx, Colaborador novo) async {
    Navigator.pop(sheetCtx);

    final providerCtx = widget.providerContext;
    final authProvider =
        Provider.of<AuthProvider>(providerCtx, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(providerCtx, listen: false);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Troca'),
        content: Text(
            'Substituir ${widget.colaborador!.nome} por ${novo.nome} no ${widget.caixa.nomeExibicao}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final fiscalId = authProvider.user?.id ?? '';

    await widget.alocacaoProvider
        .liberarAlocacao(widget.alocacao!.id, 'troca');
    await widget.alocacaoProvider.alocarColaborador(
      colaboradorId: novo.id,
      caixaId: widget.caixa.id,
      fiscalId: fiscalId,
      justificativa: 'Troca de colaborador',
    );

    eventoProvider.registrar(
      fiscalId: fiscalId,
      tipo: TipoEvento.colaboradorLiberado,
      colaboradorNome: widget.colaborador?.nome,
      caixaNome: widget.caixa.nomeExibicao,
      detalhe: 'troca',
    );
    eventoProvider.registrar(
      fiscalId: fiscalId,
      tipo: TipoEvento.colaboradorAlocado,
      colaboradorNome: novo.nome,
      caixaNome: widget.caixa.nomeExibicao,
      detalhe: 'troca',
    );

    if (mounted) {
      navigator.pop();
      AppNotif.show(
        providerCtx,
        titulo: 'Colaborador Alocado',
        mensagem: '${novo.nome} alocado no ${widget.caixa.nomeExibicao}',
        tipo: 'saida',
        cor: AppColors.success,
      );
    }
  }

  // ── Café ───────────────────────────────────────────────────────────────────

  Future<void> _enviarParaCafe() async {
    final providerCtx = widget.providerContext;
    final cafeProvider =
        Provider.of<CafeProvider>(providerCtx, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(providerCtx, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(providerCtx, listen: false)
                .user
                ?.id ??
            '';
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar para Café ☕'),
        content: Text(
            'Enviar ${widget.colaborador!.nome} para 10 min de café?\nO caixa será liberado automaticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63)),
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await widget.alocacaoProvider
        .liberarAlocacao(widget.alocacao!.id, 'cafe');

    cafeProvider.iniciarPausa(
      colaboradorId: widget.colaborador!.id,
      colaboradorNome: widget.colaborador!.nome,
      duracaoMinutos: 10,
      caixaId: widget.caixa.id,
    );

    eventoProvider.registrar(
      fiscalId: fiscalId,
      tipo: TipoEvento.cafeIniciado,
      colaboradorNome: widget.colaborador!.nome,
      caixaNome: widget.caixa.nomeExibicao,
      detalhe: '10 min',
    );

    if (mounted) {
      navigator.pop();
      AppNotif.show(
        providerCtx,
        titulo: 'Café Iniciado',
        mensagem: '${widget.colaborador!.nome} — pausa de café iniciada (10 min)',
        tipo: 'cafe',
        cor: const Color(0xFF8D6E63),
      );
    }
  }

  // ── Intervalo ──────────────────────────────────────────────────────────────

  Future<void> _enviarParaIntervalo() async {
    int duracaoMinutos = 30;
    if (widget.turno != null) {
      final t = widget.turno!;
      if (t.intervalo != null && t.retorno != null) {
        final p1 = t.intervalo!.split(':');
        final p2 = t.retorno!.split(':');
        if (p1.length == 2 && p2.length == 2) {
          final ini = Duration(
              hours: int.tryParse(p1[0]) ?? 0,
              minutes: int.tryParse(p1[1]) ?? 0);
          final ret = Duration(
              hours: int.tryParse(p2[0]) ?? 0,
              minutes: int.tryParse(p2[1]) ?? 0);
          final diff = ret - ini;
          if (!diff.isNegative && diff.inMinutes > 0) {
            duracaoMinutos = diff.inMinutes;
          }
        }
      }
    }

    final providerCtx = widget.providerContext;
    final navigator = Navigator.of(context);
    final cafeProviderIntervalo =
        Provider.of<CafeProvider>(providerCtx, listen: false);
    final eventoProviderIntervalo =
        Provider.of<EventoTurnoProvider>(providerCtx, listen: false);
    final fiscalIdIntervalo =
        Provider.of<AuthProvider>(providerCtx, listen: false)
                .user
                ?.id ??
            '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar para Intervalo 🍽️'),
        content: Text(
            'Enviar ${widget.colaborador!.nome} para intervalo de $duracaoMinutos min?\nO caixa será liberado e uma notificação de retorno será agendada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await widget.alocacaoProvider
        .liberarAlocacao(widget.alocacao!.id, 'intervalo');

    cafeProviderIntervalo.iniciarPausa(
      colaboradorId: widget.colaborador!.id,
      colaboradorNome: widget.colaborador!.nome,
      duracaoMinutos: duracaoMinutos,
      caixaId: widget.caixa.id,
    );

    eventoProviderIntervalo.registrar(
      fiscalId: fiscalIdIntervalo,
      tipo: TipoEvento.intervaloIniciado,
      colaboradorNome: widget.colaborador!.nome,
      caixaNome: widget.caixa.nomeExibicao,
      detalhe: '$duracaoMinutos min',
    );

    final retornoEm =
        DateTime.now().add(Duration(minutes: duracaoMinutos));
    NotificationService.instance.scheduleAlert(
      id: (widget.colaborador!.id.hashCode.abs() % 100000) + 1,
      title: 'Intervalo encerrado 🍽️',
      body:
          '${widget.colaborador!.nome} deve retornar ao ${widget.caixa.nomeExibicao}',
      scheduledAt: retornoEm,
    );

    if (mounted) {
      navigator.pop();
      AppNotif.show(
        providerCtx,
        titulo: 'Intervalo Iniciado',
        mensagem: '${widget.colaborador!.nome} — intervalo de $duracaoMinutos min. Notificação agendada.',
        tipo: 'intervalo',
        cor: Colors.orange,
      );
    }
  }

  // ── Banner de status do intervalo ─────────────────────────────────────────
  // Mostra countdown ou "Aguardando Intervalo" com tempo decorrido.
  Widget _buildIntervaloStatusBanner() {
    if (widget.colaborador == null) return const SizedBox.shrink();

    // Se já está em pausa ativa, o alerta de pausa já cobre isso
    final cafeProvider =
        Provider.of<CafeProvider>(widget.providerContext, listen: false);
    if (cafeProvider.colaboradorEmPausa(widget.colaborador!.id)) {
      return const SizedBox.shrink();
    }

    // Se o intervalo já foi marcado como feito, não mostra o banner
    if (widget.alocacaoProvider.isIntervaloMarcado(widget.colaborador!.id)) {
      return const SizedBox.shrink();
    }

    // Usa horário de intervalo do registro de ponto, ou da escala como fallback
    final intervaloStr =
        _registroHoje?.intervaloSaida ?? widget.turno?.intervalo;
    if (intervaloStr == null || intervaloStr.isEmpty) {
      return const SizedBox.shrink();
    }

    final parts = intervaloStr.split(':');
    if (parts.length < 2) return const SizedBox.shrink();
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final intervaloTime = DateTime(now.year, now.month, now.day, h, m);
    final diff = intervaloTime.difference(now);

    if (diff.inSeconds > 0) {
      // Falta tempo — countdown
      final minutos = diff.inMinutes;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              minutos > 0
                  ? '$minutos min para o intervalo ($intervaloStr)'
                  : 'Intervalo em menos de 1 min ($intervaloStr)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      // Passou do horário — Aguardando Intervalo
      final passou = diff.inMinutes.abs();
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 15, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                passou == 0
                    ? 'Horário de intervalo agora ($intervaloStr)'
                    : 'Aguardando Intervalo · $passou min desde $intervaloStr',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _corJornada(String status) {
    switch (status) {
      case 'encerrado':
        return AppColors.textSecondary;
      case 'intervalo':
        return AppColors.statusCafe;
      default:
        return AppColors.statusAtivo;
    }
  }
}

// ─────────────────────────────────────────────
// Seção "Sobre este Caixa"
// ─────────────────────────────────────────────
class _SobreCaixaSection extends StatefulWidget {
  final Caixa caixa;
  final List<Ocorrencia> ocorrencias;
  final BuildContext providerContext;

  const _SobreCaixaSection({
    required this.caixa,
    required this.ocorrencias,
    required this.providerContext,
  });

  @override
  State<_SobreCaixaSection> createState() => _SobreCaixaSectionState();
}

class _SobreCaixaSectionState extends State<_SobreCaixaSection> {
  bool _expandidoOcorrencias = false;

  @override
  Widget build(BuildContext context) {
    final temObservacoes = widget.caixa.observacoes?.isNotEmpty == true;
    final ocorrenciasAbertas =
        widget.ocorrencias.where((o) => !o.resolvida).toList();
    final ocorrenciasResolvidas =
        widget.ocorrencias.where((o) => o.resolvida).toList();
    final ocorrenciasVisiveis = _expandidoOcorrencias
        ? widget.ocorrencias
        : widget.ocorrencias.take(3).toList();

    // Se não há nada para mostrar, não renderiza nada
    if (!temObservacoes && widget.ocorrencias.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label da seção
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'SOBRE ESTE CAIXA',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),

        // ── Observações ───────────────────────────────────────────────────
        if (temObservacoes)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSection,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.caixa.observacoes!,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),

        // ── Ocorrências vinculadas ────────────────────────────────────────
        if (widget.ocorrencias.isNotEmpty) ...[
          // Contador resumo
          Row(
            children: [
              const Icon(Icons.report_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${widget.ocorrencias.length} ocorrência(s)',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (ocorrenciasAbertas.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${ocorrenciasAbertas.length} aberta(s)',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              if (ocorrenciasResolvidas.isNotEmpty &&
                  ocorrenciasAbertas.isEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'todas resolvidas',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Lista compacta de ocorrências
          ...ocorrenciasVisiveis.map((o) => _OcorrenciaRow(ocorrencia: o)),

          // Botão "Ver mais / menos"
          if (widget.ocorrencias.length > 3)
            GestureDetector(
              onTap: () =>
                  setState(() => _expandidoOcorrencias = !_expandidoOcorrencias),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _expandidoOcorrencias
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    Text(
                      _expandidoOcorrencias
                          ? 'Ver menos'
                          : 'Ver todas (${widget.ocorrencias.length})',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],

        const Divider(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Linha compacta de ocorrência
// ─────────────────────────────────────────────
class _OcorrenciaRow extends StatelessWidget {
  final Ocorrencia ocorrencia;

  const _OcorrenciaRow({required this.ocorrencia});

  @override
  Widget build(BuildContext context) {
    final cor = ocorrencia.gravidade.cor;
    final timeFmt = '${ocorrencia.registradaEm.day.toString().padLeft(2, '0')}/'
        '${ocorrencia.registradaEm.month.toString().padLeft(2, '0')} '
        '${ocorrencia.registradaEm.hour.toString().padLeft(2, '0')}:'
        '${ocorrencia.registradaEm.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gravidade dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ocorrencia.tipo,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cor,
                        ),
                      ),
                    ),
                    Text(
                      timeFmt,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (ocorrencia.descricao.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ocorrencia.descricao,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Badge resolvida/aberta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: ocorrencia.resolvida
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              ocorrencia.resolvida ? 'resolvida' : 'aberta',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: ocorrencia.resolvida
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Badge de status da jornada
// ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'trabalhando' => ('Trabalhando', AppColors.statusAtivo, Icons.work),
      'intervalo' => ('Em Intervalo', AppColors.statusCafe, Icons.coffee),
      'encerrado' => (
          'Jornada Encerrada',
          AppColors.textSecondary,
          Icons.check_circle
        ),
      _ => ('Sem Ponto', AppColors.inactive, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Linha de informação com ícone
// ─────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.caption),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Grid 2×2 com horários da escala de hoje
// ─────────────────────────────────────────────
class HorarioGrid extends StatelessWidget {
  final TurnoLocal turno;

  const HorarioGrid({super.key, required this.turno});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3,
      children: [
        HorarioChip(icon: Icons.login, label: 'Entrada', value: turno.entrada),
        HorarioChip(
            icon: Icons.free_breakfast,
            label: 'Intervalo',
            value: turno.intervalo),
        HorarioChip(
            icon: Icons.replay, label: 'Retorno', value: turno.retorno),
        HorarioChip(icon: Icons.logout, label: 'Saída', value: turno.saida),
      ],
    );
  }
}

class HorarioChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const HorarioChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textSecondary),
                ),
                Text(
                  value ?? '--:--',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: value != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
