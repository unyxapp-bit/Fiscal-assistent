import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/alocacao.dart';
import '../../../domain/entities/caixa.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/entities/outro_setor.dart';
import '../../../domain/entities/pacote_plantao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/escala_provider.dart';
import '../../providers/pacote_plantao_provider.dart';
import '../../providers/outro_setor_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../caixas/caixa_form_screen.dart';
import '../caixas/widgets/caixa_card.dart';
import 'widgets/caixa_list_item.dart';
import 'widgets/balcao_list_item.dart';
import 'widgets/pacote_section.dart';
import 'widgets/outro_setor_section.dart';
import '../../../core/utils/app_notif.dart';
import '../../../domain/enums/tipo_caixa.dart';

enum _MapaFiltro {
  todos,
  ocupados,
  pausa,
  atencao,
  livres,
  balcoes,
  cobertura,
}

class _MapaCaixaStatus {
  final Caixa caixa;
  final Alocacao? alocacao;
  final PausaCafe? pausa;
  final Colaborador? colaborador;
  final Colaborador? colaboradorEmPausa;
  final TurnoLocal? turno;
  final int? minIntervalo;

  const _MapaCaixaStatus({
    required this.caixa,
    required this.alocacao,
    required this.pausa,
    required this.colaborador,
    required this.colaboradorEmPausa,
    required this.turno,
    required this.minIntervalo,
  });

  bool get isOcupado => alocacao != null;
  bool get isEmPausa => pausa != null && alocacao == null;
  bool get isDisponivel =>
      caixa.ativo && !caixa.emManutencao && !isOcupado && pausa == null;
  bool get isEmAtencao => minIntervalo != null && minIntervalo! >= 15;
  bool get isPausaAtrasada => pausa?.emAtraso ?? false;
  Colaborador? get colaboradorAtual => colaborador ?? colaboradorEmPausa;

  String get localizacaoLabel {
    final partes = [caixa.loja, caixa.localizacao]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return partes.isEmpty ? 'Sem localizacao' : partes.join(' - ');
  }
}

class _MapaExcecaoItem {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _MapaExcecaoItem({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });
}

class _MapaSugestaoItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _MapaSugestaoItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });
}

