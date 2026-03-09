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
import '../../../providers/registro_ponto_provider.dart';
import '../../alocacao/alocacao_screen.dart';
import '../../../../core/utils/app_notif.dart';

/// Item do grid de caixas
class CaixaGridItem extends StatelessWidget {
  final Caixa caixa;
  final Alocacao? alocacao;

  const CaixaGridItem({
    super.key,
    required this.caixa,
    this.alocacao,
  });

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final escalaProvider = Provider.of<EscalaProvider>(context);
    final cafeProvider = Provider.of<CafeProvider>(context);

    // Buscar colaborador se há alocação
    final colaborador = alocacao != null
        ? colaboradorProvider.colaboradores
            .where((c) => c.id == alocacao!.colaboradorId)
            .firstOrNull
        : null;

    final isOcupado = alocacao != null;
    final isDisponivel = caixa.isDisponivel && !isOcupado;

    return Card(
      color: _getCardColor(isOcupado, isDisponivel),
      child: InkWell(
        onTap: () => _showDetalhes(
          context,
          colaborador,
          alocacaoProvider,
          escalaProvider,
          cafeProvider,
        ),
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Número do caixa
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    caixa.tipo.icone,
                    color: _getIconColor(isOcupado, isDisponivel),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    caixa.nomeExibicao,
                    style: AppTextStyles.h4.copyWith(
                      color: _getTextColor(isOcupado, isDisponivel),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Status
              if (colaborador != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    colaborador.iniciais,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.statusAtivo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  colaborador.nome.split(' ').first,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ] else if (caixa.emManutencao) ...[
                const Icon(
                  Icons.build,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  'Manutenção',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                  ),
                ),
              ] else if (!caixa.ativo) ...[
                const Icon(
                  Icons.power_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  'Inativo',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  'Disponível',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(bool isOcupado, bool isDisponivel) {
    if (caixa.emManutencao) return AppColors.statusAtencao;
    if (!caixa.ativo) return AppColors.inactive;
    if (isOcupado) return AppColors.statusAtivo;
    if (isDisponivel) return AppColors.success;
    return AppColors.inactive;
  }

  Color _getIconColor(bool isOcupado, bool isDisponivel) => Colors.white;
  Color _getTextColor(bool isOcupado, bool isDisponivel) => Colors.white;

  void _showDetalhes(
    BuildContext context,
    Colaborador? colaborador,
    AlocacaoProvider alocacaoProvider,
    EscalaProvider escalaProvider,
    CafeProvider cafeProvider,
  ) {
    final turno = colaborador != null
        ? escalaProvider.turnosHoje
            .where((t) => t.colaboradorId == colaborador.id)
            .firstOrNull
        : null;

    final pausa = colaborador != null
        ? cafeProvider.getPausaAtiva(colaborador.id)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _DetalhesSheet(
        caixa: caixa,
        colaborador: colaborador,
        alocacao: alocacao,
        turno: turno,
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        providerContext: context,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Resultado do cálculo de jornada
// ─────────────────────────────────────────────
class _JornadaResult {
  final String? entrada;       // "HH:mm" da entrada no ponto
  final Duration liquida;      // tempo líquido de trabalho
  final String status;         // 'trabalhando' | 'intervalo' | 'encerrado' | 'sem_ponto'

  const _JornadaResult({
    required this.entrada,
    required this.liquida,
    required this.status,
  });

  factory _JornadaResult.semPonto() => const _JornadaResult(
        entrada: null,
        liquida: Duration.zero,
        status: 'sem_ponto',
      );
}

// ─────────────────────────────────────────────
// Bottom sheet com carregamento de registro_ponto
// ─────────────────────────────────────────────
class _DetalhesSheet extends StatefulWidget {
  final Caixa caixa;
  final Colaborador? colaborador;
  final Alocacao? alocacao;
  final TurnoLocal? turno;
  final dynamic pausa;
  final AlocacaoProvider alocacaoProvider;
  final BuildContext providerContext;

  const _DetalhesSheet({
    required this.caixa,
    required this.colaborador,
    required this.alocacao,
    required this.turno,
    required this.pausa,
    required this.alocacaoProvider,
    required this.providerContext,
  });

  @override
  State<_DetalhesSheet> createState() => _DetalhesSheetState();
}

class _DetalhesSheetState extends State<_DetalhesSheet> {
  RegistroPonto? _registroHoje;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    if (widget.colaborador != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _carregarRegistro());
    }
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
      final registro = provider.registros.where((r) =>
          r.data.year == now.year &&
          r.data.month == now.month &&
          r.data.day == now.day).firstOrNull;

      setState(() {
        _registroHoje = registro;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Calcula a jornada líquida com base no registro de ponto de hoje.
  _JornadaResult _calcJornada() {
    final r = _registroHoje;
    if (r == null || r.entrada == null || r.entrada!.isEmpty) {
      return _JornadaResult.semPonto();
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

    final entrada     = parse(r.entrada)!;
    final intSaida    = parse(r.intervaloSaida);
    final intRetorno  = parse(r.intervaloRetorno);
    final saida       = parse(r.saida);

    // ── Determinar status ──────────────────────────────
    String status;
    DateTime fimCalculo;

    if (saida != null && now.isAfter(saida)) {
      // Jornada já encerrada: trava no horário de saída
      status = 'encerrado';
      fimCalculo = saida;
    } else if (intSaida != null &&
        now.isAfter(intSaida) &&
        (intRetorno == null || now.isBefore(intRetorno))) {
      // Atualmente em intervalo: trava no momento em que saiu para intervalo
      status = 'intervalo';
      fimCalculo = intSaida;
    } else {
      status = 'trabalhando';
      fimCalculo = now;
    }

    // ── Jornada bruta ──────────────────────────────────
    final bruta = fimCalculo.difference(entrada);

    // ── Descontar intervalo COMPLETO (só quando já retornou) ──
    Duration desconto = Duration.zero;
    if (intSaida != null &&
        intRetorno != null &&
        fimCalculo.isAfter(intRetorno)) {
      desconto = intRetorno.difference(intSaida);
    }

    final liquida = bruta - desconto;

    return _JornadaResult(
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

          // Cabeçalho — caixa
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
            ],
          ),

          const Divider(height: 24),

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

            // ── Jornada baseada no ponto ──────────────────
            if (_carregando)
              const Padding(
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
              // Sem registro de ponto → fallback para horário de alocação
              _InfoRow(
                icon: Icons.access_time,
                label: 'Alocado às',
                value:
                    '${widget.alocacao!.alocadoEm.hour.toString().padLeft(2, '0')}:'
                    '${widget.alocacao!.alocadoEm.minute.toString().padLeft(2, '0')} '
                    '(sem registro de ponto hoje)',
                iconColor: AppColors.textSecondary,
              )
            else ...[
              // Linha: Ativo desde HH:mm (ponto)
              _InfoRow(
                icon: Icons.fingerprint,
                label: 'Ativo desde',
                value: '${jornada.entrada} (ponto)',
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 6),
              // Linha: Jornada líquida
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Jornada líquida',
                value: _formatDuracao(jornada.liquida),
                iconColor: _corJornada(jornada.status),
              ),
              const SizedBox(height: 6),
              // Badge de status
              _StatusBadge(status: jornada.status),
            ],

            const SizedBox(height: 12),

            // Horários da escala
            if (widget.turno != null) ...[
              const Text('Escala de hoje', style: AppTextStyles.label),
              const SizedBox(height: 8),
              _HorarioGrid(turno: widget.turno!),
            ],

            const SizedBox(height: 20),

            // Botão Liberar
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await widget.alocacaoProvider.liberarAlocacao(
                  widget.alocacao!.id,
                  'Liberado pelo mapa visual',
                );
                if (context.mounted) {
                  AppNotif.show(
                    context,
                    titulo: 'Colaborador Liberado',
                    mensagem: 'Colaborador liberado!',
                    tipo: 'saida',
                    cor: AppColors.success,
                  );
                }
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Liberar Caixa'),
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
// Badge de status da jornada
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'trabalhando' => ('Trabalhando', AppColors.statusAtivo, Icons.work),
      'intervalo'   => ('Em Intervalo', AppColors.statusCafe, Icons.coffee),
      'encerrado'   => ('Jornada Encerrada', AppColors.textSecondary, Icons.check_circle),
      _             => ('Sem Ponto', AppColors.inactive, Icons.help_outline),
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
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
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
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
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
class _HorarioGrid extends StatelessWidget {
  final TurnoLocal turno;

  const _HorarioGrid({required this.turno});

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
        _HorarioChip(
            icon: Icons.login, label: 'Entrada', value: turno.entrada),
        _HorarioChip(
            icon: Icons.free_breakfast,
            label: 'Intervalo',
            value: turno.intervalo),
        _HorarioChip(
            icon: Icons.replay, label: 'Retorno', value: turno.retorno),
        _HorarioChip(
            icon: Icons.logout, label: 'Saída', value: turno.saida),
      ],
    );
  }
}

class _HorarioChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _HorarioChip({
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
