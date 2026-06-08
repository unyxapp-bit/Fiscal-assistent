import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_notif.dart';
import '../../../data/services/entrega_cupom_ai_service.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../widgets/common/operational_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/evento_turno_provider.dart';
import 'entrega_form_screen.dart';
import 'entrega_detail_screen.dart';

class EntregasScreen extends StatefulWidget {
  const EntregasScreen({super.key});

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _CupomImagePayload {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const _CupomImagePayload({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}

class _EntregasScreenState extends State<EntregasScreen> {
  final _searchCtrl = TextEditingController();
  String _filtroStatus = 'todos';
  String _filtroCidade = 'todas';
  String _busca = '';
  bool _ordenacaoDescendente = true;
  bool _processandoCupom = false;
  final _cupomAiService = EntregaCupomAiService();
  final _imagePicker = ImagePicker();
  static const _cupomMaxLongSide = 1280;
  static const _cupomJpegQuality = 72;

  static const _statusOptions = [
    ('todos', 'Todos'),
    ('separada', 'Separada'),
    ('em_rota', 'Em Rota'),
    ('entregue', 'Entregue'),
    ('cancelada', 'Cancelada'),
  ];

  List<String> _getCidades(List<Entrega> entregas) {
    final cidades = entregas.map((e) => e.cidade).toSet().toList()..sort();
    return cidades;
  }

  List<Entrega> _aplicarFiltros(List<Entrega> entregas) {
    final filtradas = entregas.where((e) {
      final statusOk = _filtroStatus == 'todos' || e.status == _filtroStatus;
      final cidadeOk = _filtroCidade == 'todas' || e.cidade == _filtroCidade;
      final buscaOk = _busca.isEmpty ||
          e.numeroNota.toLowerCase().contains(_busca) ||
          e.clienteNome.toLowerCase().contains(_busca) ||
          e.bairro.toLowerCase().contains(_busca) ||
          e.cidade.toLowerCase().contains(_busca);
      return statusOk && cidadeOk && buscaOk;
    }).toList();
    filtradas.sort((a, b) => _ordenacaoDescendente
        ? b.separadoEm.compareTo(a.separadoEm)
        : a.separadoEm.compareTo(b.separadoEm));
    return filtradas;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarCupomUpload() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
      maxHeight: 2200,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final payload = _prepararImagemCupom(
      bytes: bytes,
      fileName: image.name,
      mimeType: image.mimeType ??
          EntregaCupomAiService.mimeTypeForFileName(image.name),
    );
    await _analisarCupom(
      bytes: payload.bytes,
      fileName: payload.fileName,
      mimeType: payload.mimeType,
    );
  }

  Future<void> _tirarFotoCupom() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1400,
        maxHeight: 2200,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final payload = _prepararImagemCupom(
        bytes: bytes,
        fileName: image.name,
        mimeType: image.mimeType ??
            EntregaCupomAiService.mimeTypeForFileName(image.name),
      );
      await _analisarCupom(
        bytes: payload.bytes,
        fileName: payload.fileName,
        mimeType: payload.mimeType,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotif.show(
        context,
        titulo: 'Camera indisponivel',
        mensagem:
            'Nao foi possivel abrir a camera. Tente enviar a foto pelo upload.',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    }
  }

  _CupomImagePayload _prepararImagemCupom({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return _CupomImagePayload(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    final oriented = img.bakeOrientation(decoded);
    final longSide =
        oriented.width > oriented.height ? oriented.width : oriented.height;
    final scale =
        longSide > _cupomMaxLongSide ? _cupomMaxLongSide / longSide : 1.0;
    final resized = scale < 1
        ? img.copyResize(
            oriented,
            width: (oriented.width * scale).round(),
            height: (oriented.height * scale).round(),
          )
        : oriented;
    final encoded = img.encodeJpg(resized, quality: _cupomJpegQuality);

    return _CupomImagePayload(
      bytes: Uint8List.fromList(encoded),
      fileName: _cupomJpegFileName(fileName),
      mimeType: 'image/jpeg',
    );
  }

  String _cupomJpegFileName(String fileName) {
    final clean = fileName.trim();
    final base = clean.isEmpty
        ? 'cupom-entrega'
        : clean.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return '$base.jpg';
  }

  Future<void> _analisarCupom({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (_processandoCupom) return;

    setState(() => _processandoCupom = true);
    try {
      final draft = await _cupomAiService.extractFromImage(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      if (!mounted) return;
      await _abrirPreviaCupom(draft);
    } catch (e) {
      if (!mounted) return;
      AppNotif.show(
        context,
        titulo: 'IA nao analisou',
        mensagem: '$e',
        tipo: 'alerta',
        cor: AppColors.danger,
        duracao: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _processandoCupom = false);
    }
  }

  Future<void> _abrirPreviaCupom(EntregaCupomDraft draft) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CupomEntregaPreviewSheet(
        draft: draft,
        onCreate: draft.canCreate
            ? () {
                Navigator.of(sheetContext).pop();
                _criarEntregaDoCupom(draft);
              }
            : null,
        onEdit: () {
          Navigator.of(sheetContext).pop();
          _abrirFormularioComDraft(draft);
        },
      ),
    );
  }

  Future<void> _abrirFormularioComDraft(EntregaCupomDraft draft) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntregaFormScreen(draft: draft)),
    );
  }

  void _criarEntregaDoCupom(EntregaCupomDraft draft) {
    final pendentes = draft.requiredMissingFields;
    if (pendentes.isNotEmpty) {
      AppNotif.show(
        context,
        titulo: 'Revise o cupom',
        mensagem: 'Campos pendentes: ${pendentes.join(', ')}.',
        tipo: 'alerta',
        cor: AppColors.statusAtencao,
        duracao: const Duration(seconds: 4),
      );
      _abrirFormularioComDraft(draft);
      return;
    }

    final entregaProvider = context.read<EntregaProvider>();
    entregaProvider.adicionarEntrega(
      numeroNota: draft.numeroNota.trim(),
      clienteNome: draft.clienteNome.trim(),
      telefone: draft.telefone.trim().isEmpty ? null : draft.telefone.trim(),
      endereco: draft.endereco.trim(),
      bairro: draft.bairro.trim(),
      cidade: draft.cidade.trim(),
      observacoes: draft.observacoesParaSalvar(),
      horarioMarcado: draft.horarioMarcado,
    );

    final eventoProvider = context.read<EventoTurnoProvider>();
    if (eventoProvider.turnoAtivo) {
      final fiscalId = context.read<AuthProvider>().user?.id ?? '';
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.entregaCadastrada,
        detalhe: 'NF ${draft.numeroNota.trim()} - ${draft.clienteNome.trim()}',
      );
    }

    _searchCtrl.clear();
    setState(() {
      _busca = '';
      _filtroStatus = 'separada';
      _filtroCidade = 'todas';
      _ordenacaoDescendente = true;
    });

    AppNotif.show(
      context,
      titulo: 'Entrega criada',
      mensagem: 'Entrega criada a partir do cupom lido pela IA.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  Future<bool> _confirmarExcluirEntrega(Entrega entrega) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          entrega.status == 'entregue'
              ? 'Excluir entrega concluida?'
              : 'Excluir entrega?',
        ),
        content: Text(
          'Remover a NF ${entrega.numeroNota} de "${entrega.clienteNome}"? '
          'Essa acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<bool> _confirmarExcluirTodasConcluidas(int total) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir entregas concluidas?'),
        content: Text(
          'Serao removidas $total entrega(s) concluidas. '
          'Entregas separadas, em rota ou canceladas nao serao afetadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir todas'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  void _notificarEntregaRemovida(Entrega entrega) {
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Entrega excluida',
      mensagem: 'NF ${entrega.numeroNota} removida.',
      tipo: 'alerta',
      cor: AppColors.danger,
    );
  }

  Future<void> _excluirEntrega(
    EntregaProvider provider,
    Entrega entrega,
  ) async {
    if (!await _confirmarExcluirEntrega(entrega)) return;
    provider.removerEntrega(entrega.id);
    _notificarEntregaRemovida(entrega);
  }

  Future<void> _excluirTodasConcluidas(EntregaProvider provider) async {
    final total = provider.totalEntregues;
    if (total == 0) return;
    if (!await _confirmarExcluirTodasConcluidas(total)) return;

    provider.removerEntregasConcluidas();
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Entregas excluidas',
      mensagem: '$total entrega(s) concluidas removidas.',
      tipo: 'alerta',
      cor: AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntregaProvider>(context);
    final cidades = _getCidades(provider.entregas);
    final entregasFiltradas = _aplicarFiltros(provider.entregas);
    final abertas = provider.totalSeparadas + provider.totalEmRota;
    final canceladas =
        provider.entregas.where((e) => e.status == 'cancelada').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EntregaFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova entrega'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            Provider.of<EntregaProvider>(context, listen: false).load(),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              Dimensions.operationalHPad(constraints.maxWidth),
              14,
              Dimensions.operationalHPad(constraints.maxWidth),
              110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OperationalReferenceHeader(
                  eyebrow: 'Operação',
                  title: 'Entregas',
                  statusLabel: abertas > 0
                      ? _pluralize(
                          abertas,
                          'entrega em andamento',
                          'entregas em andamento',
                        )
                      : 'Entregas em dia',
                  subtitle: '${provider.entregas.length} registro(s) hoje',
                  statusIcon: abertas > 0
                      ? Icons.local_shipping_outlined
                      : Icons.check_circle_rounded,
                  statusColor:
                      abertas > 0 ? AppColors.statusAtencao : AppColors.success,
                  alertCount: abertas,
                  onBack: Navigator.of(context).canPop()
                      ? () => Navigator.pop(context)
                      : null,
                  actions: [
                    if (_processandoCupom)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    else ...[
                      IconButton.filledTonal(
                        icon: const Icon(Icons.upload_file_rounded),
                        tooltip: 'Enviar foto do cupom',
                        onPressed: _selecionarCupomUpload,
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.photo_camera_outlined),
                        tooltip: 'Tirar foto do cupom',
                        onPressed: _tirarFotoCupom,
                      ),
                    ],
                    IconButton.filledTonal(
                      icon: Icon(
                        _ordenacaoDescendente
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                      ),
                      tooltip: _ordenacaoDescendente
                          ? 'Mais recentes primeiro'
                          : 'Mais antigos primeiro',
                      onPressed: _processandoCupom
                          ? null
                          : () => setState(
                                () => _ordenacaoDescendente =
                                    !_ordenacaoDescendente,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OperationalHeroPanel(
                  title: 'Central de entregas',
                  subtitle:
                      'Acompanhe separação, rota e conclusão das entregas do turno.',
                  icon: Icons.local_shipping_outlined,
                  metrics: [
                    OperationalHeroMetric(
                      value: provider.totalSeparadas.toString(),
                      label: 'Separadas',
                      icon: Icons.inventory_2_outlined,
                    ),
                    OperationalHeroMetric(
                      value: provider.totalEmRota.toString(),
                      label: 'Em rota',
                      icon: Icons.route_rounded,
                    ),
                    OperationalHeroMetric(
                      value: provider.totalEntregues.toString(),
                      label: 'Entregues',
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReferenceKpiRows(
                  children: [
                    OperationalReferenceKpiCard(
                      icon: Icons.inventory_2_outlined,
                      value: provider.totalSeparadas.toString(),
                      title: 'Separadas',
                      subtitle: 'Aguardando rota',
                      color: AppColors.statusAtencao,
                      onTap: () => setState(() => _filtroStatus = 'separada'),
                    ),
                    OperationalReferenceKpiCard(
                      icon: Icons.route_rounded,
                      value: provider.totalEmRota.toString(),
                      title: 'Em rota',
                      subtitle: 'Saiu para entrega',
                      color: AppColors.primary,
                      onTap: () => setState(() => _filtroStatus = 'em_rota'),
                    ),
                    OperationalReferenceKpiCard(
                      icon: Icons.check_circle_outline,
                      value: provider.totalEntregues.toString(),
                      title: 'Entregues',
                      subtitle: 'Finalizadas',
                      color: AppColors.success,
                      onTap: () => setState(() => _filtroStatus = 'entregue'),
                    ),
                    OperationalReferenceKpiCard(
                      icon: Icons.cancel_outlined,
                      value: canceladas.toString(),
                      title: 'Canceladas',
                      subtitle: 'Sem conclusão',
                      color: AppColors.danger,
                      onTap: () => setState(() => _filtroStatus = 'cancelada'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppSurface(
                  elevated: false,
                  padding: const EdgeInsets.all(Dimensions.paddingSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OperationalSearchField(
                        controller: _searchCtrl,
                        hintText: 'Buscar nota, cliente, bairro ou cidade',
                        showClear: _busca.isNotEmpty,
                        onClear: () {
                          _searchCtrl.clear();
                          setState(() => _busca = '');
                        },
                        onChanged: (v) =>
                            setState(() => _busca = v.toLowerCase().trim()),
                      ),
                      const SizedBox(height: Dimensions.spacingSM),
                      OperationalFilterChips<String>(
                        selected: _filtroStatus,
                        onSelected: (value) =>
                            setState(() => _filtroStatus = value),
                        options: [
                          for (final opt in _statusOptions)
                            OperationalChipOption<String>(
                              value: opt.$1,
                              label: opt.$2,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                      if (cidades.isNotEmpty) ...[
                        const SizedBox(height: Dimensions.spacingXS),
                        OperationalFilterChips<String>(
                          selected: _filtroCidade,
                          onSelected: (value) =>
                              setState(() => _filtroCidade = value),
                          options: [
                            const OperationalChipOption<String>(
                              value: 'todas',
                              label: 'Todas cidades',
                              icon: Icons.location_city_outlined,
                            ),
                            for (final cidade in cidades)
                              OperationalChipOption<String>(
                                value: cidade,
                                label: cidade,
                                icon: Icons.place_outlined,
                                color: AppColors.statusIntervalo,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (_filtroStatus == 'entregue' &&
                    provider.totalEntregues > 0) ...[
                  const SizedBox(height: 12),
                  _EntregasCompletedActionBar(
                    count: provider.totalEntregues,
                    onDeleteAll: () => _excluirTodasConcluidas(provider),
                  ),
                ],
                const SizedBox(height: 18),
                _EntregasListHeader(
                  count: entregasFiltradas.length,
                  completedCount: provider.totalEntregues,
                  onDeleteCompleted: provider.totalEntregues > 0
                      ? () => _excluirTodasConcluidas(provider)
                      : null,
                ),
                const SizedBox(height: 10),
                if (entregasFiltradas.isEmpty)
                  OperationalEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: provider.entregas.isEmpty
                        ? 'Nenhuma entrega cadastrada'
                        : 'Nada encontrado',
                    message: provider.entregas.isEmpty
                        ? 'Cadastre a primeira entrega para acompanhar a rota.'
                        : 'Ajuste os filtros ou limpe a busca para ver mais entregas.',
                    actionLabel:
                        provider.entregas.isEmpty ? 'Cadastrar entrega' : null,
                    onAction: provider.entregas.isEmpty
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EntregaFormScreen(),
                              ),
                            )
                        : null,
                  )
                else
                  Column(
                    children: [
                      for (final entrega in entregasFiltradas)
                        Dismissible(
                          key: Key(entrega.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) =>
                              _confirmarExcluirEntrega(entrega),
                          onDismissed: (_) {
                            provider.removerEntrega(entrega.id);
                            _notificarEntregaRemovida(entrega);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(
                              bottom: Dimensions.spacingSM,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusMD),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: _EntregaReferenceCard(
                            entrega: entrega,
                            statusColor: _getStatusColor(entrega.status),
                            statusIcon: _getStatusIcon(entrega.status),
                            statusLabel: _getStatusLabel(entrega.status),
                            onDelete: entrega.status == 'entregue'
                                ? () => _excluirEntrega(provider, entrega)
                                : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EntregaDetailScreen(entrega: entrega),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                if (entregasFiltradas.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const ReferenceSectionTitle(
                    title: 'Últimas movimentações',
                    action: 'Hoje',
                  ),
                  const SizedBox(height: 10),
                  OperationalTimelineCard(
                    entries: entregasFiltradas.take(4).map((entrega) {
                      return OperationalTimelineEntry(
                        time: _formatHour(entrega.separadoEm),
                        icon: _getStatusIcon(entrega.status),
                        title: entrega.clienteNome,
                        subtitle:
                            'NF ${entrega.numeroNota} - ${_getStatusLabel(entrega.status)}',
                        color: _getStatusColor(entrega.status),
                      );
                    }).toList(),
                    emptyTitle: 'Sem movimentações',
                    emptySubtitle: 'As entregas do turno aparecem aqui.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatHour(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _pluralize(int value, String singular, String plural) {
    return '$value ${value == 1 ? singular : plural}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'separada':
        return AppColors.statusAtencao;
      case 'em_rota':
        return AppColors.primary;
      case 'entregue':
        return AppColors.success;
      case 'cancelada':
        return AppColors.danger;
      default:
        return AppColors.inactive;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'separada':
        return Icons.assignment;
      case 'em_rota':
        return Icons.directions_car;
      case 'entregue':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'separada':
        return 'Separada';
      case 'em_rota':
        return 'Em Rota';
      case 'entregue':
        return 'Entregue';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }
}

class _ReferenceKpiRows extends StatelessWidget {
  final List<Widget> children;

  const _ReferenceKpiRows({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final spacing = columns == 4 ? 12.0 : 10.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _EntregasListHeader extends StatelessWidget {
  final int count;
  final int completedCount;
  final VoidCallback? onDeleteCompleted;

  const _EntregasListHeader({
    required this.count,
    required this.completedCount,
    required this.onDeleteCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Widget deleteButton() {
      return Tooltip(
        message: 'Excluir todas as entregas concluidas',
        child: ElevatedButton.icon(
          onPressed: onDeleteCompleted,
          icon: const Icon(Icons.delete_sweep_outlined, size: 17),
          label: const Text('Excluir todas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    }

    final title = ReferenceSectionTitle(
      title: 'Entregas de hoje',
      action: '$count resultado(s)',
    );

    if (onDeleteCompleted == null || completedCount == 0) {
      return title;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 8),
              deleteButton(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 10),
            deleteButton(),
          ],
        );
      },
    );
  }
}

class _EntregasCompletedActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onDeleteAll;

  const _EntregasCompletedActionBar({
    required this.count,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;

    return Material(
      color: AppColors.danger.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(Dimensions.radiusMD),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entregas concluidas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$count finalizada(s)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: onDeleteAll,
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Excluir todas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 38),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupomEntregaPreviewSheet extends StatelessWidget {
  final EntregaCupomDraft draft;
  final VoidCallback? onCreate;
  final VoidCallback onEdit;

  const _CupomEntregaPreviewSheet({
    required this.draft,
    required this.onCreate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final missing = draft.requiredMissingFields;
    final reviewFields = {
      ...missing,
      ...draft.missingFields,
    }.toList();

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: tokens.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tokens.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: tokens.cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: AppStyles.softTile(
                        context: context,
                        tint: AppColors.primary,
                        radius: 12,
                      ),
                      child: Icon(
                        Icons.auto_fix_high_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cupom lido pela IA',
                            style: AppTextStyles.h3.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Confianca ${draft.confidenceLabel}',
                            style: AppTextStyles.caption.copyWith(
                              color: tokens.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (reviewFields.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: AppStyles.softCard(
                      context: context,
                      tint: AppColors.statusAtencao,
                      radius: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.statusAtencao,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Revise: ${reviewFields.join(', ')}',
                            style: AppTextStyles.body.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _CupomPreviewRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'NF',
                  value: draft.numeroNota,
                ),
                _CupomPreviewRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Cliente',
                  value: draft.clienteNome,
                ),
                _CupomPreviewRow(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  value: draft.telefone,
                ),
                _CupomPreviewRow(
                  icon: Icons.home_outlined,
                  label: 'Endereco',
                  value: draft.endereco,
                ),
                _CupomPreviewRow(
                  icon: Icons.location_city_outlined,
                  label: 'Bairro',
                  value: draft.bairro,
                ),
                _CupomPreviewRow(
                  icon: Icons.place_outlined,
                  label: 'Cidade',
                  value: draft.cidade,
                ),
                if (draft.observacoes.trim().isNotEmpty)
                  _CupomPreviewRow(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Observacoes',
                    value: draft.observacoes,
                    multiline: true,
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar antes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Criar entrega'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CupomPreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _CupomPreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final cleanValue = value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: tokens.textSecondary, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              cleanValue.isEmpty ? 'Nao identificado' : cleanValue,
              maxLines: multiline ? 4 : 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: cleanValue.isEmpty
                    ? tokens.textSecondary
                    : tokens.textPrimary,
                fontWeight:
                    cleanValue.isEmpty ? FontWeight.w600 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntregaReferenceCard extends StatelessWidget {
  final Entrega entrega;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const _EntregaReferenceCard({
    required this.entrega,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingXS),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: AppStyles.softCard(
              context: context,
              tint: statusColor,
              radius: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrega.clienteNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h4.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NF ${entrega.numeroNota} - ${entrega.bairro} - ${entrega.cidade}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((entrega.observacoes ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          entrega.observacoes!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusPill(
                      label: statusLabel,
                      color: statusColor,
                      compact: true,
                    ),
                    const SizedBox(height: 6),
                    if (onDelete != null)
                      Tooltip(
                        message: 'Excluir entrega concluida',
                        child: TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Excluir'),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AppColors.danger.withValues(alpha: 0.08),
                            foregroundColor: AppColors.danger,
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: tokens.textSecondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