class _MapaDashboardItem {
  final String value;
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _MapaDashboardItem({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

/// Tela de mapa de caixas ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â abas: Mapa | Caixas
class MapaCaixasScreen extends StatefulWidget {
  const MapaCaixasScreen({super.key});

  @override
  State<MapaCaixasScreen> createState() => _MapaCaixasScreenState();
}

class _MapaCaixasScreenState extends State<MapaCaixasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;
  final TextEditingController _buscaMapaCtrl = TextEditingController();
  String _buscaMapa = '';
  _MapaFiltro _filtroMapa = _MapaFiltro.todos;
  bool _mostrarLivres = false;
  bool _expandPainelMapa = true;
  bool _expandLeituraMapa = true;
  bool _expandSugestoesMapa = true;

  Timer? _timerSaidas;
  final Set<String> _saidasProcessadas = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      _iniciarTimerSaidas();
    });
  }

  @override
  void dispose() {
    _timerSaidas?.cancel();
    _buscaMapaCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _iniciarTimerSaidas() {
    _verificarSaidasAutomaticas();
    _timerSaidas = Timer.periodic(const Duration(minutes: 1), (_) {
      _verificarSaidasAutomaticas();
    });
  }

  void _verificarSaidasAutomaticas() {
    if (!mounted) return;
    final escala = Provider.of<EscalaProvider>(context, listen: false);
    final plantao = Provider.of<PacotePlantaoProvider>(context, listen: false);
    final agora = DateTime.now();

    // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Caixas ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    /*
    for (final turno in escala.turnosHoje) {
      if (turno.saida == null || turno.folga || turno.feriado) continue;
      if (_saidasProcessadas.contains(turno.colaboradorId)) continue;

      final partes = turno.saida!.split(':');
      final h = int.tryParse(partes[0]) ?? -1;
      final m = int.tryParse(partes.length > 1 ? partes[1] : '') ?? -1;
      if (h < 0 || m < 0) continue;

      final saidaHoje = DateTime(agora.year, agora.month, agora.day, h, m);
      if (!agora.isAfter(saidaHoje)) continue;

      final alocacaoAtiva = alocacao.getAlocacaoColaborador(turno.colaboradorId);
      if (alocacaoAtiva == null) continue;

      _saidasProcessadas.add(turno.colaboradorId);
      alocacao.liberarAlocacao(
        alocacaoAtiva.id,
        'Encerramento automÃƒÆ’Ã‚Â¡tico ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â horÃƒÆ’Ã‚Â¡rio de saÃƒÆ’Ã‚Â­da atingido (${turno.saida})',
      );

      if (mounted) {
        AppNotif.show(
          context,
          titulo: 'SaÃƒÆ’Ã‚Â­da AutomÃƒÆ’Ã‚Â¡tica',
          mensagem: '${turno.colaboradorNome} atingiu o horÃƒÆ’Ã‚Â¡rio de saÃƒÆ’Ã‚Â­da e foi liberado(a) do caixa',
          tipo: 'saida',
          cor: AppColors.success,
          duracao: const Duration(seconds: 5),
        );
      }
    }

    */
    // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Pacotes ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    for (final p in plantao.plantao.toList()) {
      if (_saidasProcessadas.contains(p.colaboradorId)) continue;

      final turno = escala.turnosHoje
          .where((t) => t.colaboradorId == p.colaboradorId)
          .firstOrNull;
      if (turno?.saida == null ||
          (turno?.folga ?? false) ||
          (turno?.feriado ?? false)) {
        continue;
      }

      final partes = turno!.saida!.split(':');
      final h = int.tryParse(partes[0]) ?? -1;
      final m = int.tryParse(partes.length > 1 ? partes[1] : '') ?? -1;
      if (h < 0 || m < 0) continue;

      final saidaHoje = DateTime(agora.year, agora.month, agora.day, h, m);
      if (!agora.isAfter(saidaHoje)) continue;

      _saidasProcessadas.add(p.colaboradorId);
      plantao.remover(p.id);

      if (mounted) {
        AppNotif.show(
          context,
          titulo: 'SaÃƒÆ’Ã‚Â­da AutomÃƒÆ’Ã‚Â¡tica',
          mensagem:
              '${turno.colaboradorNome} atingiu o horÃƒÆ’Ã‚Â¡rio de saÃƒÆ’Ã‚Â­da e foi removido(a) do plantÃƒÆ’Ã‚Â£o de pacotes',
          tipo: 'saida',
          cor: AppColors.success,
          duracao: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final userId = authProvider.user!.id;

    await Future.wait([
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
      Provider.of<CafeProvider>(context, listen: false).load(),
      Provider.of<EscalaProvider>(context, listen: false).load(),
      Provider.of<PacotePlantaoProvider>(context, listen: false).load(userId),
      Provider.of<OutroSetorProvider>(context, listen: false).load(userId),
    ]);
  }

  void _aplicarFiltroMapa(_MapaFiltro filtro, {bool? mostrarLivres}) {
    setState(() {
      _filtroMapa = filtro;
      if (mostrarLivres != null) {
        _mostrarLivres = mostrarLivres;
      } else if (filtro == _MapaFiltro.livres) {
        _mostrarLivres = true;
      }
    });
  }

  String _normalizarBusca(String valor) {
    const mapa = {
      'a': 'a',
      'ÃƒÆ’Ã‚Â¡': 'a',
      'ÃƒÆ’Ã‚Â ': 'a',
      'ÃƒÆ’Ã‚Â¢': 'a',
      'ÃƒÆ’Ã‚Â£': 'a',
      'ÃƒÆ’Ã‚Â¤': 'a',
      'e': 'e',
      'ÃƒÆ’Ã‚Â©': 'e',
      'ÃƒÆ’Ã‚Â¨': 'e',
      'ÃƒÆ’Ã‚Âª': 'e',
      'ÃƒÆ’Ã‚Â«': 'e',
      'i': 'i',
      'ÃƒÆ’Ã‚Â­': 'i',
      'ÃƒÆ’Ã‚Â¬': 'i',
      'ÃƒÆ’Ã‚Â®': 'i',
      'ÃƒÆ’Ã‚Â¯': 'i',
      'o': 'o',
      'ÃƒÆ’Ã‚Â³': 'o',
      'ÃƒÆ’Ã‚Â²': 'o',
      'ÃƒÆ’Ã‚Â´': 'o',
      'ÃƒÆ’Ã‚Âµ': 'o',
      'ÃƒÆ’Ã‚Â¶': 'o',
      'u': 'u',
      'ÃƒÆ’Ã‚Âº': 'u',
      'ÃƒÆ’Ã‚Â¹': 'u',
      'ÃƒÆ’Ã‚Â»': 'u',
      'ÃƒÆ’Ã‚Â¼': 'u',
      'ÃƒÆ’Ã‚Â§': 'c',
      'ÃƒÆ’Ã‚Â±': 'n',
    };

    final lower = valor.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(mapa[char] ?? char);
    }
    return buffer.toString();
  }

  int? _calcMinIntervaloMapa(TurnoLocal? turno) {
    if (turno?.intervalo == null) return null;
    final parts = turno!.intervalo!.split(':');
    if (parts.length < 2) return null;
    final agora = DateTime.now();
    final agoraMin = agora.hour * 60 + agora.minute;
    final intervaloMin =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return agoraMin - intervaloMin;
  }

  List<_MapaCaixaStatus> _coletarStatusesMapa({
    required List<Caixa> caixasTodos,
    required AlocacaoProvider alocacaoProvider,
    required CafeProvider cafeProvider,
    required ColaboradorProvider colaboradorProvider,
    required EscalaProvider escalaProvider,
  }) {
    final colabById = {
      for (final colaborador in colaboradorProvider.colaboradores)
        colaborador.id: colaborador,
    };

    final turnosByColab = {
      for (final turno in escalaProvider.turnosHoje) turno.colaboradorId: turno,
    };

    final itens = caixasTodos
        .where((caixa) => caixa.tipo != TipoCaixa.balcao)
        .map((caixa) {
      final alocacao = alocacaoProvider.getAlocacaoCaixa(caixa.id);
      final pausa = cafeProvider.getPausaAtivaPorCaixa(caixa.id);
      final colaborador =
          alocacao != null ? colabById[alocacao.colaboradorId] : null;
      final colaboradorEmPausa = pausa != null && colaborador == null
          ? colabById[pausa.colaboradorId]
          : null;
      final colaboradorAtual = colaborador ?? colaboradorEmPausa;
      final turno =
          colaboradorAtual != null ? turnosByColab[colaboradorAtual.id] : null;
      final intervaloJaFeito = colaboradorAtual != null &&
          (alocacaoProvider.isIntervaloMarcado(colaboradorAtual.id) ||
              cafeProvider.colaboradorJaFezIntervaloHoje(colaboradorAtual.id));
      final minIntervalo = alocacao != null &&
              pausa == null &&
              !intervaloJaFeito &&
              turno != null
          ? _calcMinIntervaloMapa(turno)
          : null;

      return _MapaCaixaStatus(
        caixa: caixa,
        alocacao: alocacao,
        pausa: pausa,
        colaborador: colaborador,
        colaboradorEmPausa: colaboradorEmPausa,
        turno: turno,
        minIntervalo: minIntervalo,
      );
    }).toList();

    itens.sort((a, b) {
      final loc = a.localizacaoLabel.compareTo(b.localizacaoLabel);
      if (loc != 0) return loc;
      return a.caixa.numero.compareTo(b.caixa.numero);
    });
    return itens;
  }

  bool _matchesBuscaStatus(_MapaCaixaStatus status) {
    final query = _normalizarBusca(_buscaMapa.trim());
    if (query.isEmpty) return true;

    final texto = [
      status.caixa.nomeExibicao,
      status.caixa.numero.toString(),
      status.caixa.tipo.nome,
      status.caixa.loja ?? '',
      status.caixa.localizacao ?? '',
      status.colaboradorAtual?.nome ?? '',
    ].join(' ');

    return _normalizarBusca(texto).contains(query);
  }

  bool _matchesBuscaBalcao(
    Caixa caixa,
    List<Alocacao> alocacoes,
    Map<String, Colaborador> colabById,
  ) {
    final query = _normalizarBusca(_buscaMapa.trim());
    if (query.isEmpty) return true;

    final nomes = alocacoes
        .map((alocacao) => colabById[alocacao.colaboradorId]?.nome ?? '')
        .join(' ');
    final texto = [
      caixa.nomeExibicao,
      caixa.numero.toString(),
      caixa.tipo.nome,
      caixa.loja ?? '',
      caixa.localizacao ?? '',
      nomes,
    ].join(' ');

    return _normalizarBusca(texto).contains(query);
  }

  bool _deveExibirStatus(_MapaCaixaStatus status) {
    if (!_matchesBuscaStatus(status)) return false;

    switch (_filtroMapa) {
      case _MapaFiltro.todos:
        return _mostrarLivres || status.isOcupado || status.isEmPausa;
      case _MapaFiltro.ocupados:
        return status.isOcupado;
      case _MapaFiltro.pausa:
        return status.isEmPausa;
      case _MapaFiltro.atencao:
        return status.isEmAtencao || status.isPausaAtrasada;
      case _MapaFiltro.livres:
        return status.isDisponivel;
      case _MapaFiltro.balcoes:
      case _MapaFiltro.cobertura:
        return false;
    }
  }

  Map<String, List<_MapaCaixaStatus>> _agruparPorLocalizacao(
    List<_MapaCaixaStatus> itens,
  ) {
    final grupos = <String, List<_MapaCaixaStatus>>{};
    for (final item in itens) {
      grupos.putIfAbsent(item.localizacaoLabel, () => []).add(item);
    }
    for (final grupo in grupos.values) {
      grupo.sort((a, b) {
        final porPrioridade =
            _prioridadeStatusMapa(a).compareTo(_prioridadeStatusMapa(b));
        if (porPrioridade != 0) return porPrioridade;
        return a.caixa.numero.compareTo(b.caixa.numero);
      });
    }
    return grupos;
  }

  int _prioridadeStatusMapa(_MapaCaixaStatus status) {
    if (status.isEmAtencao) return 0;
    if (status.isPausaAtrasada) return 1;
    if (status.isEmPausa) return 2;
    if (status.isOcupado) return 3;
    if (status.isDisponivel) return 4;
    return 5;
  }

  String _labelFiltroMapa(_MapaFiltro filtro) {
    switch (filtro) {
      case _MapaFiltro.todos:
        return 'Todos';
      case _MapaFiltro.ocupados:
        return 'Ocupados';
      case _MapaFiltro.pausa:
        return 'Em pausa';
      case _MapaFiltro.atencao:
        return 'Em atencao';
      case _MapaFiltro.livres:
        return 'Livres';
      case _MapaFiltro.balcoes:
        return 'Balcoes';
      case _MapaFiltro.cobertura:
        return 'Cobertura';
    }
  }

  Color _corFiltroMapa(_MapaFiltro filtro) {
    switch (filtro) {
      case _MapaFiltro.todos:
        return AppColors.primary;
      case _MapaFiltro.ocupados:
        return AppColors.statusAtivo;
      case _MapaFiltro.pausa:
        return AppColors.statusCafe;
      case _MapaFiltro.atencao:
        return AppColors.danger;
      case _MapaFiltro.livres:
        return AppColors.success;
      case _MapaFiltro.balcoes:
        return AppColors.statusSelf;
      case _MapaFiltro.cobertura:
        return AppColors.indigo;
    }
  }

  bool get _temControlesMapaAtivos {
    return _filtroMapa != _MapaFiltro.todos ||
        _mostrarLivres ||
        _buscaMapa.trim().isNotEmpty;
  }

  void _limparControlesMapa() {
    _buscaMapaCtrl.clear();
    setState(() {
      _buscaMapa = '';
      _filtroMapa = _MapaFiltro.todos;
      _mostrarLivres = false;
    });
  }

  Widget _buildMapaBusca() {
    return TextField(
      controller: _buscaMapaCtrl,
      onChanged: (value) => setState(() => _buscaMapa = value),
      decoration: InputDecoration(
        hintText: 'Buscar por caixa, colaborador ou localizacao',
        prefixIcon: Icon(Icons.search),
        suffixIcon: _buscaMapa.trim().isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  _buscaMapaCtrl.clear();
                  setState(() => _buscaMapa = '');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildMapaFiltros() {
    final filtros = [
      _MapaFiltro.todos,
      _MapaFiltro.ocupados,
      _MapaFiltro.pausa,
      _MapaFiltro.atencao,
      _MapaFiltro.livres,
      _MapaFiltro.balcoes,
      _MapaFiltro.cobertura,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...filtros.map((filtro) {
          final cor = _corFiltroMapa(filtro);
          return ChoiceChip(
            label: Text(_labelFiltroMapa(filtro)),
            selected: _filtroMapa == filtro,
            showCheckmark: false,
            labelStyle: AppTextStyles.caption.copyWith(
              color: _filtroMapa == filtro ? cor : AppColors.textPrimary,
              fontWeight:
                  _filtroMapa == filtro ? FontWeight.w700 : FontWeight.w600,
            ),
            selectedColor: cor.withValues(alpha: 0.12),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: _filtroMapa == filtro
                  ? cor.withValues(alpha: 0.30)
                  : AppColors.cardBorder,
            ),
            avatar: Icon(
              filtro == _MapaFiltro.todos
                  ? Icons.grid_view_rounded
                  : filtro == _MapaFiltro.ocupados
                      ? Icons.person
                      : filtro == _MapaFiltro.pausa
                          ? Icons.coffee
                          : filtro == _MapaFiltro.atencao
                              ? Icons.warning_amber_rounded
                              : filtro == _MapaFiltro.livres
                                  ? Icons.point_of_sale_outlined
                                  : filtro == _MapaFiltro.balcoes
                                      ? Icons.storefront_outlined
                                      : Icons.groups_2_outlined,
              size: 16,
              color: _filtroMapa == filtro ? cor : AppColors.textSecondary,
            ),
            onSelected: (_) => _aplicarFiltroMapa(filtro),
          );
        }),
        FilterChip(
          label: Text('Mostrar livres'),
          selected: _mostrarLivres,
          showCheckmark: false,
          labelStyle: AppTextStyles.caption.copyWith(
            color: _mostrarLivres ? AppColors.success : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: AppColors.success.withValues(alpha: 0.12),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: _mostrarLivres
                ? AppColors.success.withValues(alpha: 0.28)
                : AppColors.cardBorder,
          ),
          avatar: Icon(
            Icons.visibility_outlined,
            size: 16,
            color: _mostrarLivres ? AppColors.success : AppColors.textSecondary,
          ),
          onSelected: (value) => setState(() => _mostrarLivres = value),
        ),
      ],
    );
  }

  Widget _buildMapaLegenda() {
    return Container(
      decoration: AppStyles.softTile(
        tint: AppColors.blueGrey,
        radius: 14,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSM),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildLegendItem('Ocupado', AppColors.statusAtivo),
            _buildLegendItem('Em pausa', AppColors.statusCafe),
            _buildLegendItem('Em atencao', AppColors.danger),
            _buildLegendItem('Disponivel', AppColors.success),
            _buildLegendItem('Inativo', AppColors.inactive),
            _buildLegendItem('Manutencao', AppColors.statusAtencao),
          ],
        ),
      ),
    );
  }

  Widget _buildPainelPill({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaControlesCard({
    required int totalVisiveis,
    required int totalGeral,
    required int localizacoes,
  }) {
    final corFiltro = _corFiltroMapa(_filtroMapa);

    return Container(
      decoration: AppStyles.softCard(
        tint: AppColors.blueGrey,
        radius: Dimensions.radiusLG,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusMD),
              onTap: () => setState(
                () => _expandLeituraMapa = !_expandLeituraMapa,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.blueGrey.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.blueGrey,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Leitura do mapa', style: AppTextStyles.h4),
                        SizedBox(height: 2),
                        Text(
                          'Mostrando $totalVisiveis de $totalGeral caixas em $localizacoes area(s).',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_temControlesMapaAtivos)
                    TextButton.icon(
                      onPressed: _limparControlesMapa,
                      icon: Icon(Icons.restart_alt, size: 16),
                      label: Text('Limpar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _expandLeituraMapa
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  SizedBox(height: Dimensions.spacingSM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPainelPill(
                        icon: Icons.filter_alt_outlined,
                        color: corFiltro,
                        label: 'Filtro: ${_labelFiltroMapa(_filtroMapa)}',
                      ),
                      _buildPainelPill(
                        icon: Icons.grid_view_rounded,
                        color: AppColors.primary,
                        label: '$totalVisiveis visiveis',
                      ),
                      _buildPainelPill(
                        icon: Icons.map_outlined,
                        color: AppColors.teal,
                        label: '$localizacoes localizacoes',
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingMD),
                  _buildMapaBusca(),
                  SizedBox(height: Dimensions.spacingSM),
                  _buildMapaFiltros(),
                  SizedBox(height: Dimensions.spacingSM),
                  _buildMapaLegenda(),
                ],
              ),
              crossFadeState: _expandLeituraMapa
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoPill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$value $label',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLocalizacaoSection(
    String label,
    List<_MapaCaixaStatus> itens,
  ) {
    final total = itens.length;
    final ocupados = itens.where((item) => item.isOcupado).length;
    final pausas = itens.where((item) => item.isEmPausa).length;
    final livres = itens.where((item) => item.isDisponivel).length;
    final atencao = itens.where((item) => item.isEmAtencao).length;
    final corDestaque = atencao > 0
        ? AppColors.danger
        : pausas > 0
            ? AppColors.statusCafe
            : ocupados > 0
                ? AppColors.primary
                : AppColors.success;

    return Container(
      decoration: AppStyles.softCard(
        tint: corDestaque,
        radius: Dimensions.radiusLG,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: BoxDecoration(
                color: corDestaque.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                border: Border.all(
                  color: corDestaque.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: corDestaque.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: corDestaque,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTextStyles.h4),
                        SizedBox(height: 2),
                        Text(
                          '$total caixa(s) visivel(is) nesta area.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$total',
                      style: AppTextStyles.label.copyWith(
                        color: corDestaque,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Dimensions.spacingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ocupados > 0)
                  _buildResumoPill(
                    'ocupados',
                    ocupados,
                    AppColors.statusAtivo,
                  ),
                if (pausas > 0)
                  _buildResumoPill(
                    'em pausa',
                    pausas,
                    AppColors.statusCafe,
                  ),
                if (livres > 0)
                  _buildResumoPill(
                    'livres',
                    livres,
                    AppColors.success,
                  ),
                if (atencao > 0)
                  _buildResumoPill(
                    'em atencao',
                    atencao,
                    AppColors.danger,
                  ),
              ],
            ),
            SizedBox(height: Dimensions.spacingMD),
            ...itens.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                child: CaixaListItem(
                  caixa: item.caixa,
                  alocacao: item.alocacao,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcecoesFaixa(List<_MapaExcecaoItem> itens) {
    if (itens.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: AppStyles.softCard(
        tint: AppColors.warning,
        radius: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emergency_outlined,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Excecoes do mapa', style: AppTextStyles.h4),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Pontos que pedem leitura imediata antes de trocar o quadro.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: itens.map((item) {
                final chip = Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: item.color.withValues(alpha: 0.16)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 16, color: item.color),
                      SizedBox(width: 6),
                      Text(
                        item.label,
                        style: AppTextStyles.caption.copyWith(
                          color: item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );

                if (item.onTap == null) return chip;
                return InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: chip,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSugestoesCard(List<_MapaSugestaoItem> sugestoes) {
    if (sugestoes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: AppStyles.softCard(
        tint: AppColors.success,
        radius: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusMD),
              onTap: () => setState(
                () => _expandSugestoesMapa = !_expandSugestoesMapa,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child:
                        Text('Sugestoes automaticas', style: AppTextStyles.h4),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _expandSugestoesMapa
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  SizedBox(height: 4),
                  Text(
                    'Atalhos de decisao para destravar pausa, troca e cobertura.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 10),
                  ...sugestoes.map(
                    (sugestao) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: sugestao.onTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: sugestao.color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  sugestao.icon,
                                  color: sugestao.color,
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sugestao.title,
                                      style: AppTextStyles.label,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      sugestao.subtitle,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                sugestao.actionLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: sugestao.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _expandSugestoesMapa
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapaDashboard({
    required BuildContext context,
    required CaixaProvider caixaProvider,
    required AlocacaoProvider alocacaoProvider,
    required CafeProvider cafeProvider,
    required ColaboradorProvider colaboradorProvider,
    required PacotePlantaoProvider plantaoProvider,
    required OutroSetorProvider outroSetorProvider,
    required List<_MapaCaixaStatus> statuses,
    required int localizacoesVisiveis,
  }) {
    final caixasTodos = caixaProvider.caixasTodos;
    final colabById = {
      for (final colaborador in colaboradorProvider.colaboradores)
        colaborador.id: colaborador,
    };

    final ocupados = caixasTodos.where((caixa) {
      return alocacaoProvider.getAlocacaoCaixa(caixa.id) != null ||
          cafeProvider.getPausaAtivaPorCaixa(caixa.id) != null;
    }).toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));

    final pausasAtivas = cafeProvider.pausasAtivas
        .where((pausa) => pausa.caixaId != null && pausa.caixaId!.isNotEmpty)
        .toList()
      ..sort((a, b) => a.colaboradorNome.compareTo(b.colaboradorNome));

    final livres = statuses.where((status) => status.isDisponivel).toList()
      ..sort((a, b) => a.caixa.numero.compareTo(b.caixa.numero));

    final totalCobertura = alocacaoProvider.getAlocacoesAtivas().length +
        plantaoProvider.total +
        outroSetorProvider.total;
    final excecoes = statuses
        .where((status) => status.isEmAtencao || status.isPausaAtrasada)
        .length;
    final resumo = excecoes > 0
        ? '$excecoes ponto(s) do mapa pedem decisao agora.'
        : 'Sem alertas criticos no momento. Use os cards para detalhar a operacao.';

    final cards = [
      _MapaDashboardItem(
        value: '${ocupados.length}',
        label: 'Alocados',
        subtitle:
            ocupados.isEmpty ? 'Sem caixas ocupados' : 'Caixas em operacao',
        color: AppColors.statusAtivo,
        icon: Icons.person,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusSheet),
            ),
          ),
          builder: (_) => _OcupadosSheet(
            caixas: ocupados,
            caixasTodos: caixasTodos,
            alocacaoProvider: alocacaoProvider,
            cafeProvider: cafeProvider,
            colabById: colabById,
          ),
        ),
      ),
      _MapaDashboardItem(
        value: '${pausasAtivas.length}',
        label: 'Em pausa',
        subtitle: pausasAtivas.isEmpty
            ? 'Sem pausas abertas'
            : 'Pessoas fora do caixa',
        color: AppColors.statusCafe,
        icon: Icons.coffee,
        onTap: () => showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusSheet),
            ),
          ),
          builder: (_) => _PausasSheet(
            pausas: pausasAtivas,
            caixasTodos: caixasTodos,
          ),
        ),
      ),
      _MapaDashboardItem(
        value: '${livres.length}',
        label: 'Livres',
        subtitle:
            livres.isEmpty ? 'Nenhum caixa livre' : 'Prontos para cobertura',
        color: AppColors.success,
        icon: Icons.point_of_sale,
        onTap: () => showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusSheet),
            ),
          ),
          builder: (_) => _LivresSheet(statuses: livres),
        ),
      ),
      _MapaDashboardItem(
        value: '$totalCobertura',
        label: 'Cobertura',
        subtitle: 'Mapa + plantao + outro setor',
        color: AppColors.primary,
        icon: Icons.groups_2_outlined,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusSheet),
            ),
          ),
          builder: (_) => _CoberturaSheet(
            alocacoes: alocacaoProvider.getAlocacoesAtivas(),
            plantao: plantaoProvider.plantao,
            outroSetor: outroSetorProvider.lista,
            caixasTodos: caixasTodos,
            colabById: colabById,
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLG),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary,
                Colors.white,
                AppColors.alertInfo,
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                  onTap: () => setState(
                    () => _expandPainelMapa = !_expandPainelMapa,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.monitor_heart_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Painel operacional',
                              style: AppTextStyles.h3,
                            ),
                            SizedBox(height: 4),
                            Text(
                              resumo,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _expandPainelMapa
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: SizedBox(width: double.infinity),
                  secondChild: Column(
                    children: [
                      SizedBox(height: Dimensions.spacingSM),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPainelPill(
                            icon: Icons.map_outlined,
                            color: AppColors.primary,
                            label: '${statuses.length} caixas no mapa',
                          ),
                          _buildPainelPill(
                            icon: Icons.pin_drop_outlined,
                            color: AppColors.teal,
                            label: '$localizacoesVisiveis localizacoes',
                          ),
                          _buildPainelPill(
                            icon: Icons.warning_amber_rounded,
                            color: excecoes > 0
                                ? AppColors.danger
                                : AppColors.success,
                            label: excecoes > 0
                                ? '$excecoes excecoes ativas'
                                : 'Mapa estavel',
                          ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState: _expandPainelMapa
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Dimensions.spacingSM),
        LayoutBuilder(
          builder: (context, constraints) {
            final largura = constraints.maxWidth;
            final colunas = largura >= 900
                ? 4
                : largura >= Dimensions.breakpointTablet
                    ? 2
                    : 2;
            final proporcao = largura >= 900
                ? 1.95
                : largura >= Dimensions.breakpointTablet
                    ? 1.75
                    : 1.6;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunas,
                crossAxisSpacing: Dimensions.spacingSM,
                mainAxisSpacing: Dimensions.spacingSM,
                childAspectRatio: proporcao,
              ),
              itemBuilder: (_, index) {
                final item = cards[index];
                return _DashItem(
                  value: item.value,
                  label: item.label,
                  subtitle: item.subtitle,
                  color: item.color,
                  icon: item.icon,
                  onTap: item.onTap,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMapaTab(
    BuildContext context,
    CaixaProvider caixaProvider,
    AlocacaoProvider alocacaoProvider,
  ) {
    final cafeProvider = Provider.of<CafeProvider>(context);
    final escalaProvider = Provider.of<EscalaProvider>(context);
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final plantaoProvider = Provider.of<PacotePlantaoProvider>(context);
    final outroSetorProvider = Provider.of<OutroSetorProvider>(context);

    final caixasTodos = caixaProvider.caixasTodos;
    final statuses = _coletarStatusesMapa(
      caixasTodos: caixasTodos,
      alocacaoProvider: alocacaoProvider,
      cafeProvider: cafeProvider,
      colaboradorProvider: colaboradorProvider,
      escalaProvider: escalaProvider,
    );
    final colabById = {
      for (final colaborador in colaboradorProvider.colaboradores)
        colaborador.id: colaborador,
    };

    final statusesFiltrados =
        statuses.where(_deveExibirStatus).toList(growable: false);
    final grupos = _agruparPorLocalizacao(statusesFiltrados);
    final balcoes = caixasTodos
        .where((caixa) => caixa.tipo == TipoCaixa.balcao)
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));
    final balcoesFiltrados = balcoes.where((balcao) {
      if (_filtroMapa != _MapaFiltro.todos &&
          _filtroMapa != _MapaFiltro.balcoes) {
        return false;
      }
      return _matchesBuscaBalcao(
        balcao,
        alocacaoProvider.getAlocacoesCaixa(balcao.id),
        colabById,
      );
    }).toList();

    final atrasosIntervalo =
        statuses.where((status) => status.isEmAtencao).length;
    final pausasEstouradas =
        statuses.where((status) => status.isPausaAtrasada).length;
    final aguardandoLiberacao = statuses.where((status) {
      final colaborador = status.colaboradorAtual;
      return status.isOcupado &&
          colaborador != null &&
          alocacaoProvider.isAguardandoIntervalo(colaborador.id);
    }).length;
    final manutencao = caixasTodos.where((caixa) => caixa.emManutencao).length;

    final excecoes = <_MapaExcecaoItem>[
      if (atrasosIntervalo > 0)
        _MapaExcecaoItem(
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
          label: '$atrasosIntervalo em atraso para intervalo',
          onTap: () => _aplicarFiltroMapa(_MapaFiltro.atencao),
        ),
      if (pausasEstouradas > 0)
        _MapaExcecaoItem(
          icon: Icons.coffee,
          color: AppColors.statusCafe,
          label: '$pausasEstouradas pausas estouradas',
          onTap: () => _aplicarFiltroMapa(_MapaFiltro.pausa),
        ),
      if (aguardandoLiberacao > 0)
        _MapaExcecaoItem(
          icon: Icons.pending_actions,
          color: AppColors.warning,
          label: '$aguardandoLiberacao aguardando liberacao',
          onTap: () => _aplicarFiltroMapa(_MapaFiltro.atencao),
        ),
      if (manutencao > 0)
        _MapaExcecaoItem(
          icon: Icons.build_outlined,
          color: AppColors.statusAtencao,
          label: '$manutencao em manutencao',
        ),
    ];

    final candidatosCobertura = [
      ...plantaoProvider.plantao
          .map((item) => colabById[item.colaboradorId]?.nome)
          .whereType<String>(),
      ...outroSetorProvider.lista
          .map((item) => colabById[item.colaboradorId]?.nome)
          .whereType<String>(),
    ];

    final sugestoes = <_MapaSugestaoItem>[];
    final atrasoPrincipal = statuses
        .where((status) => status.isEmAtencao)
        .toList()
      ..sort((a, b) => (b.minIntervalo ?? 0).compareTo(a.minIntervalo ?? 0));

    if (atrasoPrincipal.isNotEmpty) {
      final item = atrasoPrincipal.first;
      sugestoes.add(
        _MapaSugestaoItem(
          icon: Icons.restaurant_outlined,
          color: AppColors.danger,
          title: 'Priorize o proximo intervalo',
          subtitle:
              '${item.colaboradorAtual?.nome ?? item.caixa.nomeExibicao} esta no ${item.caixa.nomeExibicao} com ${item.minIntervalo ?? 0} min de atraso.',
          actionLabel: 'Ver atencao',
          onTap: () => _aplicarFiltroMapa(_MapaFiltro.atencao),
        ),
      );
    }

    if (pausasEstouradas > 0) {
      sugestoes.add(
        _MapaSugestaoItem(
          icon: Icons.coffee_outlined,
          color: AppColors.statusCafe,
          title: 'Finalize pausas vencidas primeiro',
          subtitle:
              'Ha $pausasEstouradas pausa(s) estourada(s) ocupando cobertura do mapa.',
          actionLabel: 'Ver pausas',
          onTap: () => _aplicarFiltroMapa(_MapaFiltro.pausa),
        ),
      );
    }

    if (atrasoPrincipal.isNotEmpty && candidatosCobertura.isNotEmpty) {
      final nomes = candidatosCobertura.take(2).join(', ');
      sugestoes.add(
        _MapaSugestaoItem(
          icon: Icons.swap_horiz,
          color: AppColors.primary,
          title: 'Sugestao de cobertura imediata',
          subtitle:
              'Use $nomes para cobrir o caixa e liberar ${atrasoPrincipal.first.colaboradorAtual?.nome ?? 'o colaborador'} para intervalo.',
          actionLabel: 'Ver cobertura',
          onTap: () => _aplicarFiltroMapa(_MapaFiltro.cobertura),
        ),
      );
    }

    if (statuses.where((status) => status.isDisponivel).isNotEmpty &&
        sugestoes.length < 3) {
      sugestoes.add(
        _MapaSugestaoItem(
          icon: Icons.point_of_sale_outlined,
          color: AppColors.success,
          title: 'Ha caixas livres para redistribuir',
          subtitle:
              'Ative a visualizacao de livres para antecipar trocas e retornos de pausa.',
          actionLabel: 'Ver livres',
          onTap: () => _aplicarFiltroMapa(
            _MapaFiltro.livres,
            mostrarLivres: true,
          ),
        ),
      );
    }

    final mostrarCobertura = _filtroMapa == _MapaFiltro.cobertura ||
        (_filtroMapa == _MapaFiltro.todos && _buscaMapa.trim().isEmpty);
    final mostrarBalcoes = (_filtroMapa == _MapaFiltro.todos ||
            _filtroMapa == _MapaFiltro.balcoes) &&
        balcoesFiltrados.isNotEmpty;
    final mostrarLocalizacoes = _filtroMapa != _MapaFiltro.balcoes &&
        _filtroMapa != _MapaFiltro.cobertura;
    final semResultadosLocal =
        mostrarLocalizacoes && grupos.values.every((itens) => itens.isEmpty);
    final totalVisiveisPainel = statusesFiltrados.length +
        (mostrarBalcoes ? balcoesFiltrados.length : 0);
    final totalGeralPainel = statuses.length + balcoes.length;
    final areasVisiveisPainel = grupos.length + (mostrarBalcoes ? 1 : 0);
    final secoesLocalizacao = grupos.entries
        .map((entry) => _buildLocalizacaoSection(entry.key, entry.value))
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 960
                ? (constraints.maxWidth - 960) / 2
                : Dimensions.hPad(constraints.maxWidth),
            vertical: Dimensions.paddingMD,
          ),
          child: Builder(
            builder: (context) {
              final larguraConteudo = constraints.maxWidth > 960
                  ? 960.0
                  : constraints.maxWidth -
                      (Dimensions.hPad(constraints.maxWidth) * 2);
              final insightsEmLinha = larguraConteudo >= 760;
              final localizacoesEmDuasColunas =
                  larguraConteudo >= 860 && secoesLocalizacao.length > 1;
              final larguraColuna = localizacoesEmDuasColunas
                  ? (larguraConteudo - 12) / 2
                  : larguraConteudo;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMapaDashboard(
                    context: context,
                    caixaProvider: caixaProvider,
                    alocacaoProvider: alocacaoProvider,
                    cafeProvider: cafeProvider,
                    colaboradorProvider: colaboradorProvider,
                    plantaoProvider: plantaoProvider,
                    outroSetorProvider: outroSetorProvider,
                    statuses: statuses,
                    localizacoesVisiveis: grupos.length,
                  ),
                  SizedBox(height: Dimensions.spacingMD),
                  _buildMapaControlesCard(
                    totalVisiveis: totalVisiveisPainel,
                    totalGeral: totalGeralPainel,
                    localizacoes: areasVisiveisPainel,
                  ),
                  if (excecoes.isNotEmpty || sugestoes.isNotEmpty) ...[
                    SizedBox(height: Dimensions.spacingMD),
                    if (insightsEmLinha &&
                        excecoes.isNotEmpty &&
                        sugestoes.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildExcecoesFaixa(excecoes)),
                          SizedBox(width: Dimensions.spacingSM),
                          Expanded(child: _buildSugestoesCard(sugestoes)),
                        ],
                      )
                    else ...[
                      _buildExcecoesFaixa(excecoes),
                      if (excecoes.isNotEmpty && sugestoes.isNotEmpty)
                        SizedBox(height: Dimensions.spacingMD),
                      _buildSugestoesCard(sugestoes),
                    ],
                  ],
                  SizedBox(height: Dimensions.spacingLG),
                  if (semResultadosLocal &&
                      !mostrarBalcoes &&
                      !mostrarCobertura)
                    const EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'Nenhum resultado no mapa',
                      message:
                          'Ajuste a busca ou troque os filtros para continuar.',
                    ),
                  if (mostrarLocalizacoes && secoesLocalizacao.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'Mapa por localizacao',
                      count: secoesLocalizacao.length,
                    ),
                    SizedBox(height: Dimensions.spacingXS),
                    Text(
                      'As areas abaixo ja aparecem priorizadas por atencao, pausa e ocupacao.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingSM),
                    if (localizacoesEmDuasColunas)
                      Wrap(
                        spacing: Dimensions.spacingSM,
                        runSpacing: Dimensions.spacingSM,
                        children: secoesLocalizacao
                            .map(
                              (secao) => SizedBox(
                                width: larguraColuna,
                                child: secao,
                              ),
                            )
                            .toList(),
                      )
                    else
                      ...secoesLocalizacao.map(
                        (secao) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: Dimensions.spacingSM),
                          child: secao,
                        ),
                      ),
                    SizedBox(height: Dimensions.spacingLG),
                  ],
                  if (mostrarBalcoes) ...[
                    _SectionHeader(
                      label: 'Balcoes',
                      count: balcoesFiltrados.length,
                    ),
                    SizedBox(height: Dimensions.spacingXS),
                    Text(
                      'Separados do mapa principal para leitura mais rapida de frente de loja.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingSM),
                    ...balcoesFiltrados.map((balcao) {
                      final alocacoes =
                          alocacaoProvider.getAlocacoesCaixa(balcao.id);
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: Dimensions.spacingSM,
                        ),
                        child: BalcaoListItem(
                          balcao: balcao,
                          alocacoes: alocacoes,
                        ),
                      );
                    }),
                    SizedBox(height: Dimensions.spacingLG),
                  ],
                  if (mostrarCobertura) ...[
                    _SectionHeader(
                      label: 'Cobertura e apoio',
                      count: 2,
                    ),
                    SizedBox(height: Dimensions.spacingXS),
                    Text(
                      'Use estas listas para decidir trocas e reforcos fora do mapa.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingSM),
                    const PacoteSection(),
                    SizedBox(height: Dimensions.spacingMD),
                    const OutroSetorSection(),
                    SizedBox(height: Dimensions.spacingMD),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caixaProvider = Provider.of<CaixaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mapa de Caixas'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_tabIndex == 0)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadData,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Mapa'),
            Tab(
                icon: Icon(Icons.point_of_sale_outlined, size: 18),
                text: 'Caixas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ABA 1: MAPA ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

          Builder(
            builder: (context) =>
                _buildMapaTab(context, caixaProvider, alocacaoProvider),
          ),
          // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ABA 2: CAIXAS ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
          _CaixasBody(onRefresh: _loadData),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CaixaFormScreen(),
                  ),
                );
                _loadData();
              },
              icon: Icon(Icons.add),
              label: Text('Novo Caixa'),
              backgroundColor: AppColors.success,
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Aba "Caixas" ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _CaixasBody extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CaixasBody({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final caixaProvider = Provider.of<CaixaProvider>(context);

    if (caixaProvider.isLoading) {
      return const LoadingWidget(message: 'Carregando caixas...');
    }

    return Column(
      children: [
        // Stats
        _StatsBar(provider: caixaProvider),

        // Filtro
        _FilterBar(provider: caixaProvider),

        // Lista
        Expanded(
          child: caixaProvider.caixas.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.point_of_sale,
                  title: 'Nenhum caixa',
                  message: 'VocÃƒÆ’Ã‚Âª nÃƒÆ’Ã‚Â£o possui caixas cadastrados',
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = MediaQuery.sizeOf(context).width;
                      final cols = w >= Dimensions.breakpointWide
                          ? 6
                          : w >= Dimensions.breakpointTablet
                              ? 4
                              : 3;
                      return GridView.builder(
                        padding: const EdgeInsets.all(Dimensions.paddingMD),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: Dimensions.spacingSM,
                          mainAxisSpacing: Dimensions.spacingSM,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: caixaProvider.caixas.length,
                        itemBuilder: (_, i) =>
                            CaixaGridCard(caixa: caixaProvider.caixas[i]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final CaixaProvider provider;

  const _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
              label: 'Ativos',
              value: provider.totalAtivos.toString(),
              color: AppColors.success),
          _StatItem(
              label: 'ManutenÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o',
              value: provider.totalEmManutencao.toString(),
              color: Colors.orange),
          _StatItem(
              label: 'Inativos',
              value: provider.totalInativos.toString(),
              color: AppColors.textSecondary),
          _StatItem(
              label: 'Total',
              value: provider.totalCaixas.toString(),
              color: AppColors.primary),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3
                .copyWith(color: color, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final CaixaProvider provider;

  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      child: GestureDetector(
        onTap: () => provider.toggleFiltroAtivos(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMD,
            vertical: Dimensions.paddingSM,
          ),
          decoration: BoxDecoration(
            color: provider.mostrarApenasAtivos
                ? AppColors.primary
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            border: Border.all(
              color: provider.mostrarApenasAtivos
                  ? AppColors.primary
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list,
                color: provider.mostrarApenasAtivos
                    ? Colors.white
                    : AppColors.textPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                provider.mostrarApenasAtivos ? 'Apenas Ativos' : 'Ver Todos',
                style: AppTextStyles.label.copyWith(
                  color: provider.mostrarApenasAtivos
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: provider.mostrarApenasAtivos
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ SeÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o com cabeÃƒÆ’Ã‚Â§alho e contador ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.h3),
        SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.backgroundSection,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashItem extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _DashItem({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      decoration: AppStyles.softCard(
        tint: color,
        radius: Dimensions.radiusMD,
        elevated: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: color.withValues(alpha: 0.70),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusMD),
      child: child,
    );
  }
}

class _OcupadosSheet extends StatelessWidget {
  final List<Caixa> caixas;
  final List<Caixa> caixasTodos;
  final AlocacaoProvider alocacaoProvider;
  final CafeProvider cafeProvider;
  final Map<String, Colaborador> colabById;

  const _OcupadosSheet({
    required this.caixas,
    required this.caixasTodos,
    required this.alocacaoProvider,
    required this.cafeProvider,
    required this.colabById,
  });

  @override
  Widget build(BuildContext context) {
    final temOcupados = caixas.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Icon(Icons.point_of_sale, size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Caixas ocupados', style: AppTextStyles.h3),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Mostra quais caixas estÃƒÆ’Ã‚Â£o contando como ocupados.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12),
          if (!temOcupados)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhum caixa ocupado no momento.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: caixas.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 16, color: AppColors.cardBorder),
                itemBuilder: (_, i) {
                  final caixa = caixas[i];
                  final alocacao = alocacaoProvider.getAlocacaoCaixa(caixa.id);
                  final pausa = cafeProvider.getPausaAtivaPorCaixa(caixa.id);

                  final nomeAlocado = alocacao != null
                      ? (colabById[alocacao.colaboradorId]?.nome ??
                          caixa.colaboradorAlocadoNome ??
                          'ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â')
                      : null;
                  final nomePausa = pausa?.colaboradorNome;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _mostrarAcoes(
                      context,
                      caixa,
                      alocacao,
                      pausa,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        caixa.numero.toString(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(caixa.nomeExibicao),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nomeAlocado != null)
                          Text(
                            'Alocado: $nomeAlocado',
                            style: AppTextStyles.caption,
                          ),
                        if (nomePausa != null)
                          Text(
                            'Em pausa: $nomePausa',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.statusCafe,
                            ),
                          ),
                        if (nomeAlocado == null && nomePausa == null)
                          Text(
                            'Sem detalhes da ocupaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                    trailing: (alocacao != null || pausa != null)
                        ? Icon(Icons.more_vert, size: 18)
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarAcoes(
    BuildContext context,
    Caixa caixa,
    Alocacao? alocacao,
    PausaCafe? pausa,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.point_of_sale, size: 18, color: AppColors.primary),
                SizedBox(width: 6),
                Text(caixa.nomeExibicao, style: AppTextStyles.h3),
              ],
            ),
            SizedBox(height: 8),
            if (alocacao != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.exit_to_app, color: AppColors.danger),
                title: Text('Liberar caixa'),
                subtitle:
                    Text('Remove a alocaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o ativa deste caixa'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarLiberar(context, caixa, alocacao);
                },
              ),
            if (pausa != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.coffee, color: AppColors.statusCafe),
                title: Text('Finalizar pausa'),
                subtitle: Text('Encerra a pausa ativa deste caixa'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarFinalizarPausa(context, pausa);
                },
              ),
            if (alocacao == null && pausa == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'NÃƒÆ’Ã‚Â£o hÃƒÆ’Ã‚Â¡ alocaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o ou pausa ativa para este caixa.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmarLiberar(
    BuildContext context,
    Caixa caixa,
    Alocacao alocacao,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Liberar caixa'),
        content: Text('Deseja liberar ${caixa.nomeExibicao}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await alocacaoProvider.liberarAlocacao(
                alocacao.id,
                'Liberado pelo mapa (lista de ocupados)',
              );
              if (context.mounted) {
                AppNotif.show(
                  context,
                  titulo: 'Caixa liberado',
                  mensagem: '${caixa.nomeExibicao} foi liberado.',
                  tipo: 'saida',
                  cor: AppColors.success,
                );
              }
            },
            child: Text(
              'Liberar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarFinalizarPausa(
    BuildContext context,
    PausaCafe pausa,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Finalizar pausa'),
        content: Text('Deseja finalizar a pausa de ${pausa.colaboradorNome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final fiscalId =
                  Provider.of<AuthProvider>(context, listen: false).user?.id ??
                      '';
              if (fiscalId.isEmpty) {
                if (context.mounted) {
                  AppNotif.show(
                    context,
                    titulo: 'Erro',
                    mensagem: 'Usuario nao autenticado para finalizar pausa.',
                    tipo: 'alerta',
                    cor: AppColors.danger,
                  );
                }
                return;
              }

              String? erro;
              if (pausa.isIntervalo) {
                final escolha = await _escolherRetornoIntervalo(context, pausa);
                if (escolha == null) return;
                erro = await cafeProvider.finalizarPausaComRegra(
                  pausa: pausa,
                  alocacaoProvider: alocacaoProvider,
                  fiscalId: fiscalId,
                  caixaDestinoIntervaloId: escolha.caixaDestinoId,
                  permitirMesmoCaixaNoIntervalo: escolha.permitirMesmoCaixa,
                  justificativaMesmoCaixa: escolha.justificativaMesmoCaixa,
                );
              } else {
                erro = await cafeProvider.finalizarPausaComRegra(
                  pausa: pausa,
                  alocacaoProvider: alocacaoProvider,
                  fiscalId: fiscalId,
                );
              }

              if (context.mounted) {
                if (erro == null) {
                  AppNotif.show(
                    context,
                    titulo: 'Pausa finalizada',
                    mensagem: pausa.isCafe
                        ? 'Pausa de ${pausa.colaboradorNome} finalizada com retorno ao caixa.'
                        : 'Pausa de ${pausa.colaboradorNome} finalizada com realocacao.',
                    tipo: 'saida',
                    cor: AppColors.success,
                  );
                } else {
                  AppNotif.show(
                    context,
                    titulo: 'Pausa finalizada',
                    mensagem: erro,
                    tipo: 'alerta',
                    cor: AppColors.warning,
                  );
                }
              }
            },
            child: Text(
              'Finalizar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<_RetornoIntervaloEscolha?> _escolherRetornoIntervalo(
    BuildContext context,
    PausaCafe pausa,
  ) async {
    final caixasAtivos = caixasTodos
        .where((c) => c.ativo && !c.emManutencao)
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));
    final caixasLivres = caixasAtivos
        .where((c) => alocacaoProvider.getAlocacaoCaixa(c.id) == null)
        .toList();

    if (caixasLivres.isEmpty) {
      if (context.mounted) {
        AppNotif.show(
          context,
          titulo: 'Sem caixa disponivel',
          mensagem: 'Nao ha caixa livre para retorno do intervalo.',
          tipo: 'alerta',
          cor: AppColors.warning,
        );
      }
      return null;
    }

    String? caixaSelecionadoId = caixasLivres
        .where((c) => c.id != pausa.caixaId)
        .map((c) => c.id)
        .firstOrNull;
    caixaSelecionadoId ??= caixasLivres.first.id;
    bool permitirMesmoCaixa = false;
    final justificativaCtrl = TextEditingController();

    final escolha = await showDialog<_RetornoIntervaloEscolha>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final mesmoCaixaSelecionado = pausa.caixaId != null &&
              pausa.caixaId!.isNotEmpty &&
              caixaSelecionadoId == pausa.caixaId;
          final precisaJustificativa =
              mesmoCaixaSelecionado && permitirMesmoCaixa;
          final podeConfirmar = caixaSelecionadoId != null &&
              (!precisaJustificativa ||
                  justificativaCtrl.text.trim().isNotEmpty);

          return AlertDialog(
            title: Text('Retorno do intervalo'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: caixaSelecionadoId,
                  onChanged: (v) =>
                      setStateDialog(() => caixaSelecionadoId = v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Regra padrao: retornar em caixa diferente.'),
                      SizedBox(height: 12),
                      ...caixasAtivos.map((caixa) {
                        final ocupado =
                            alocacaoProvider.getAlocacaoCaixa(caixa.id) != null;
                        Widget tile = RadioListTile<String>(
                          value: caixa.id,
                          title: Text(caixa.nomeExibicao),
                          subtitle:
                              Text(ocupado ? 'Ocupado agora' : 'Disponivel'),
                          dense: true,
                        );
                        if (ocupado) {
                          tile = Opacity(
                            opacity: 0.5,
                            child: IgnorePointer(child: tile),
                          );
                        }
                        return tile;
                      }),
                      if (mesmoCaixaSelecionado) ...[
                        SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: permitirMesmoCaixa,
                          onChanged: (v) => setStateDialog(
                            () => permitirMesmoCaixa = v ?? false,
                          ),
                          title: Text('Permitir mesmo caixa (excecao)'),
                          subtitle: Text(
                            'Necessario justificar para auditoria.',
                          ),
                        ),
                        if (permitirMesmoCaixa) ...[
                          SizedBox(height: 8),
                          TextField(
                            controller: justificativaCtrl,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Justificativa da excecao *',
                            ),
                            onChanged: (_) => setStateDialog(() {}),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: !podeConfirmar
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          _RetornoIntervaloEscolha(
                            caixaDestinoId: caixaSelecionadoId!,
                            permitirMesmoCaixa: permitirMesmoCaixa,
                            justificativaMesmoCaixa:
                                justificativaCtrl.text.trim().isEmpty
                                    ? null
                                    : justificativaCtrl.text.trim(),
                          ),
                        ),
                child: Text('Confirmar retorno'),
              ),
            ],
          );
        },
      ),
    );

    justificativaCtrl.dispose();
    return escolha;
  }
}

class _PausasSheet extends StatelessWidget {
  final List<PausaCafe> pausas;
  final List<Caixa> caixasTodos;

  const _PausasSheet({
    required this.pausas,
    required this.caixasTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Icon(Icons.coffee, size: 18, color: AppColors.statusCafe),
              SizedBox(width: 6),
              Text('Pausas ativas', style: AppTextStyles.h3),
            ],
          ),
          SizedBox(height: 12),
          if (pausas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhuma pausa ativa no momento.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pausas.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 16, color: AppColors.cardBorder),
                itemBuilder: (_, i) {
                  final pausa = pausas[i];
                  final caixa = caixasTodos
                      .where((item) => item.id == pausa.caixaId)
                      .firstOrNull;
                  final titulo = pausa.isCafe ? 'Cafe' : 'Intervalo';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.statusCafe.withValues(alpha: 0.12),
                      child: Icon(
                        pausa.isCafe ? Icons.coffee : Icons.restaurant,
                        color: AppColors.statusCafe,
                        size: 18,
                      ),
                    ),
                    title: Text(pausa.colaboradorNome),
                    subtitle: Text(
                      '${caixa?.nomeExibicao ?? 'Sem caixa'} - $titulo ha ${pausa.minutosDecorridos} min',
                      style: AppTextStyles.caption,
                    ),
                    trailing: pausa.emAtraso
                        ? Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.danger,
                          )
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LivresSheet extends StatelessWidget {
  final List<_MapaCaixaStatus> statuses;

  const _LivresSheet({required this.statuses});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Icon(Icons.point_of_sale, size: 18, color: AppColors.success),
              SizedBox(width: 6),
              Text('Caixas livres', style: AppTextStyles.h3),
            ],
          ),
          SizedBox(height: 12),
          if (statuses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhum caixa livre no momento.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: statuses.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 16, color: AppColors.cardBorder),
                itemBuilder: (_, i) {
                  final status = statuses[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.success.withValues(alpha: 0.12),
                      child: Text(
                        status.caixa.numero.toString(),
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(status.caixa.nomeExibicao),
                    subtitle: Text(
                      status.localizacaoLabel,
                      style: AppTextStyles.caption,
                    ),
                    trailing: Text(
                      status.caixa.tipo.nome,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CoberturaSheet extends StatelessWidget {
  final List<Alocacao> alocacoes;
  final List<PacotePlantao> plantao;
  final List<OutroSetor> outroSetor;
  final List<Caixa> caixasTodos;
  final Map<String, Colaborador> colabById;

  const _CoberturaSheet({
    required this.alocacoes,
    required this.plantao,
    required this.outroSetor,
    required this.caixasTodos,
    required this.colabById,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.groups_2_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 6),
                Text('Cobertura da operacao', style: AppTextStyles.h3),
              ],
            ),
            SizedBox(height: 12),
            _SectionHeader(
              label: 'No caixa',
              count: alocacoes.length,
            ),
            SizedBox(height: 8),
            if (alocacoes.isEmpty)
              Text('Nenhuma alocacao ativa.', style: AppTextStyles.caption)
            else
              ...alocacoes.map((alocacao) {
                final caixa = caixasTodos
                    .where((item) => item.id == alocacao.caixaId)
                    .firstOrNull;
                final colaborador = colabById[alocacao.colaboradorId];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    Icons.point_of_sale,
                    color: AppColors.primary,
                  ),
                  title: Text(colaborador?.nome ?? 'Colaborador'),
                  subtitle: Text(
                    caixa?.nomeExibicao ?? 'Caixa sem identificacao',
                    style: AppTextStyles.caption,
                  ),
                );
              }),
            SizedBox(height: 12),
            _SectionHeader(
              label: 'Pacotes',
              count: plantao.length,
            ),
            SizedBox(height: 8),
            if (plantao.isEmpty)
              Text('Sem cobertura em pacotes.', style: AppTextStyles.caption)
            else
              ...plantao.map((item) {
                final colaborador = colabById[item.colaboradorId];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.success,
                  ),
                  title: Text(colaborador?.nome ?? 'Colaborador'),
                  subtitle: Text(
                    'Empacotador disponivel na cobertura',
                    style: AppTextStyles.caption,
                  ),
                );
              }),
            SizedBox(height: 12),
            _SectionHeader(
              label: 'Outro setor',
              count: outroSetor.length,
            ),
            SizedBox(height: 8),
            if (outroSetor.isEmpty)
              Text('Sem apoio em outro setor.', style: AppTextStyles.caption)
            else
              ...outroSetor.map((item) {
                final colaborador = colabById[item.colaboradorId];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    Icons.storefront_outlined,
                    color: AppColors.statusAtencao,
                  ),
                  title: Text(colaborador?.nome ?? 'Colaborador'),
                  subtitle: Text(item.setor, style: AppTextStyles.caption),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RetornoIntervaloEscolha {
  final String caixaDestinoId;
  final bool permitirMesmoCaixa;
  final String? justificativaMesmoCaixa;

  const _RetornoIntervaloEscolha({
    required this.caixaDestinoId,
    required this.permitirMesmoCaixa,
    this.justificativaMesmoCaixa,
  });
}
