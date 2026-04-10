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
            SizedBox(
              width: larguraCard,
              child: _buildAtivoDesdeCard(jornada),
            ),
            SizedBox(
              width: larguraCard,
              child: _buildJornadaCard(jornada),
            ),
            SizedBox(
              width: largura,
              child: _buildIntervaloCard(jornada),
            ),
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
        valor = '${alocadoEm.hour.toString().padLeft(2, '0')}:'
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
      final cafeProvider =
          Provider.of<CafeProvider>(widget.providerContext, listen: false);

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
              SizedBox(width: 8),
              Text(widget.caixa.nomeExibicao, style: AppTextStyles.h2),
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.caixa.tipo.cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.caixa.tipo.nome,
                  style: AppTextStyles.caption
                      .copyWith(color: widget.caixa.tipo.cor),
                ),
              ),
              if (widget.caixa.localizacao != null) ...[
                SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSection,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: AppColors.textSecondary),
                      SizedBox(width: 3),
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

          Divider(height: 24),

          // â”€â”€ INFO DO CAIXA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SobreCaixaSection(
            caixa: widget.caixa,
            ocorrencias: ocorrenciasCaixa,
            providerContext: widget.providerContext,
          ),

          if (widget.colaborador != null) ...[
            // Avatar + nome + departamento
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    widget.colaborador!.iniciais,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.colaborador!.nome, style: AppTextStyles.h4),
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

            SizedBox(height: 16),

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
                    Icon(Icons.coffee, color: Colors.orange.shade700, size: 18),
                    SizedBox(width: 8),
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

            _buildOperacaoDashboard(jornada),

            SizedBox(height: 12),
            if (widget.turno != null) ...[
              InkWell(
                onTap: () => setState(() => _mostrarEscala = !_mostrarEscala),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Escala de hoje',
                        style: AppTextStyles.label,
                      ),
                      const Spacer(),
                      Icon(
                        _mostrarEscala
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_mostrarEscala) ...[
                SizedBox(height: 8),
                HorarioGrid(turno: widget.turno!),
              ],
            ],

            if (widget.alocacao != null) ...[
              SizedBox(height: 20),

              // â”€â”€ AÇÕES RÁPIDAS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
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
                    SizedBox(height: 10),
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
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildActionBtn(
                            icon: Icons.coffee,
                            label: 'Café',
                            color: const Color(0xFF8D6E63),
                            onTap: _enviarParaCafe,
                          ),
                        ),
                        SizedBox(width: 8),
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
                    SizedBox(height: 8),
                    Row(
                      children: [
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
                    // â”€â”€ Botão "Intervalo já feito" â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Builder(builder: (context) {
                      if (widget.turno?.intervalo == null) {
                        return const SizedBox.shrink();
                      }
                      final parts = widget.turno!.intervalo!.split(':');
                      if (parts.length < 2) return const SizedBox.shrink();
                      final agora = DateTime.now();
                      final agoraMin = agora.hour * 60 + agora.minute;
                      final intervaloMin = (int.tryParse(parts[0]) ?? 0) * 60 +
                          (int.tryParse(parts[1]) ?? 0);
                      final minPassado = agoraMin - intervaloMin;
                      if (minPassado <= 0) return const SizedBox.shrink();
                      final cafeProvider = Provider.of<CafeProvider>(
                          widget.providerContext,
                          listen: false);
                      if (cafeProvider.colaboradorJaFezIntervaloHoje(
                          widget.colaborador!.id)) {
                        return const SizedBox.shrink();
                      }
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
                              : _marcarIntervaloJaFeito,
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

                    // â”€â”€ Botão "Aguardando liberação para intervalo" â”€â”€â”€â”€â”€â”€â”€â”€
                    Builder(builder: (context) {
                      final cafeProvider = Provider.of<CafeProvider>(
                          widget.providerContext,
                          listen: false);
                      // Não mostrar se já está em pausa ou intervalo marcado
                      if (cafeProvider
                          .colaboradorEmPausa(widget.colaborador!.id)) {
                        return const SizedBox.shrink();
                      }
                      if (widget.alocacaoProvider
                          .isIntervaloMarcado(widget.colaborador!.id)) {
                        return const SizedBox.shrink();
                      }
                      if (cafeProvider.colaboradorJaFezIntervaloHoje(
                          widget.colaborador!.id)) {
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
                                  final fiscalId = Provider.of<AuthProvider>(
                                              widget.providerContext,
                                              listen: false)
                                          .user
                                          ?.id ??
                                      '';
                                  eventoProvider.registrar(
                                    fiscalId: fiscalId,
                                    tipo:
                                        TipoEvento.intervaloAguardandoLiberacao,
                                    colaboradorNome: widget.colaborador!.nome,
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

              SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () async {
                  final providerCtx = widget.providerContext;
                  final eventoProvider = Provider.of<EventoTurnoProvider>(
                      providerCtx,
                      listen: false);
                  final fiscalId =
                      Provider.of<AuthProvider>(providerCtx, listen: false)
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
                icon: Icon(Icons.exit_to_app),
                label: Text(widget.liberarLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ] else if (widget.pausa != null) ...[
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusCafe.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusCafe.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.statusCafe,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta pessoa esta em pausa no momento. As acoes de troca e liberacao voltam a aparecer quando houver nova alocacao ativa.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  final fiscalId = Provider.of<AuthProvider>(
                              widget.providerContext,
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
                icon: Icon(Icons.swap_horiz),
                label: Text('Alocar Colaborador'),
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

  // â”€â”€ Botão de ação compacto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
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

  // â”€â”€ Trocar Colaborador â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _trocarColaborador() {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(widget.providerContext, listen: false);
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
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
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
                  SizedBox(height: 4),
                  Text(
                    'Substituto para ${widget.caixa.nomeExibicao}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: disponiveis.isEmpty
                  ? Center(
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
                                Colors.blue.withValues(alpha: 0.10),
                            child: Text(
                              c.iniciais,
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(c.nome, style: AppTextStyles.body),
                          subtitle: Text(c.departamento.nome,
                              style: AppTextStyles.caption),
                          trailing: Icon(Icons.arrow_forward_ios, size: 14),
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
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(providerCtx, listen: false);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmar Troca'),
        content: Text(
            'Substituir ${widget.colaborador!.nome} por ${novo.nome} no ${widget.caixa.nomeExibicao}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Confirmar', style: TextStyle(color: Colors.white)),
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
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(providerCtx, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(providerCtx, listen: false).user?.id ?? '';
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enviar para Café ☕'),
        content: Text(
            'Enviar ${widget.colaborador!.nome} para 10 min de café?\nO caixa será liberado automaticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63)),
            child: Text('Confirmar', style: TextStyle(color: Colors.white)),
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
        Provider.of<AuthProvider>(providerCtx, listen: false).user?.id ?? '';

    final jaFezIntervalo =
        widget.alocacaoProvider.isIntervaloMarcado(widget.colaborador!.id) ||
            cafeProviderIntervalo
                .colaboradorJaFezIntervaloHoje(widget.colaborador!.id);
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
        title: Text('Enviar para Intervalo 🍽️'),
        content: Text(
            'Enviar ${widget.colaborador!.nome} para intervalo de $duracaoMinutos min?\nO caixa será liberado e uma notificação de retorno será agendada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Confirmar', style: TextStyle(color: Colors.white)),
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
        title: Text('Intervalo já realizado?'),
        content: Text(
          'Esse colaborador fez o tempo completo do intervalo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sim'),
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
            title: Text('Motivo do intervalo incompleto'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Descreva o motivo...',
              ),
              onChanged: (_) => setStateDialog(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: !podeSalvar
                    ? null
                    : () {
                        motivo = controller.text.trim();
                        Navigator.pop(ctx);
                      },
                child: Text('Salvar'),
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
    final ocorrenciaProvider =
        Provider.of<OcorrenciaProvider>(providerCtx, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(providerCtx, listen: false);
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

    await widget.alocacaoProvider.marcarIntervaloFeito(
      widget.colaborador!.id,
    );
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
                Icon(Icons.sticky_note_2_outlined,
                    size: 15, color: AppColors.textSecondary),
                SizedBox(width: 8),
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
              Icon(Icons.report_outlined,
                  size: 14, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text(
                '${widget.ocorrencias.length} ocorrência(s)',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (ocorrenciasAbertas.isNotEmpty) ...[
                SizedBox(width: 6),
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
                SizedBox(width: 6),
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
          SizedBox(height: 6),

          // Lista compacta de ocorrências
          ...ocorrenciasVisiveis.map((o) => _OcorrenciaRow(ocorrencia: o)),

          // Botão "Ver mais / menos"
          if (widget.ocorrencias.length > 3)
            GestureDetector(
              onTap: () => setState(
                  () => _expandidoOcorrencias = !_expandidoOcorrencias),
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

        Divider(height: 20),
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
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
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
                  SizedBox(height: 2),
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
          SizedBox(width: 6),
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
                color:
                    ocorrencia.resolvida ? AppColors.success : AppColors.danger,
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
              SizedBox(width: 10),
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
                SizedBox(width: 10),
                Flexible(child: trailing!),
              ],
            ],
          ),
          SizedBox(height: 12),
          Text(
            valor,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
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
          Icons.check_circle
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
          SizedBox(width: 5),
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

  InfoRow({
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
        SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.caption),
        ),
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
            value: turno.intervalo),
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
          SizedBox(width: 4),
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
