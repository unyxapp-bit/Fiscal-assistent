import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/alocacao.dart';
import '../../../domain/entities/caixa.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/pacote_plantao_provider.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de alocação — lista colaboradores disponíveis agora e permite
/// alocar em um caixa com dois toques.
class AlocacaoScreen extends StatefulWidget {
  final String fiscalId;

  const AlocacaoScreen({super.key, required this.fiscalId});

  @override
  State<AlocacaoScreen> createState() => _AlocacaoScreenState();
}

class _AlocacaoScreenState extends State<AlocacaoScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await Future.wait([
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(widget.fiscalId),
      Provider.of<EscalaProvider>(context, listen: false).load(),
      Provider.of<PacotePlantaoProvider>(context, listen: false)
          .load(widget.fiscalId),
      if (authProvider.user != null)
        Provider.of<ColaboradorProvider>(context, listen: false)
            .loadColaboradores(authProvider.user!.id),
    ]);
  }

  int _minutos(String hora) {
    final p = hora.split(':');
    if (p.length != 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  /// Retorna quantos minutos faltam para o colaborador chegar.
  int? _minutosParaChegar(TurnoLocal turno) {
    if (turno.entrada == null) return null;
    final agora = DateTime.now();
    final minAgora = agora.hour * 60 + agora.minute;
    final diff = _minutos(turno.entrada!) - minAgora;
    return diff > 0 ? diff : null;
  }

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

  void _abrirSeletorCaixa(TurnoLocal turno, {String? alocacaoIdParaLiberar}) {
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
                          alocacaoIdParaLiberar != null
                              ? 'Selecione o novo caixa'
                              : isEmpacotador
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
                  // ── Opção Empacotador (apenas para depto. pacote e sem troca) ─
                  if (isEmpacotador && alocacaoIdParaLiberar == null)
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
                  if (isEmpacotador &&
                      alocacaoIdParaLiberar == null &&
                      disponiveis.isNotEmpty)
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
                              backgroundColor: alocacaoIdParaLiberar != null
                                  ? Colors.blue
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => alocacaoIdParaLiberar != null
                                ? _confirmarTroca(sheetCtx, turno, caixa,
                                    alocacaoIdParaLiberar, alocacaoProvider)
                                : _confirmarAlocacao(
                                    sheetCtx, turno, caixa, alocacaoProvider),
                            child: Text(
                                alocacaoIdParaLiberar != null
                                    ? 'Trocar'
                                    : 'Alocar'),
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
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: pacoteProvider.error!,
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    } else {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.empacotadorAdicionado,
        colaboradorNome: turno.colaboradorNome,
      );
      AppNotif.show(
        context,
        titulo: 'Empacotador Adicionado',
        mensagem:
            '${turno.colaboradorNome} adicionado ao plantão de empacotadores!',
        tipo: 'saida',
        cor: const Color(0xFF795548),
      );
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
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: alocacaoProvider.error!,
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    } else {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.colaboradorAlocado,
        colaboradorNome: turno.colaboradorNome,
        caixaNome: caixa.nomeExibicao,
      );
      AppNotif.show(
        context,
        titulo: 'Colaborador Alocado',
        mensagem: '${turno.colaboradorNome} alocado em ${caixa.nomeExibicao}!',
        tipo: 'saida',
        cor: AppColors.success,
      );
    }
  }

  Future<void> _confirmarTroca(
    BuildContext sheetCtx,
    TurnoLocal turno,
    Caixa novoCaixa,
    String alocacaoIdAtual,
    AlocacaoProvider alocacaoProvider,
  ) async {
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    Navigator.of(sheetCtx).pop();

    // 1. Libera o caixa atual
    await alocacaoProvider.liberarAlocacao(
        alocacaoIdAtual, 'Troca de caixa — realocado em ${novoCaixa.nomeExibicao}');

    if (!mounted) return;
    if (alocacaoProvider.error != null) {
      AppNotif.show(
        context,
        titulo: 'Erro ao trocar',
        mensagem: alocacaoProvider.error!,
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    // 2. Aloca no novo caixa
    await alocacaoProvider.alocarColaborador(
      colaboradorId: turno.colaboradorId,
      caixaId: novoCaixa.id,
      fiscalId: widget.fiscalId,
    );

    if (!mounted) return;

    if (alocacaoProvider.error != null) {
      AppNotif.show(
        context,
        titulo: 'Erro ao alocar',
        mensagem: alocacaoProvider.error!,
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    } else {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.colaboradorAlocado,
        colaboradorNome: turno.colaboradorNome,
        caixaNome: novoCaixa.nomeExibicao,
      );
      AppNotif.show(
        context,
        titulo: 'Caixa Trocado',
        mensagem:
            '${turno.colaboradorNome} transferido para ${novoCaixa.nomeExibicao}!',
        tipo: 'saida',
        cor: Colors.blue,
      );
    }
  }

  void _abrirOpcoesAlocado(TurnoLocal turno, Alocacao al) {
    final caixaProvider = Provider.of<CaixaProvider>(context, listen: false);
    final caixa =
        caixaProvider.caixas.where((c) => c.id == al.caixaId).firstOrNull;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── Cabeçalho ──────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    turno.colaboradorNome[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(turno.colaboradorNome, style: AppTextStyles.h4),
                      if (caixa != null)
                        Row(
                          children: [
                            Icon(caixa.tipo.icone,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              caixa.nomeExibicao,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Tempo alocado
                _TempoAlocadoBadge(alocadoEm: al.alocadoEm),
              ],
            ),

            // ── Info de intervalo ──────────────────────────────────────────
            if (turno.intervalo != null) ...[
              const SizedBox(height: 12),
              _IntervaloBanner(turno: turno),
            ],

            const SizedBox(height: 20),

            // ── Ações ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Trocar Caixa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _abrirSeletorCaixa(turno,
                          alocacaoIdParaLiberar: al.id);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Liberar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () =>
                        _confirmarLiberacao(sheetCtx, turno, al, caixa?.nomeExibicao),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarLiberacao(
    BuildContext sheetCtx,
    TurnoLocal turno,
    Alocacao al,
    String? caixaNome,
  ) async {
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    Navigator.of(sheetCtx).pop();

    await alocacaoProvider.liberarAlocacao(al.id, 'Liberado manualmente');

    if (!mounted) return;

    if (alocacaoProvider.error != null) {
      AppNotif.show(
        context,
        titulo: 'Erro',
        mensagem: alocacaoProvider.error!,
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    } else {
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.colaboradorLiberado,
        colaboradorNome: turno.colaboradorNome,
        caixaNome: caixaNome,
      );
      AppNotif.show(
        context,
        titulo: 'Colaborador Liberado',
        mensagem: '${turno.colaboradorNome} liberado do caixa!',
        tipo: 'saida',
        cor: AppColors.statusAtencao,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final escalaProvider = Provider.of<EscalaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final pacoteProvider = Provider.of<PacotePlantaoProvider>(context);
    final cafeProvider = Provider.of<CafeProvider>(context);

    final agora = DateTime.now();
    final dataLabel =
        DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(agora);
    final horaLabel = DateFormat('HH:mm').format(agora);

    final turnosHoje = escalaProvider.turnosHoje;
    final q = _searchCtrl.text.toLowerCase().trim();

    bool _matchSearch(TurnoLocal t) =>
        q.isEmpty || t.colaboradorNome.toLowerCase().contains(q);

    final disponiveis = turnosHoje
        .where((t) {
          if (!_matchSearch(t)) return false;
          if (!_estaDisponivel(t, alocacaoProvider)) return false;
          if (t.departamento == DepartamentoTipo.pacote &&
              pacoteProvider.isNaLista(t.colaboradorId)) {
            return false;
          }
          if (cafeProvider.colaboradorEmPausa(t.colaboradorId)) return false;
          return true;
        })
        .toList()
      ..sort((a, b) => (a.entrada ?? '').compareTo(b.entrada ?? ''));

    final jaAlocados = turnosHoje
        .where((t) =>
            _matchSearch(t) &&
            t.trabalhando &&
            alocacaoProvider.getAlocacaoColaborador(t.colaboradorId) != null)
        .toList();

    final folgas =
        turnosHoje.where((t) => _matchSearch(t) && (t.folga || t.feriado)).toList();

    final aChegar = turnosHoje
        .where((t) {
          if (!_matchSearch(t)) return false;
          if (!t.trabalhando || t.folga || t.feriado) return false;
          if (alocacaoProvider.getAlocacaoColaborador(t.colaboradorId) != null) {
            return false;
          }
          if (t.departamento == DepartamentoTipo.pacote &&
              pacoteProvider.isNaLista(t.colaboradorId)) {
            return false;
          }
          final min = _minutosParaChegar(t);
          if (min == null) return false;
          return min > 30 && min <= 180;
        })
        .toList()
      ..sort((a, b) => (a.entrada ?? '').compareTo(b.entrada ?? ''));

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
            // Data e hora
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

            const SizedBox(height: Dimensions.spacingMD),

            // ── Barra de busca ───────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar colaborador...',
                hintStyle: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundSection,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide.none,
                ),
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
                      minutosParaChegar: _minutosParaChegar(t),
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
                  final al =
                      alocacaoProvider.getAlocacaoColaborador(t.colaboradorId);
                  return _CardAlocado(
                    turno: t,
                    caixaId: al?.caixaId ?? '',
                    alocadoEm: al?.alocadoEm,
                    onTap: al != null
                        ? () => _abrirOpcoesAlocado(t, al)
                        : null,
                  );
                }),
              ],

              // A caminho
              if (aChegar.isNotEmpty) ...[
                const SizedBox(height: Dimensions.spacingLG),
                _Header(
                    icon: Icons.directions_walk,
                    label: 'A caminho',
                    count: aChegar.length,
                    color: AppColors.statusAtencao),
                const SizedBox(height: 8),
                ...aChegar.map((t) => _CardAChegar(
                      turno: t,
                      minutosParaChegar: _minutosParaChegar(t) ?? 0,
                    )),
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

// ─── Widgets auxiliares do sheet ─────────────────────────────────────────────

class _TempoAlocadoBadge extends StatefulWidget {
  final DateTime alocadoEm;
  const _TempoAlocadoBadge({required this.alocadoEm});

  @override
  State<_TempoAlocadoBadge> createState() => _TempoAlocadoBadgeState();
}

class _TempoAlocadoBadgeState extends State<_TempoAlocadoBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _tempo() {
    final d = DateTime.now().difference(widget.alocadoEm);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _tempo(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            'no caixa',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _IntervaloBanner extends StatelessWidget {
  final TurnoLocal turno;
  const _IntervaloBanner({required this.turno});

  int? _calcMin() {
    if (turno.intervalo == null) return null;
    final parts = turno.intervalo!.split(':');
    if (parts.length < 2) return null;
    final agora = DateTime.now();
    final agoraMin = agora.hour * 60 + agora.minute;
    final intervaloMin =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return agoraMin - intervaloMin;
  }

  @override
  Widget build(BuildContext context) {
    final min = _calcMin();
    if (min == null) return const SizedBox.shrink();

    final Color cor;
    final IconData icone;
    final String texto;

    if (min < -30) {
      cor = AppColors.textSecondary;
      icone = Icons.schedule;
      texto = 'Intervalo em ${-min}min (${turno.intervalo})';
    } else if (min < 0) {
      cor = Colors.orange.shade800;
      icone = Icons.schedule;
      texto = 'Intervalo em ${-min}min — aproximando';
    } else if (min < 15) {
      cor = Colors.orange.shade900;
      icone = Icons.warning_amber;
      texto = '${min}min em atraso para o intervalo';
    } else {
      cor = AppColors.danger;
      icone = Icons.error_outline;
      texto = '${min}min sem intervalo — Em Atenção';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

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
  final int? minutosParaChegar;
  const _CardDisponivel(
      {required this.turno, required this.onAlocar, this.minutosParaChegar});

  String _chegaEm(int min) {
    if (min >= 60) return 'Chega em ${min ~/ 60}h ${min % 60}min';
    return 'Chega em ${min}min';
  }

  @override
  Widget build(BuildContext context) {
    final chegando = minutosParaChegar != null && minutosParaChegar! > 0;
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              chegando ? AppColors.statusAtencao : AppColors.statusAtivo,
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
            if (chegando) _chegaEm(minutosParaChegar!),
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

// ─── Card de colaborador alocado com timer dinâmico ──────────────────────────

class _CardAlocado extends StatefulWidget {
  final TurnoLocal turno;
  final String caixaId;
  final DateTime? alocadoEm;
  final VoidCallback? onTap;
  const _CardAlocado(
      {required this.turno,
      required this.caixaId,
      this.alocadoEm,
      this.onTap});

  @override
  State<_CardAlocado> createState() => _CardAlocadoState();
}

class _CardAlocadoState extends State<_CardAlocado> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _tempo() {
    if (widget.alocadoEm == null) return '';
    final d = DateTime.now().difference(widget.alocadoEm!);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes}min';
  }

  /// Positivo = minutos ATRASADO; Negativo = minutos RESTANTES
  int? _calcMinIntervalo() {
    if (widget.turno.intervalo == null) return null;
    final parts = widget.turno.intervalo!.split(':');
    if (parts.length < 2) return null;
    final agora = DateTime.now();
    final agoraMin = agora.hour * 60 + agora.minute;
    final intervaloMin =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return agoraMin - intervaloMin;
  }

  @override
  Widget build(BuildContext context) {
    final caixa = Provider.of<CaixaProvider>(context, listen: false)
        .caixas
        .where((c) => c.id == widget.caixaId)
        .firstOrNull;

    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final intervaloJaFeito =
        alocacaoProvider.isIntervaloMarcado(widget.turno.colaboradorId);
    final minIntervalo = intervaloJaFeito ? null : _calcMinIntervalo();
    final emAtencao = minIntervalo != null && minIntervalo >= 15;

    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: widget.onTap,
            leading: CircleAvatar(
              backgroundColor: emAtencao
                  ? AppColors.danger.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              child: Text(widget.turno.colaboradorNome[0].toUpperCase(),
                  style: TextStyle(
                      color: emAtencao ? AppColors.danger : AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(widget.turno.colaboradorNome, style: AppTextStyles.h4),
            subtitle: Text(
              caixa != null
                  ? '${caixa.nomeExibicao}  •  ${_tempo()}'
                  : widget.turno.departamento.nome,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: emAtencao
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('Ativo',
                      style: AppTextStyles.caption.copyWith(
                          color: emAtencao ? AppColors.danger : AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
          // ── Faixa de aviso de intervalo ─────────────────────────────
          if (minIntervalo != null && minIntervalo > -60)
            _buildIntervaloBar(minIntervalo),
        ],
      ),
    );
  }

  Widget _buildIntervaloBar(int min) {
    final Color cor;
    final IconData icone;
    final String texto;

    if (min < 0) {
      cor = Colors.orange.shade800;
      icone = Icons.schedule;
      texto = 'Intervalo em ${-min}min';
    } else if (min < 15) {
      cor = Colors.orange.shade900;
      icone = Icons.warning_amber;
      texto = '${min}min em atraso para o intervalo';
    } else {
      cor = AppColors.danger;
      icone = Icons.error_outline;
      texto = '${min}min sem intervalo — Em Atenção';
    }

    final bgColor = min >= 15
        ? AppColors.danger.withValues(alpha: 0.08)
        : Colors.orange.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: bgColor,
      child: Row(
        children: [
          Icon(icone, size: 13, color: cor),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAChegar extends StatelessWidget {
  final TurnoLocal turno;
  final int minutosParaChegar;
  const _CardAChegar({required this.turno, required this.minutosParaChegar});

  String _chegaEm() {
    if (minutosParaChegar >= 60) {
      return 'Chega em ${minutosParaChegar ~/ 60}h ${minutosParaChegar % 60}min';
    }
    return 'Chega em ${minutosParaChegar}min';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.statusAtencao.withValues(alpha: 0.15),
          child: Text(turno.colaboradorNome[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.statusAtencao,
                  fontWeight: FontWeight.bold)),
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.statusAtencao.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Text(_chegaEm(),
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.statusAtencao,
                  fontWeight: FontWeight.bold)),
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
