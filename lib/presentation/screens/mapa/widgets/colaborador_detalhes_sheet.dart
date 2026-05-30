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
import '../../ocorrencias/ocorrencia_form_screen.dart';
import '../../../../data/services/notification_service.dart';
import '../../../providers/ocorrencia_provider.dart';
import '../../../../core/utils/app_notif.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Resultado do cálculo de jornada
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Bottom sheet com carregamento de registro_ponto
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  bool _mostrarEscala = false;

  @override
  void initState() {
    super.initState();
    if (widget.colaborador != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _carregarRegistro());
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
        listen: false,
      );
      await provider.loadRegistros(widget.colaborador!.id);

      if (!mounted) return;

      final now = DateTime.now();
      final registro = provider.registros
          .where(
            (r) =>
                r.data.year == now.year &&
                r.data.month == now.month &&
                r.data.day == now.day,
          )
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

  Widget _buildOperacaoDashboard(JornadaResult jornada) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final largura = constraints.maxWidth;
        final usarDuasColunas = largura >= 420;
        final larguraCard = usarDuasColunas ? (largura - gap) / 2 : largura;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(width: larguraCard, child: _buildAtivoDesdeCard(jornada)),
            SizedBox(width: larguraCard, child: _buildJornadaCard(jornada)),
            SizedBox(width: larguraCard, child: _buildIntervaloCard(jornada)),
            SizedBox(width: larguraCard, child: _buildAtrasoCard()),
          ],
        );
      },
    );
  }

  Widget _buildAtivoDesdeCard(JornadaResult jornada) {
    late final String valor;
    late final String detalhe;
    late final IconData icone;
    late final Color cor;

    if (_carregando) {
      valor = '--';
      detalhe = 'Carregando ponto';
      icone = Icons.sync;
      cor = AppColors.textSecondary;
    } else if (jornada.status == 'sem_ponto') {
      final alocadoEm = widget.alocacao?.alocadoEm;
      if (alocadoEm != null) {
        valor =
            '${alocadoEm.hour.toString().padLeft(2, '0')}:'
            '${alocadoEm.minute.toString().padLeft(2, '0')}';
        detalhe = 'pela alocação';
        icone = Icons.access_time;
        cor = AppColors.textSecondary;
      } else {
        valor = 'Sem ponto';
        detalhe = 'sem registro de hoje';
        icone = Icons.event_busy;
        cor = AppColors.textSecondary;
      }
    } else if (jornada.status == 'escala') {
      valor = jornada.entrada ?? '--';
      detalhe = 'baseado na escala';
      icone = Icons.schedule;
      cor = AppColors.statusAtencao;
    } else {
      valor = jornada.entrada ?? '--';
      detalhe = 'registro de ponto';
      icone = Icons.fingerprint;
      cor = AppColors.primary;
    }

    return _DashboardInfoCard(
      titulo: 'Ativo desde',
      valor: valor,
      detalhe: detalhe,
      icone: icone,
      cor: cor,
    );
  }

  Widget _buildJornadaCard(JornadaResult jornada) {
    late final String titulo;
    late final String valor;
    late final String detalhe;
    late final IconData icone;
    late final Color cor;

    if (_carregando) {
      titulo = 'Jornada líquida';
      valor = '--';
      detalhe = 'Aguardando cálculo';
      icone = Icons.timer_outlined;
      cor = AppColors.textSecondary;
    } else if (jornada.status == 'sem_ponto') {
      titulo = 'Jornada líquida';
      valor = 'Sem ponto';
      detalhe = 'sem registro de hoje';
      icone = Icons.timer_off_outlined;
      cor = AppColors.textSecondary;
    } else if (jornada.status == 'escala') {
      titulo = 'Jornada estimada';
      valor = _formatDuracao(jornada.liquida);
      detalhe = 'estimada pela escala';
      icone = Icons.timelapse_outlined;
      cor = AppColors.statusAtencao;
    } else {
      titulo = 'Jornada líquida';
      valor = _formatDuracao(jornada.liquida);
      detalhe = _statusResumo(jornada.status);
      icone = Icons.timer_outlined;
      cor = _corJornada(jornada.status);
    }

    return _DashboardInfoCard(
      titulo: titulo,
      valor: valor,
      detalhe: detalhe,
      icone: icone,
      cor: cor,
    );
  }

  Widget _buildIntervaloCard(JornadaResult jornada) {
    final colaborador = widget.colaborador;
    late final String valor;
    late final String detalhe;
    late final IconData icone;
    late final Color cor;

    if (colaborador == null) {
      valor = '--';
      detalhe = 'sem colaborador';
      icone = Icons.event_busy;
      cor = AppColors.textSecondary;
    } else {
      final cafeProvider = Provider.of<CafeProvider>(
        widget.providerContext,
        listen: false,
      );

      if (cafeProvider.colaboradorEmPausa(colaborador.id)) {
        final minutos = widget.pausa?.minutosDecorridos;
        valor = minutos != null ? '$minutos min' : 'Em café';
        detalhe = minutos != null ? 'pausa ativa no café' : 'pausa ativa';
        icone = Icons.coffee;
        cor = AppColors.statusCafe;
      } else if (widget.alocacaoProvider.isIntervaloMarcado(colaborador.id) ||
          cafeProvider.colaboradorJaFezIntervaloHoje(colaborador.id)) {
        valor = 'Concluído';
        detalhe = 'intervalo já registrado';
        icone = Icons.check_circle;
        cor = AppColors.success;
      } else {
        final intervaloStr =
            _registroHoje?.intervaloSaida ?? widget.turno?.intervalo;
        if (intervaloStr == null || intervaloStr.isEmpty) {
          valor = 'Sem horário';
          detalhe = 'nenhum intervalo previsto';
          icone = Icons.event_busy;
          cor = AppColors.textSecondary;
        } else {
          final parts = intervaloStr.split(':');
          final h = parts.length >= 2 ? int.tryParse(parts[0]) : null;
          final m = parts.length >= 2 ? int.tryParse(parts[1]) : null;

          if (h == null || m == null) {
            valor = 'Sem horário';
            detalhe = 'intervalo inválido';
            icone = Icons.event_busy;
            cor = AppColors.textSecondary;
          } else {
            final now = DateTime.now();
            final intervaloTime = DateTime(now.year, now.month, now.day, h, m);
            final diff = intervaloTime.difference(now);

            if (diff.inSeconds > 0) {
              final minutos = diff.inMinutes;
              valor = minutos > 0 ? '$minutos min' : '< 1 min';
              detalhe = 'para o intervalo ($intervaloStr)';
              icone = Icons.hourglass_top;
              cor = AppColors.primary;
            } else {
              final passou = diff.inMinutes.abs();
              valor = passou == 0 ? 'Agora' : '$passou min';
              detalhe = passou == 0
                  ? 'horário do intervalo ($intervaloStr)'
                  : 'aguardando desde $intervaloStr';
              icone = Icons.schedule;
              cor = AppColors.warning;
            }
          }
        }
      }
    }

    return _DashboardInfoCard(
      titulo: 'Intervalo',
      valor: valor,
      detalhe: detalhe,
      icone: icone,
      cor: cor,
      trailing: StatusBadge(status: jornada.status),
    );
  }

  Widget _buildAtrasoCard() {
    late final String valor;
    late final String detalhe;
    late final IconData icone;
    late final Color cor;

    if (widget.pausa != null && widget.pausa.emAtraso == true) {
      valor = '${widget.pausa.minutosExcedidos} min';
      detalhe = 'retorno atrasado';
      icone = Icons.timer_off_outlined;
      cor = AppColors.danger;
    } else {
      final atraso = _intervaloAtrasoMinutos();
      if (atraso > 0) {
        valor = '$atraso min';
        detalhe = atraso >= 30 ? 'prioridade alta' : 'precisa liberar';
        icone = Icons.priority_high_rounded;
        cor = atraso >= 30 ? AppColors.danger : AppColors.warning;
      } else {
        valor = 'Sem atraso';
        detalhe = 'dentro do previsto';
        icone = Icons.check_circle_outline_rounded;
        cor = AppColors.success;
      }
    }

    return _DashboardInfoCard(
      titulo: 'Atraso',
      valor: valor,
      detalhe: detalhe,
      icone: icone,
      cor: cor,
    );
  }

  String _statusResumo(String status) {
    switch (status) {
      case 'trabalhando':
        return 'em atividade';
      case 'intervalo':
        return 'em pausa';
      case 'encerrado':
        return 'jornada encerrada';
      default:
        return 'sem ponto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final jornada = _calcJornada();
    final ocorrenciasCaixa =
        Provider.of<OcorrenciaProvider>(
            widget.providerContext,
            listen: false,
          ).todas.where((o) => o.caixaId == widget.caixa.id).toList()
          ..sort((a, b) => b.registradaEm.compareTo(a.registradaEm));
    final eventosDoContexto = _eventosDoContexto();
    final status = _modalStatus(jornada);
    final alerta = _alertaOperacional(ocorrenciasCaixa);
    final proximaAcao = _proximaAcao();

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                _buildOperationalHeader(status, jornada),
                const SizedBox(height: 16),
                _SobreCaixaSection(
                  caixa: widget.caixa,
                  ocorrencias: ocorrenciasCaixa,
                  providerContext: widget.providerContext,
                ),
                if (widget.colaborador != null) ...[
                  _buildOperacaoDashboard(jornada),
                  const SizedBox(height: 16),
                  _buildTimeline(eventosDoContexto),
                  if (alerta != null) ...[
                    const SizedBox(height: 16),
                    _buildAlertCard(alerta),
                  ],
                  const SizedBox(height: 16),
                  _buildNextActionCard(proximaAcao),
                  if (widget.turno != null) ...[
                    const SizedBox(height: 12),
                    _buildEscalaToggle(),
                  ],
                  if (widget.alocacao != null) ...[
                    const SizedBox(height: 16),
                    _buildQuickActionsPanel(),
                    const SizedBox(height: 16),
                    _buildPrimaryButton(),
                  ] else if (widget.pausa != null) ...[
                    const SizedBox(height: 16),
                    _buildPausedNotice(),
                  ],
                  const SizedBox(height: 16),
                  _buildHistoricoExpansivel(eventosDoContexto),
                ] else ...[
                  _buildCaixaLivreState(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€ Botão de ação compacto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<EventoTurno> _eventosDoContexto() {
    final eventoProvider = Provider.of<EventoTurnoProvider>(
      widget.providerContext,
      listen: false,
    );
    final colaboradorNome = widget.colaborador?.nome;
    final eventos = eventoProvider.eventos.where((evento) {
      final mesmoCaixa = evento.caixaNome == widget.caixa.nomeExibicao;
      final mesmoColaborador =
          colaboradorNome != null && evento.colaboradorNome == colaboradorNome;
      return mesmoCaixa || mesmoColaborador;
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return eventos;
  }

  bool _temEventoTermo(List<EventoTurno> eventos, String termo) {
    final needle = termo.toLowerCase();
    return eventos.any((evento) {
      final texto = [
        evento.tipo.label,
        evento.colaboradorNome,
        evento.caixaNome,
        evento.detalhe,
      ].whereType<String>().join(' ').toLowerCase();
      return texto.contains(needle);
    });
  }

  bool _jaFezIntervalo() {
    final colaborador = widget.colaborador;
    if (colaborador == null) return false;
    final cafeProvider = Provider.of<CafeProvider>(
      widget.providerContext,
      listen: false,
    );
    return widget.alocacaoProvider.isIntervaloMarcado(colaborador.id) ||
        cafeProvider.colaboradorJaFezIntervaloHoje(colaborador.id);
  }

  bool _estaAguardandoIntervalo() {
    final colaborador = widget.colaborador;
    if (colaborador == null) return false;
    return widget.alocacaoProvider.isAguardandoIntervalo(colaborador.id);
  }

  String? _intervaloPrevisto() {
    final registro = _registroHoje?.intervaloSaida;
    if (registro != null && registro.isNotEmpty) return registro;
    final escala = widget.turno?.intervalo;
    if (escala != null && escala.isNotEmpty) return escala;
    return null;
  }

  DateTime? _parseHorarioHoje(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  int _intervaloAtrasoMinutos() {
    if (widget.colaborador == null ||
        widget.pausa != null ||
        _jaFezIntervalo()) {
      return 0;
    }
    final horario = _parseHorarioHoje(_intervaloPrevisto());
    if (horario == null) return 0;
    final atraso = DateTime.now().difference(horario).inMinutes;
    return atraso > 0 ? atraso : 0;
  }

  int? _minutosParaIntervalo() {
    if (widget.colaborador == null ||
        widget.pausa != null ||
        _jaFezIntervalo()) {
      return null;
    }
    final horario = _parseHorarioHoje(_intervaloPrevisto());
    if (horario == null) return null;
    return horario.difference(DateTime.now()).inMinutes;
  }

  String _tempoOperacional(JornadaResult jornada) {
    if (jornada.liquida.inMinutes > 0) {
      return 'Há ${_formatDuracao(jornada.liquida)}';
    }
    final alocadoEm = widget.alocacao?.alocadoEm;
    if (alocadoEm == null) return 'Sem jornada ativa';
    final duracao = DateTime.now().difference(alocadoEm);
    return 'Há ${_formatDuracao(duracao.isNegative ? Duration.zero : duracao)}';
  }

  _ModalStatusInfo _modalStatus(JornadaResult jornada) {
    if (widget.caixa.emManutencao) {
      return _ModalStatusInfo(
        label: 'Bloqueado',
        detail: 'Caixa em manutenção',
        icon: Icons.build_circle_outlined,
        color: AppColors.statusAtencao,
      );
    }
    if (!widget.caixa.ativo) {
      return _ModalStatusInfo(
        label: 'Inativo',
        detail: 'Fora da operação',
        icon: Icons.pause_circle_outline,
        color: AppColors.inactive,
      );
    }
    if (widget.colaborador == null) {
      return _ModalStatusInfo(
        label: 'Livre',
        detail: 'Pronto para alocação',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      );
    }
    if (widget.pausa != null) {
      final atrasado = widget.pausa.emAtraso == true;
      return _ModalStatusInfo(
        label: atrasado ? 'Atrasado' : 'Em pausa',
        detail: atrasado
            ? '${widget.pausa.minutosExcedidos}min em atraso'
            : '${widget.pausa.minutosDecorridos}min decorridos',
        icon: atrasado ? Icons.timer_off_outlined : Icons.coffee_outlined,
        color: atrasado ? AppColors.danger : AppColors.statusCafe,
      );
    }
    if (_estaAguardandoIntervalo()) {
      return _ModalStatusInfo(
        label: 'Deve sair',
        detail: 'Aguardando liberação',
        icon: Icons.pending_actions_outlined,
        color: AppColors.warning,
      );
    }
    final atraso = _intervaloAtrasoMinutos();
    if (atraso > 0) {
      return _ModalStatusInfo(
        label: atraso >= 30 ? 'Crítico' : 'Atenção',
        detail: 'Intervalo atrasado em ${atraso}min',
        icon: Icons.priority_high_rounded,
        color: atraso >= 30 ? AppColors.danger : AppColors.warning,
      );
    }
    if (_jaFezIntervalo()) {
      return _ModalStatusInfo(
        label: 'Trabalhando',
        detail: 'Intervalo registrado',
        icon: Icons.verified_outlined,
        color: AppColors.success,
      );
    }
    return _ModalStatusInfo(
      label: 'Trabalhando',
      detail: _tempoOperacional(jornada),
      icon: Icons.point_of_sale_rounded,
      color: AppColors.statusAtivo,
    );
  }

  _OperationalAlert? _alertaOperacional(List<Ocorrencia> ocorrenciasCaixa) {
    if (widget.pausa != null && widget.pausa.emAtraso == true) {
      return _OperationalAlert(
        title: 'Retorno atrasado',
        message:
            '${widget.colaborador!.nome} passou ${widget.pausa.minutosExcedidos}min do tempo previsto.',
        action: 'Acompanhe o retorno antes de nova alocação.',
        icon: Icons.timer_off_outlined,
        color: AppColors.danger,
      );
    }
    final atraso = _intervaloAtrasoMinutos();
    if (atraso > 0) {
      return _OperationalAlert(
        title: atraso >= 30 ? 'Ação crítica' : 'Atenção',
        message: 'Intervalo atrasado em ${atraso}min.',
        action: 'Ação recomendada: liberar operador para intervalo.',
        icon: Icons.warning_amber_rounded,
        color: atraso >= 30 ? AppColors.danger : AppColors.warning,
      );
    }
    if (_estaAguardandoIntervalo()) {
      return _OperationalAlert(
        title: 'Pendente',
        message: 'Operador marcado como aguardando liberação.',
        action: 'Confirme a troca ou libere o intervalo.',
        icon: Icons.pending_actions_outlined,
        color: AppColors.warning,
      );
    }
    final abertas = ocorrenciasCaixa.where((o) => !o.resolvida).length;
    if (abertas > 0) {
      return _OperationalAlert(
        title: 'Ocorrência aberta',
        message:
            '$abertas ocorrência${abertas == 1 ? '' : 's'} vinculada${abertas == 1 ? '' : 's'} ao caixa.',
        action: 'Revise antes de encerrar a operação.',
        icon: Icons.report_problem_outlined,
        color: AppColors.danger,
      );
    }
    return null;
  }

  _RecommendedAction _proximaAcao() {
    if (widget.colaborador == null) {
      if (widget.caixa.ativo && !widget.caixa.emManutencao) {
        return _RecommendedAction(
          title: 'Alocar colaborador',
          description: 'Caixa livre para receber operador.',
          label: 'Alocar agora',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.primary,
          onTap: _abrirAlocacao,
        );
      }
      return _RecommendedAction(
        title: 'Sem ação disponível',
        description: 'Caixa indisponível para operação.',
        label: 'Bloqueado',
        icon: Icons.block_rounded,
        color: AppColors.inactive,
      );
    }
    if (widget.pausa != null) {
      return _RecommendedAction(
        title: widget.pausa.emAtraso == true
            ? 'Priorizar retorno'
            : 'Acompanhar pausa',
        description: widget.pausa.emAtraso == true
            ? 'O tempo previsto já foi excedido.'
            : 'Ações de troca e liberação voltam após nova alocação.',
        label: 'Em acompanhamento',
        icon: widget.pausa.emAtraso == true
            ? Icons.timer_off_outlined
            : Icons.coffee_outlined,
        color: widget.pausa.emAtraso == true
            ? AppColors.danger
            : AppColors.statusCafe,
      );
    }
    if (widget.alocacao == null) {
      return _RecommendedAction(
        title: 'Aguardando alocação',
        description: 'Operador não está em caixa ativo neste momento.',
        label: 'Sem ação',
        icon: Icons.info_outline,
        color: AppColors.textSecondary,
      );
    }
    final atraso = _intervaloAtrasoMinutos();
    if (atraso > 0) {
      return _RecommendedAction(
        title: 'Liberar com prioridade',
        description: 'Intervalo atrasado em ${atraso}min.',
        label: 'Liberar intervalo',
        icon: Icons.restaurant_rounded,
        color: atraso >= 30 ? AppColors.danger : AppColors.warning,
        onTap: _enviarParaIntervalo,
      );
    }
    final minutosParaIntervalo = _minutosParaIntervalo();
    if (minutosParaIntervalo != null && minutosParaIntervalo <= 15) {
      return _RecommendedAction(
        title: 'Preparar liberação',
        description: minutosParaIntervalo <= 0
            ? 'Horário de intervalo chegou.'
            : 'Faltam ${minutosParaIntervalo}min para o intervalo.',
        label: 'Liberar intervalo',
        icon: Icons.restaurant_rounded,
        color: AppColors.warning,
        onTap: _enviarParaIntervalo,
      );
    }
    if (!_jaFezIntervalo() && _intervaloPrevisto() != null) {
      return _RecommendedAction(
        title: 'Manter em operação',
        description: 'Próximo intervalo previsto para ${_intervaloPrevisto()}.',
        label: _estaAguardandoIntervalo() ? 'Cancelar espera' : 'Marcar espera',
        icon: Icons.schedule_rounded,
        color: AppColors.primary,
        onTap: _toggleAguardandoIntervalo,
      );
    }
    return _RecommendedAction(
      title: 'Operação estável',
      description: 'Nenhuma ação urgente para este caixa.',
      label: 'Sem ação urgente',
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.success,
    );
  }

  Widget _buildOperationalHeader(
    _ModalStatusInfo status,
    JornadaResult jornada,
  ) {
    final colaborador = widget.colaborador;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            status.color.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(widget.caixa.tipo.icone, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.caixa.nomeExibicao.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      colaborador?.nome.toUpperCase() ?? 'CAIXA SEM OPERADOR',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      colaborador?.departamento.nome ?? widget.caixa.tipo.nome,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(status),
              _buildHeaderPill(
                icon: Icons.timer_outlined,
                label: colaborador == null
                    ? status.detail
                    : _tempoOperacional(jornada),
              ),
              if (widget.caixa.localizacao?.isNotEmpty == true)
                _buildHeaderPill(
                  icon: Icons.location_on_outlined,
                  label: widget.caixa.localizacao!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(_ModalStatusInfo status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            status.label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.86)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<EventoTurno> eventos) {
    final steps = _timelineSteps(eventos);
    return _buildPanel(
      title: 'Timeline operacional',
      icon: Icons.timeline_rounded,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(child: _TimelineStepView(step: steps[i])),
            if (i < steps.length - 1)
              Container(
                width: 18,
                height: 2,
                color: steps[i].done
                    ? AppColors.success.withValues(alpha: 0.45)
                    : AppColors.cardBorder,
              ),
          ],
        ],
      ),
    );
  }

  List<_TimelineStep> _timelineSteps(List<EventoTurno> eventos) {
    final jornada = _calcJornada();
    final temEntrada =
        jornada.status != 'sem_ponto' || widget.alocacao?.alocadoEm != null;
    final sangriaFeita = _temEventoTermo(eventos, 'sangria');
    final intervaloFeito = _jaFezIntervalo();
    final emPausa = widget.pausa != null || jornada.status == 'intervalo';
    final intervaloAtual =
        emPausa || _estaAguardandoIntervalo() || _intervaloAtrasoMinutos() > 0;

    return [
      _TimelineStep(
        label: 'Entrada',
        icon: Icons.login_rounded,
        done: temEntrada,
        current: !temEntrada,
      ),
      _TimelineStep(
        label: 'Sangria',
        icon: Icons.payments_outlined,
        done: sangriaFeita,
      ),
      _TimelineStep(
        label: 'Intervalo',
        icon: Icons.restaurant_rounded,
        done: intervaloFeito,
        current: !intervaloFeito && intervaloAtual,
      ),
      _TimelineStep(
        label: 'Retorno',
        icon: Icons.replay_rounded,
        done: intervaloFeito && !emPausa,
        current: emPausa,
      ),
      _TimelineStep(
        label: 'Saída',
        icon: Icons.logout_rounded,
        done: jornada.status == 'encerrado',
      ),
    ];
  }

  Widget _buildAlertCard(_OperationalAlert alerta) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alerta.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: alerta.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: alerta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(alerta.icon, color: alerta.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.title.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    color: alerta.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(alerta.message, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text(
                  alerta.action,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionCard(_RecommendedAction action) {
    return _buildPanel(
      title: 'Próxima ação recomendada',
      icon: Icons.auto_awesome_rounded,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(action.icon, color: action.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  action.description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: action.onTap,
            style: FilledButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.cardBorder,
              disabledForegroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(action.label),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalaToggle() {
    return _buildPanel(
      title: 'Escala de hoje',
      icon: Icons.schedule_rounded,
      trailing: Icon(
        _mostrarEscala ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        color: AppColors.textSecondary,
      ),
      onTap: () => setState(() => _mostrarEscala = !_mostrarEscala),
      child: _mostrarEscala
          ? HorarioGrid(turno: widget.turno!)
          : Text(
              'Toque para consultar entrada, intervalo, retorno e saída.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
    );
  }

  Widget _buildQuickActionsPanel() {
    final intervalControls = _intervaloControlButtons();
    return _buildPanel(
      title: 'Ações rápidas',
      icon: Icons.touch_app_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.swap_horiz,
                  label: 'Troca',
                  color: Colors.blue,
                  onTap: _trocarColaborador,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.coffee,
                  label: 'Café',
                  color: const Color(0xFF8D6E63),
                  onTap: _enviarParaCafe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.restaurant,
                  label: 'Intervalo',
                  color: Colors.orange,
                  onTap: _enviarParaIntervalo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.report_problem,
                  label: 'Ocorrência',
                  color: AppColors.danger,
                  onTap: _registrarOcorrencia,
                ),
              ),
            ],
          ),
          if (intervalControls.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...intervalControls,
          ],
        ],
      ),
    );
  }

  List<Widget> _intervaloControlButtons() {
    final colaborador = widget.colaborador;
    if (colaborador == null) return const [];

    final buttons = <Widget>[];
    if (_deveMostrarIntervaloJaFeito()) {
      final jaMarcado = widget.alocacaoProvider.isIntervaloMarcado(
        colaborador.id,
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: jaMarcado
              ? _confirmarIntervaloJaRegistrado
              : _marcarIntervaloJaFeito,
          icon: Icon(
            jaMarcado ? Icons.check_circle : Icons.check_circle_outline,
            size: 18,
          ),
          label: Text(
            jaMarcado ? 'Intervalo já registrado' : 'Intervalo já feito',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            side: BorderSide(
              color: jaMarcado ? Colors.green.shade200 : Colors.green.shade700,
            ),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    if (_deveMostrarAguardandoIntervalo()) {
      final aguardando = _estaAguardandoIntervalo();
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 8));
      buttons.add(
        OutlinedButton.icon(
          onPressed: _toggleAguardandoIntervalo,
          icon: Icon(
            aguardando ? Icons.pending_actions : Icons.access_time,
            size: 18,
          ),
          label: Text(
            aguardando
                ? 'Aguardando liberação (toque para cancelar)'
                : 'Aguardando liberação para intervalo',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: aguardando
                ? AppColors.warning
                : AppColors.textSecondary,
            side: BorderSide(
              color: aguardando ? AppColors.warning : AppColors.cardBorder,
            ),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }
    return buttons;
  }

  bool _deveMostrarIntervaloJaFeito() {
    if (widget.colaborador == null || widget.turno?.intervalo == null) {
      return false;
    }
    final parts = widget.turno!.intervalo!.split(':');
    if (parts.length < 2) return false;
    final agora = DateTime.now();
    final agoraMin = agora.hour * 60 + agora.minute;
    final intervaloMin =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    if (agoraMin - intervaloMin <= 0) return false;

    final cafeProvider = Provider.of<CafeProvider>(
      widget.providerContext,
      listen: false,
    );
    return !cafeProvider.colaboradorJaFezIntervaloHoje(widget.colaborador!.id);
  }

  bool _deveMostrarAguardandoIntervalo() {
    final colaborador = widget.colaborador;
    if (colaborador == null) return false;
    final cafeProvider = Provider.of<CafeProvider>(
      widget.providerContext,
      listen: false,
    );
    if (cafeProvider.colaboradorEmPausa(colaborador.id)) return false;
    if (widget.alocacaoProvider.isIntervaloMarcado(colaborador.id)) {
      return false;
    }
    if (cafeProvider.colaboradorJaFezIntervaloHoje(colaborador.id)) {
      return false;
    }
    return true;
  }

  void _confirmarIntervaloJaRegistrado() {
    final colaborador = widget.colaborador;
    if (colaborador == null) return;
    widget.alocacaoProvider.desmarcarAguardandoIntervalo(colaborador.id);
    Navigator.of(context).pop();
  }

  void _toggleAguardandoIntervalo() {
    final colaborador = widget.colaborador;
    if (colaborador == null) return;
    if (_estaAguardandoIntervalo()) {
      widget.alocacaoProvider.desmarcarAguardandoIntervalo(colaborador.id);
      setState(() {});
      return;
    }

    widget.alocacaoProvider.marcarAguardandoIntervalo(colaborador.id);
    final eventoProvider = Provider.of<EventoTurnoProvider>(
      widget.providerContext,
      listen: false,
    );
    final fiscalId =
        Provider.of<AuthProvider>(
          widget.providerContext,
          listen: false,
        ).user?.id ??
        '';
    eventoProvider.registrar(
      fiscalId: fiscalId,
      tipo: TipoEvento.intervaloAguardandoLiberacao,
      colaboradorNome: colaborador.nome,
      caixaNome: widget.caixa.nomeExibicao,
      detalhe: widget.turno?.intervalo != null
          ? 'previsto ${widget.turno!.intervalo}'
          : null,
    );
    setState(() {});
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: _liberarColaborador,
        icon: const Icon(Icons.lock_open_rounded),
        label: Text(widget.liberarLabel.toUpperCase()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _liberarColaborador() async {
    if (widget.alocacao == null) return;
    final providerCtx = widget.providerContext;
    final eventoProvider = Provider.of<EventoTurnoProvider>(
      providerCtx,
      listen: false,
    );
    final fiscalId =
        Provider.of<AuthProvider>(providerCtx, listen: false).user?.id ?? '';
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
  }

  Widget _buildPausedNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusCafe.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusCafe.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.statusCafe, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta pessoa está em pausa no momento. As ações de troca e liberação voltam a aparecer quando houver nova alocação ativa.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaixaLivreState() {
    final title = widget.caixa.emManutencao
        ? 'Caixa em manutenção'
        : !widget.caixa.ativo
        ? 'Caixa inativo'
        : 'Caixa disponível';
    final message = widget.caixa.ativo && !widget.caixa.emManutencao
        ? 'Sem operador alocado. Você pode iniciar uma nova alocação.'
        : 'Este caixa não está disponível para operação agora.';
    return _buildPanel(
      title: title,
      icon: widget.caixa.ativo && !widget.caixa.emManutencao
          ? Icons.check_circle_outline_rounded
          : Icons.block_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (widget.caixa.ativo && !widget.caixa.emManutencao) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _abrirAlocacao,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Alocar colaborador'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _abrirAlocacao() {
    Navigator.of(context).pop();
    final fiscalId =
        Provider.of<AuthProvider>(
          widget.providerContext,
          listen: false,
        ).user?.id ??
        '';
    Navigator.of(widget.providerContext).push(
      MaterialPageRoute(builder: (_) => AlocacaoScreen(fiscalId: fiscalId)),
    );
  }

  Widget _buildHistoricoExpansivel(List<EventoTurno> eventos) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.history_rounded, color: AppColors.primary),
          title: Text(
            'Histórico de hoje',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            eventos.isEmpty
                ? 'Sem eventos registrados neste contexto'
                : '${eventos.length} evento${eventos.length == 1 ? '' : 's'} do turno',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          children: eventos.isEmpty
              ? [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Os eventos aparecerão aqui conforme as ações forem registradas.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ]
              : eventos.take(5).map(_buildHistoricoItem).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoricoItem(EventoTurno evento) {
    final hora =
        '${evento.timestamp.hour.toString().padLeft(2, '0')}:'
        '${evento.timestamp.minute.toString().padLeft(2, '0')}';
    final detalhe = [
      evento.tipo.label,
      if (evento.detalhe?.isNotEmpty == true) evento.detalhe!,
    ].join(' - ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              hora,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detalhe,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: content,
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Trocar Colaborador â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _trocarColaborador() {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(
      widget.providerContext,
      listen: false,
    );
    final cafeProvider = Provider.of<CafeProvider>(
      widget.providerContext,
      listen: false,
    );
    final escalaProvider = Provider.of<EscalaProvider>(
      widget.providerContext,
      listen: false,
    );
    final idsAlocados =
        widget.alocacaoProvider
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
          final saidaMin =
              (int.tryParse(parts[0]) ?? 0) * 60 +
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusSheet),
        ),
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
                  Text('Trocar Colaborador', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Substituto para ${widget.caixa.nomeExibicao}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                            backgroundColor: Colors.blue.withValues(
                              alpha: 0.10,
                            ),
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
                          subtitle: Text(
                            c.departamento.nome,
                            style: AppTextStyles.caption,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                          ),
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

  Future<void> _confirmarTroca(BuildContext sheetCtx, Colaborador novo) async {
    Navigator.pop(sheetCtx);

    final providerCtx = widget.providerContext;
    final authProvider = Provider.of<AuthProvider>(providerCtx, listen: false);
    final eventoProvider = Provider.of<EventoTurnoProvider>(
      providerCtx,
      listen: false,
    );
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Troca'),
        content: Text(
          'Substituir ${widget.colaborador!.nome} por ${novo.nome} no ${widget.caixa.nomeExibicao}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final fiscalId = authProvider.user?.id ?? '';

    await widget.alocacaoProvider.liberarAlocacao(widget.alocacao!.id, 'troca');
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

  // â”€â”€ Café â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _enviarParaCafe() async {
    final providerCtx = widget.providerContext;
    final cafeProvider = Provider.of<CafeProvider>(providerCtx, listen: false);
    final eventoProvider = Provider.of<EventoTurnoProvider>(
      providerCtx,
      listen: false,
    );
    final fiscalId =
        Provider.of<AuthProvider>(providerCtx, listen: false).user?.id ?? '';
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar para Café ☕'),
        content: Text(
          'Enviar ${widget.colaborador!.nome} para 10 min de café?\nO caixa será liberado automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8D6E63),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await widget.alocacaoProvider.liberarAlocacao(widget.alocacao!.id, 'cafe');

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
        mensagem:
            '${widget.colaborador!.nome} — pausa de café iniciada (10 min)',
        tipo: 'cafe',
        cor: const Color(0xFF8D6E63),
      );
    }
  }

  // â”€â”€ Intervalo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _enviarParaIntervalo() async {
    int duracaoMinutos = 60;
    if (widget.turno != null) {
      final t = widget.turno!;
      if (t.intervalo != null && t.retorno != null) {
        final p1 = t.intervalo!.split(':');
        final p2 = t.retorno!.split(':');
        if (p1.length == 2 && p2.length == 2) {
          final ini = Duration(
            hours: int.tryParse(p1[0]) ?? 0,
            minutes: int.tryParse(p1[1]) ?? 0,
          );
          final ret = Duration(
            hours: int.tryParse(p2[0]) ?? 0,
            minutes: int.tryParse(p2[1]) ?? 0,
          );
          final diff = ret - ini;
          if (!diff.isNegative && diff.inMinutes > 0) {
            duracaoMinutos = diff.inMinutes;
          }
        }
      }
    }

    final providerCtx = widget.providerContext;
    final navigator = Navigator.of(context);
    final cafeProviderIntervalo = Provider.of<CafeProvider>(
      providerCtx,
      listen: false,
    );
    final eventoProviderIntervalo = Provider.of<EventoTurnoProvider>(
      providerCtx,
      listen: false,
    );
    final fiscalIdIntervalo =
        Provider.of<AuthProvider>(providerCtx, listen: false).user?.id ?? '';

    final jaFezIntervalo =
        widget.alocacaoProvider.isIntervaloMarcado(widget.colaborador!.id) ||
        cafeProviderIntervalo.colaboradorJaFezIntervaloHoje(
          widget.colaborador!.id,
        );
    if (jaFezIntervalo) {
      AppNotif.show(
        providerCtx,
        titulo: 'Intervalo já realizado',
        mensagem:
            'Este colaborador já fez o intervalo hoje. Disponível somente para café (10 min).',
        tipo: 'intervalo',
        cor: Colors.orange,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar para Intervalo 🍽️'),
        content: Text(
          'Enviar ${widget.colaborador!.nome} para intervalo de $duracaoMinutos min?\nO caixa será liberado e uma notificação de retorno será agendada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await widget.alocacaoProvider.liberarAlocacao(
      widget.alocacao!.id,
      'intervalo',
    );

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

    final retornoEm = DateTime.now().add(Duration(minutes: duracaoMinutos));
    NotificationService.instance.scheduleAlert(
      id: (widget.colaborador!.id.hashCode.abs() % 100000) + 1,
      title: 'Intervalo encerrado 🍽️',
      body:
          '${widget.colaborador!.nome} deve ser realocado(a) apos o intervalo.',
      scheduledAt: retornoEm,
    );

    if (mounted) {
      navigator.pop();
      AppNotif.show(
        providerCtx,
        titulo: 'Intervalo Iniciado',
        mensagem:
            '${widget.colaborador!.nome} — intervalo de $duracaoMinutos min. Notificação agendada.',
        tipo: 'intervalo',
        cor: Colors.orange,
      );
    }
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
    String? motivo;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setStateDialog) {
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
                        motivo = controller.text.trim();
                        Navigator.pop(ctx);
                      },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();
    return motivo;
  }

  Future<void> _marcarIntervaloJaFeito() async {
    if (widget.colaborador == null) return;

    final fezCompleto = await _perguntarSeFezTempoCompleto();
    if (!mounted || fezCompleto == null) return;

    String? motivoIncompleto;
    if (!fezCompleto) {
      motivoIncompleto = await _perguntarMotivoIncompleto();
      if (!mounted || motivoIncompleto == null) return;
    }

    final providerCtx = widget.providerContext;
    final ocorrenciaProvider = Provider.of<OcorrenciaProvider>(
      providerCtx,
      listen: false,
    );
    final eventoProvider = Provider.of<EventoTurnoProvider>(
      providerCtx,
      listen: false,
    );
    final fiscalId =
        Provider.of<AuthProvider>(providerCtx, listen: false).user?.id ?? '';

    if (!fezCompleto) {
      ocorrenciaProvider.registrar(
        tipo: 'Intervalo incompleto',
        caixaId: widget.caixa.id,
        caixaNome: widget.caixa.nomeExibicao,
        colaboradorId: widget.colaborador!.id,
        colaboradorNome: widget.colaborador!.nome,
        descricao: motivoIncompleto!,
        gravidade: GravidadeOcorrencia.media,
      );
      if (eventoProvider.turnoAtivo && fiscalId.isNotEmpty) {
        eventoProvider.registrar(
          fiscalId: fiscalId,
          tipo: TipoEvento.ocorrenciaRegistrada,
          colaboradorNome: widget.colaborador!.nome,
          caixaNome: widget.caixa.nomeExibicao,
          detalhe: 'Intervalo incompleto - Média',
        );
      }
    }

    await widget.alocacaoProvider.marcarIntervaloFeito(widget.colaborador!.id);
    widget.alocacaoProvider.desmarcarAguardandoIntervalo(
      widget.colaborador!.id,
    );

    if (fiscalId.isNotEmpty) {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.intervaloMarcadoFeito,
        colaboradorNome: widget.colaborador!.nome,
        caixaNome: widget.caixa.nomeExibicao,
        detalhe: fezCompleto
            ? 'Marcado manualmente: tempo completo'
            : 'Marcado manualmente: tempo incompleto',
      );
    }

    if (!mounted) return;
    AppNotif.show(
      providerCtx,
      titulo: 'Intervalo atualizado',
      mensagem: fezCompleto
          ? '${widget.colaborador!.nome} foi marcado(a) com intervalo feito.'
          : 'Ocorrência registrada e intervalo marcado como feito.',
      tipo: 'saida',
      cor: AppColors.success,
    );
    Navigator.of(context).pop();
  }

  void _registrarOcorrencia() {
    Navigator.of(context).pop();
    Navigator.of(widget.providerContext).push(
      MaterialPageRoute(
        builder: (_) => OcorrenciaFormScreen(
          caixaId: widget.caixa.id,
          caixaNome: widget.caixa.nomeExibicao,
          colaboradorId: widget.colaborador?.id,
          colaboradorNome: widget.colaborador?.nome,
        ),
      ),
    );
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

class _ModalStatusInfo {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;

  const _ModalStatusInfo({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class _OperationalAlert {
  final String title;
  final String message;
  final String action;
  final IconData icon;
  final Color color;

  const _OperationalAlert({
    required this.title,
    required this.message,
    required this.action,
    required this.icon,
    required this.color,
  });
}

class _RecommendedAction {
  final String title;
  final String description;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _RecommendedAction({
    required this.title,
    required this.description,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final bool done;
  final bool current;

  const _TimelineStep({
    required this.label,
    required this.icon,
    this.done = false,
    this.current = false,
  });
}

class _TimelineStepView extends StatelessWidget {
  final _TimelineStep step;

  const _TimelineStepView({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = step.done
        ? AppColors.success
        : step.current
        ? AppColors.warning
        : AppColors.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: step.done || step.current ? 0.14 : 0.06,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(
                alpha: step.done || step.current ? 0.45 : 0.22,
              ),
              width: step.current ? 2 : 1,
            ),
          ),
          child: Icon(
            step.done ? Icons.check_rounded : step.icon,
            size: 17,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: step.done || step.current
                ? FontWeight.w800
                : FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Seção "Sobre este Caixa"
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    final ocorrenciasAbertas = widget.ocorrencias
        .where((o) => !o.resolvida)
        .toList();
    final ocorrenciasResolvidas = widget.ocorrencias
        .where((o) => o.resolvida)
        .toList();
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

        // â”€â”€ Observações â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
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

        // â”€â”€ Ocorrências vinculadas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (widget.ocorrencias.isNotEmpty) ...[
          // Contador resumo
          Row(
            children: [
              Icon(
                Icons.report_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.ocorrencias.length} ocorrência(s)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (ocorrenciasAbertas.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${ocorrenciasAbertas.length} aberta(s)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (ocorrenciasResolvidas.isNotEmpty &&
                  ocorrenciasAbertas.isEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'todas resolvidas',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
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
              onTap: () => setState(
                () => _expandidoOcorrencias = !_expandidoOcorrencias,
              ),
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
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Linha compacta de ocorrência
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _OcorrenciaRow extends StatelessWidget {
  final Ocorrencia ocorrencia;

  const _OcorrenciaRow({required this.ocorrencia});

  @override
  Widget build(BuildContext context) {
    final cor = ocorrencia.gravidade.cor;
    final timeFmt =
        '${ocorrencia.registradaEm.day.toString().padLeft(2, '0')}/'
        '${ocorrencia.registradaEm.month.toString().padLeft(2, '0')} '
        '${ocorrencia.registradaEm.hour.toString().padLeft(2, '0')}:'
        '${ocorrencia.registradaEm.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gravidade dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
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
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (ocorrencia.descricao.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ocorrencia.descricao,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Badge de status da jornada
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// Card base do dashboard operacional
class _DashboardInfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String detalhe;
  final IconData icone;
  final Color cor;
  final Widget? trailing;

  const _DashboardInfoCard({
    required this.titulo,
    required this.valor,
    required this.detalhe,
    required this.icone,
    required this.cor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 18, color: cor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                Flexible(child: trailing!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detalhe,
            style: AppTextStyles.caption.copyWith(
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
        Icons.check_circle,
      ),
      _ => ('Sem Ponto', AppColors.inactive, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Linha de informação com ícone
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(child: Text(value, style: AppTextStyles.caption)),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Grid 2×2 com horários da escala de hoje
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          value: turno.intervalo,
        ),
        HorarioChip(icon: Icons.replay, label: 'Retorno', value: turno.retorno),
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
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
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
