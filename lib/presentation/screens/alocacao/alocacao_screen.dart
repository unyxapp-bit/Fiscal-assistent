import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/caixa.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/escala_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/pacote_plantao_provider.dart';

/// Tela de alocação — lista colaboradores disponíveis agora e permite
/// alocar em um caixa com dois toques.
class AlocacaoScreen extends StatefulWidget {
  final String fiscalId;

  const AlocacaoScreen({super.key, required this.fiscalId});

  @override
  State<AlocacaoScreen> createState() => _AlocacaoScreenState();
}

class _AlocacaoScreenState extends State<AlocacaoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    if (!mounted) return;
    await Future.wait([
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(widget.fiscalId),
      Provider.of<EscalaProvider>(context, listen: false).load(),
      Provider.of<PacotePlantaoProvider>(context, listen: false)
          .load(widget.fiscalId),
    ]);
  }

  /// True se o colaborador está na janela de trabalho agora e não alocado.
  bool _estaDisponivel(TurnoLocal turno, AlocacaoProvider alocacaoProvider) {
    if (!turno.trabalhando) return false;
    if (alocacaoProvider.getAlocacaoColaborador(turno.colaboradorId) != null) {
      return false;
    }

    final agora = DateTime.now();
    final minAgora = agora.hour * 60 + agora.minute;

    if (turno.entrada != null) {
      final p = turno.entrada!.split(':');
      if (p.length == 2) {
        final minEntrada =
            (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
        // Disponível a partir de 30 min antes do horário de entrada
        if (minAgora < minEntrada - 30) return false;
      }
    }

    if (turno.saida != null) {
      final p = turno.saida!.split(':');
      if (p.length == 2) {
        final minSaida =
            (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
        if (minAgora > minSaida) return false;
      }
    }

    return true;
  }

  void _abrirSeletorCaixa(TurnoLocal turno) {
    final caixaProvider = Provider.of<CaixaProvider>(context, listen: false);
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final pacoteProvider =
        Provider.of<PacotePlantaoProvider>(context, listen: false);

    final isEmpacotador = turno.departamento == DepartamentoTipo.pacote;

    final disponiveis = caixaProvider.caixas
        .where((c) =>
            c.ativo &&
            !c.emManutencao &&
            alocacaoProvider.getAlocacaoCaixa(c.id) == null)
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      turno.colaboradorNome[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(turno.colaboradorNome, style: AppTextStyles.h4),
                        Text(
                          isEmpacotador
                              ? 'Alocar como empacotador ou em caixa'
                              : 'Selecione o caixa',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // ── Opção Empacotador (apenas para depto. pacote) ─────────
                  if (isEmpacotador)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF795548).withValues(alpha: 0.15),
                        child: const Icon(Icons.inventory_2,
                            color: Color(0xFF795548)),
                      ),
                      title: const Text('Empacotador',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Adicionar ao plantão de empacotadores',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF795548),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _alocarComoEmpacotador(
                            sheetCtx, turno, pacoteProvider),
                        child: const Text('Alocar'),
                      ),
                    ),
                  if (isEmpacotador && disponiveis.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('ou em caixa',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary)),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                    ),
                  // ── Caixas disponíveis ────────────────────────────────────
                  if (disponiveis.isEmpty && !isEmpacotador)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum caixa disponível no momento.',
                        style: AppTextStyles.body,
                      ),
                    )
                  else
                    ...disponiveis.map((caixa) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                caixa.tipo.cor.withValues(alpha: 0.15),
                            child:
                                Icon(caixa.tipo.icone, color: caixa.tipo.cor),
                          ),
                          title: Text(caixa.nomeExibicao,
                              style: AppTextStyles.h4),
                          subtitle: Text(caixa.tipo.nome,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _confirmarAlocacao(
                                sheetCtx, turno, caixa, alocacaoProvider),
                            child: const Text('Alocar'),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alocarComoEmpacotador(
    BuildContext sheetCtx,
    TurnoLocal turno,
    PacotePlantaoProvider pacoteProvider,
  ) async {
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    Navigator.of(sheetCtx).pop();

    await pacoteProvider.adicionar(widget.fiscalId, turno.colaboradorId);

    if (!mounted) return;

    if (pacoteProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pacoteProvider.error!),
        backgroundColor: AppColors.danger,
      ));
    } else {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.empacotadorAdicionado,
        colaboradorNome: turno.colaboradorNome,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${turno.colaboradorNome} adicionado ao plantão de empacotadores!'),
        backgroundColor: const Color(0xFF795548),
      ));
    }
  }

  Future<void> _confirmarAlocacao(
    BuildContext sheetCtx,
    TurnoLocal turno,
    Caixa caixa,
    AlocacaoProvider alocacaoProvider,
  ) async {
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    Navigator.of(sheetCtx).pop();

    await alocacaoProvider.alocarColaborador(
      colaboradorId: turno.colaboradorId,
      caixaId: caixa.id,
      fiscalId: widget.fiscalId,
    );

    if (!mounted) return;

    if (alocacaoProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(alocacaoProvider.error!),
        backgroundColor: AppColors.danger,
      ));
    } else {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.colaboradorAlocado,
        colaboradorNome: turno.colaboradorNome,
        caixaNome: caixa.nomeExibicao,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('${turno.colaboradorNome} alocado em ${caixa.nomeExibicao}!'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final escalaProvider = Provider.of<EscalaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final pacoteProvider = Provider.of<PacotePlantaoProvider>(context);

    final agora = DateTime.now();
    final dataLabel =
        DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(agora);
    final horaLabel = DateFormat('HH:mm').format(agora);

    final turnosHoje = escalaProvider.turnosHoje;

    final disponiveis = turnosHoje
        .where((t) {
          if (!_estaDisponivel(t, alocacaoProvider)) return false;
          // Empacotador já no plantão não aparece como disponível
          if (t.departamento == DepartamentoTipo.pacote &&
              pacoteProvider.isNaLista(t.colaboradorId)) {
            return false;
          }
          return true;
        })
        .toList()
      ..sort((a, b) => (a.entrada ?? '').compareTo(b.entrada ?? ''));

    final jaAlocados = turnosHoje
        .where((t) =>
            t.trabalhando &&
            alocacaoProvider.getAlocacaoColaborador(t.colaboradorId) != null)
        .toList();

    final folgas = turnosHoje.where((t) => t.folga || t.feriado).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alocar Colaborador'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          children: [
            // Data e hora atual
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(Dimensions.borderRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cap(dataLabel),
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  Text(horaLabel,
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            if (turnosHoje.isEmpty) ...[
              const _Empty(
                icon: Icons.calendar_today,
                msg: 'Nenhuma escala cadastrada para hoje.\nVá em "Escala Semanal" e cadastre.',
              ),
            ] else ...[
              // Disponíveis agora
              _Header(
                  icon: Icons.person_add,
                  label: 'Disponíveis agora',
                  count: disponiveis.length,
                  color: AppColors.statusAtivo),
              const SizedBox(height: 8),
              if (disponiveis.isEmpty)
                const _Empty(
                  icon: Icons.hourglass_empty,
                  msg: 'Nenhum colaborador disponível neste horário.',
                )
              else
                ...disponiveis.map((t) => _CardDisponivel(
                      turno: t,
                      onAlocar: () => _abrirSeletorCaixa(t),
                    )),

              // Já alocados
              if (jaAlocados.isNotEmpty) ...[
                const SizedBox(height: Dimensions.spacingLG),
                _Header(
                    icon: Icons.point_of_sale,
                    label: 'Já alocados',
                    count: jaAlocados.length,
                    color: AppColors.primary),
                const SizedBox(height: 8),
                ...jaAlocados.map((t) {
                  final al = alocacaoProvider
                      .getAlocacaoColaborador(t.colaboradorId);
                  return _CardAlocado(
                    turno: t,
                    caixaId: al?.caixaId ?? '',
                    alocadoEm: al?.alocadoEm,
                  );
                }),
              ],

              // Folgas
              if (folgas.isNotEmpty) ...[
                const SizedBox(height: Dimensions.spacingLG),
                _Header(
                    icon: Icons.beach_access,
                    label: 'Folgas / Feriados',
                    count: folgas.length,
                    color: AppColors.statusAtencao),
                const SizedBox(height: 8),
                ...folgas.map((t) => _CardFolga(turno: t)),
              ],
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Widgets internos ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _Header(
      {required this.icon,
      required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyles.subtitle.copyWith(color: color)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Text('$count',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ),
    ]);
  }
}

class _CardDisponivel extends StatelessWidget {
  final TurnoLocal turno;
  final VoidCallback onAlocar;
  const _CardDisponivel({required this.turno, required this.onAlocar});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.statusAtivo,
          child: Text(turno.colaboradorNome[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(turno.colaboradorNome, style: AppTextStyles.h4),
        subtitle: Text(
          [
            turno.departamento.nome,
            if (turno.entrada != null && turno.saida != null)
              '${turno.entrada}–${turno.saida}',
          ].join('  •  '),
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          onPressed: onAlocar,
          child: const Text('Alocar'),
        ),
      ),
    );
  }
}

class _CardAlocado extends StatelessWidget {
  final TurnoLocal turno;
  final String caixaId;
  final DateTime? alocadoEm;
  const _CardAlocado(
      {required this.turno, required this.caixaId, this.alocadoEm});

  String _tempo() {
    if (alocadoEm == null) return '';
    final d = DateTime.now().difference(alocadoEm!);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final caixa = Provider.of<CaixaProvider>(context, listen: false)
        .caixas
        .where((c) => c.id == caixaId)
        .firstOrNull;

    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(turno.colaboradorNome[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(turno.colaboradorNome, style: AppTextStyles.h4),
        subtitle: Text(
          caixa != null
              ? '${caixa.nomeExibicao}  •  ${_tempo()}'
              : turno.departamento.nome,
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Text('Ativo',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _CardFolga extends StatelessWidget {
  final TurnoLocal turno;
  const _CardFolga({required this.turno});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.inactive.withValues(alpha: 0.15),
          child: Text(turno.colaboradorNome[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.inactive, fontWeight: FontWeight.bold)),
        ),
        title: Text(turno.colaboradorNome,
            style: AppTextStyles.h4
                .copyWith(color: AppColors.textSecondary)),
        subtitle: Text(turno.feriado ? 'Feriado' : 'Folga semanal',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        trailing: Icon(
          turno.feriado ? Icons.celebration : Icons.beach_access,
          color: AppColors.statusAtencao,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String msg;
  const _Empty({required this.icon, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(icon, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(msg,
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
