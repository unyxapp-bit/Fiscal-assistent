// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/entities/registro_ponto.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/pacote_plantao_provider.dart';
import '../../../providers/registro_ponto_provider.dart';
import '../../../../data/services/notification_service.dart';
import 'colaborador_detalhes_sheet.dart'
    show JornadaResult, StatusBadge, InfoRow, HorarioGrid;
import '../../../providers/escala_provider.dart' show TurnoLocal;
import '../../../../core/utils/app_notif.dart';

const Color _kPacoteColor = Color(0xFF795548);

/// Sheet de detalhes para empacotadores do plantÃƒÂ£o do dia
class PacoteDetalhesSheet extends StatefulWidget {
  final Colaborador colaborador;
  final String plantaoId;
  final TurnoLocal? turno;
  final dynamic pausa;
  final BuildContext providerContext;

  const PacoteDetalhesSheet({
    super.key,
    required this.colaborador,
    required this.plantaoId,
    required this.turno,
    required this.pausa,
    required this.providerContext,
  });

  @override
  State<PacoteDetalhesSheet> createState() => _PacoteDetalhesSheetState();
}

class _PacoteDetalhesSheetState extends State<PacoteDetalhesSheet> {
  RegistroPonto? _registroHoje;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarRegistro());
  }

  Future<void> _carregarRegistro() async {
    setState(() => _carregando = true);
    try {
      final provider = Provider.of<RegistroPontoProvider>(
          widget.providerContext,
          listen: false);
      await provider.loadRegistros(widget.colaborador.id);

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
    if (r == null || r.entrada == null || r.entrada!.isEmpty) {
      return JornadaResult.semPonto();
    }

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

  @override
  Widget build(BuildContext context) {
    final jornada = _calcJornada();

    return Padding(
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

          // CabeÃƒÂ§alho Ã¢â‚¬â€ seÃƒÂ§ÃƒÂ£o Pacotes
          Row(
            children: [
              Icon(Icons.shopping_bag, color: _kPacoteColor, size: 22),
              SizedBox(width: 8),
              Text('Pacotes', style: AppTextStyles.h2),
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPacoteColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PlantÃƒÂ£o do dia',
                  style: AppTextStyles.caption.copyWith(color: _kPacoteColor),
                ),
              ),
            ],
          ),

          Divider(height: 24),

          // Avatar + nome + departamento
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _kPacoteColor,
                child: Text(
                  widget.colaborador.iniciais,
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
                    Text(widget.colaborador.nome, style: AppTextStyles.h4),
                    Text(
                      widget.colaborador.departamento.nome,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Alerta de pausa de cafÃƒÂ©
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
                    'Em pausa de cafÃƒÂ© Ã¢â‚¬â€ ${widget.pausa.minutosDecorridos}min decorridos'
                    '${widget.pausa.emAtraso ? ' (${widget.pausa.minutosExcedidos}min em atraso)' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Jornada
          if (_carregando)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Carregando ponto...'),
                ],
              ),
            )
          else if (jornada.status == 'sem_ponto')
            InfoRow(
              icon: Icons.access_time,
              label: 'PlantÃƒÂ£o iniciado',
              value: 'Sem registro de ponto hoje',
              iconColor: AppColors.textSecondary,
            )
          else ...[
            InfoRow(
              icon: Icons.fingerprint,
              label: 'Ativo desde',
              value: '${jornada.entrada} (ponto)',
              iconColor: AppColors.primary,
            ),
            SizedBox(height: 6),
            InfoRow(
              icon: Icons.timer_outlined,
              label: 'Jornada lÃƒÂ­quida',
              value: _formatDuracao(jornada.liquida),
              iconColor: _corJornada(jornada.status),
            ),
            SizedBox(height: 6),
            StatusBadge(status: jornada.status),
          ],

          SizedBox(height: 12),

          if (widget.turno != null) ...[
            Text('Escala de hoje', style: AppTextStyles.label),
            SizedBox(height: 8),
            HorarioGrid(turno: widget.turno!),
          ],

          SizedBox(height: 20),

          // Ã¢â€â‚¬Ã¢â€â‚¬ AÃƒâ€¡Ãƒâ€¢ES RÃƒÂPIDAS Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
                  'AÃƒâ€¡Ãƒâ€¢ES RÃƒÂPIDAS',
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
                        icon: Icons.coffee,
                        label: 'CafÃƒÂ©',
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
                Builder(builder: (context) {
                  final cafeProvider = Provider.of<CafeProvider>(
                    widget.providerContext,
                    listen: false,
                  );
                  if (cafeProvider.colaboradorEmPausa(widget.colaborador.id)) {
                    return const SizedBox.shrink();
                  }
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
                  if (cafeProvider
                      .colaboradorJaFezIntervaloHoje(widget.colaborador.id)) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _marcarIntervaloJaFeito,
                      icon: Icon(Icons.check_circle_outline, size: 18),
                      label: Text('Intervalo jÃƒÂ¡ feito'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade700),
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
              final plantaoProvider = Provider.of<PacotePlantaoProvider>(
                  widget.providerContext,
                  listen: false);
              Navigator.of(context).pop();
              await plantaoProvider.remover(widget.plantaoId);
            },
            icon: Icon(Icons.remove_circle_outline),
            label: Text('Remover do plantÃƒÂ£o'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
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

  Future<void> _enviarParaCafe() async {
    final providerCtx = widget.providerContext;
    final cafeProvider = Provider.of<CafeProvider>(providerCtx, listen: false);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enviar para CafÃƒÂ© Ã¢Ëœâ€¢'),
        content:
            Text('Enviar ${widget.colaborador.nome} para 10 min de cafÃƒÂ©?'),
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

    cafeProvider.iniciarPausa(
      colaboradorId: widget.colaborador.id,
      colaboradorNome: widget.colaborador.nome,
      duracaoMinutos: 10,
    );

    if (mounted) {
      navigator.pop();
      AppNotif.show(
        providerCtx,
        titulo: 'CafÃƒÂ© Iniciado',
        mensagem:
            '${widget.colaborador.nome} Ã¢â‚¬â€ pausa de cafÃƒÂ© iniciada (10 min)',
        tipo: 'cafe',
        cor: const Color(0xFF8D6E63),
      );
    }
  }

  Future<void> _enviarParaIntervalo() async {
    final duracaoMinutos = _calcularDuracaoIntervalo();

    final providerCtx = widget.providerContext;
    final navigator = Navigator.of(context);
    final cafeProvider = Provider.of<CafeProvider>(providerCtx, listen: false);

    if (cafeProvider.colaboradorJaFezIntervaloHoje(widget.colaborador.id)) {
      AppNotif.show(
        providerCtx,
        titulo: 'Intervalo jÃƒÂ¡ realizado',
        mensagem:
            'Este colaborador jÃƒÂ¡ fez o intervalo hoje. DisponÃƒÂ­vel somente para cafÃƒÂ© (10 min).',
        tipo: 'intervalo',
        cor: Colors.orange,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enviar para Intervalo Ã°Å¸ÂÂ½Ã¯Â¸Â'),
        content: Text(
            'Enviar ${widget.colaborador.nome} para intervalo de $duracaoMinutos min?\nUma notificaÃƒÂ§ÃƒÂ£o de retorno serÃƒÂ¡ agendada.'),
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

    cafeProvider.iniciarPausa(
      colaboradorId: widget.colaborador.id,
      colaboradorNome: widget.colaborador.nome,
      duracaoMinutos: duracaoMinutos,
    );

    final retornoEm = DateTime.now().add(Duration(minutes: duracaoMinutos));
    NotificationService.instance.scheduleAlert(
      id: (widget.colaborador.id.hashCode.abs() % 100000) + 1,
      title: 'Intervalo encerrado Ã°Å¸ÂÂ½Ã¯Â¸Â',
      body:
          '${widget.colaborador.nome} deve ser realocado(a) apos o intervalo.',
      scheduledAt: retornoEm,
    );

    if (mounted) {
      navigator.pop();
      AppNotif.show(
        providerCtx,
        titulo: 'Intervalo Iniciado',
        mensagem:
            '${widget.colaborador.nome} Ã¢â‚¬â€ intervalo de $duracaoMinutos min. NotificaÃƒÂ§ÃƒÂ£o agendada.',
        tipo: 'intervalo',
        cor: Colors.orange,
      );
    }
  }

  int _calcularDuracaoIntervalo() {
    int duracaoMinutos = 60;
    if (widget.turno == null) return duracaoMinutos;

    final t = widget.turno!;
    if (t.intervalo == null || t.retorno == null) return duracaoMinutos;

    final p1 = t.intervalo!.split(':');
    final p2 = t.retorno!.split(':');
    if (p1.length != 2 || p2.length != 2) return duracaoMinutos;

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
    return duracaoMinutos;
  }

  DateTime? _inicioIntervaloEscalaHoje() {
    final intervalo = widget.turno?.intervalo;
    if (intervalo == null) return null;
    final parts = intervalo.split(':');
    if (parts.length < 2) return null;

    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  Future<void> _marcarIntervaloJaFeito() async {
    final providerCtx = widget.providerContext;
    final cafeProvider = Provider.of<CafeProvider>(providerCtx, listen: false);

    if (cafeProvider.colaboradorJaFezIntervaloHoje(widget.colaborador.id)) {
      AppNotif.show(
        providerCtx,
        titulo: 'Intervalo jÃƒÂ¡ registrado',
        mensagem: '${widget.colaborador.nome} jÃƒÂ¡ possui intervalo hoje.',
        tipo: 'intervalo',
        cor: Colors.orange,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Intervalo jÃƒÂ¡ feito?'),
        content: Text(
          'Confirmar que ${widget.colaborador.nome} jÃƒÂ¡ realizou o intervalo?',
        ),
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

    final duracaoMinutos = _calcularDuracaoIntervalo();
    final now = DateTime.now();
    final inicioEscala = _inicioIntervaloEscalaHoje();
    final inicioRegistro = (inicioEscala != null && inicioEscala.isBefore(now))
        ? inicioEscala
        : now.subtract(Duration(minutes: duracaoMinutos));

    cafeProvider.iniciarPausa(
      colaboradorId: widget.colaborador.id,
      colaboradorNome: widget.colaborador.nome,
      duracaoMinutos: duracaoMinutos,
      iniciadoEm: inicioRegistro,
    );
    cafeProvider.finalizarPausa(widget.colaborador.id);

    if (!mounted) return;
    setState(() {});
    AppNotif.show(
      providerCtx,
      titulo: 'Intervalo registrado',
      mensagem:
          '${widget.colaborador.nome} foi marcado(a) com intervalo feito.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }
}
