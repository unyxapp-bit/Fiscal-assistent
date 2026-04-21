import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:notification_listener_service/notification_listener_service.dart';

import '../../../core/constants/colors.dart';
import '../../../data/services/whatsapp_notification_service.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_notif.dart';
import '../../providers/fiscal_events_provider.dart';
import 'balcao_permissao_screen.dart';

// ─────────────────────────────────────────────
//  CONFIGURAÇÃO DE CATEGORIAS
// ─────────────────────────────────────────────

class _CatConfig {
  final String label;
  final IconData icon;
  final Color Function() color;
  const _CatConfig(this.label, this.icon, this.color);
}

final Map<String, _CatConfig> _cats = {
  'caixa':
      _CatConfig('Caixa', Icons.account_balance_wallet, () => AppColors.warning),
  'ausencia':
      _CatConfig('Ausência', Icons.person_off, () => AppColors.danger),
  'atestado':
      _CatConfig('Atestado', Icons.medical_services, () => AppColors.info),
  'horario_especial':
      _CatConfig('Horário Especial', Icons.schedule, () => AppColors.outro),
  'ferias':
      _CatConfig('Férias', Icons.beach_access, () => AppColors.success),
  'vale':
      _CatConfig('Vale', Icons.receipt_long, () => AppColors.teal),
  'problema_operacional':
      _CatConfig('Problema', Icons.warning_amber, () => AppColors.statusSaida),
  'aviso_geral':
      _CatConfig('Aviso', Icons.campaign, () => AppColors.blueGrey),
  'midia_pendente':
      _CatConfig('Mídia', Icons.perm_media, () => AppColors.deepPurple),
};

_CatConfig _catOf(String cat) => _cats[cat] ?? _cats['aviso_geral']!;

// ─────────────────────────────────────────────
//  TELA PRINCIPAL
// ─────────────────────────────────────────────

class FiscalEventsScreen extends StatefulWidget {
  const FiscalEventsScreen({super.key});

  @override
  State<FiscalEventsScreen> createState() => _FiscalEventsScreenState();
}

class _FiscalEventsScreenState extends State<FiscalEventsScreen>
    with AutomaticKeepAliveClientMixin {
  String? _selectedCategory;
  String _selectedStatus = 'pending';
  bool _permissaoVerificada = false;
  bool _temPermissao = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await _verificarPermissao();
    if (!mounted) return;
    final provider = context.read<FiscalEventsProvider>();
    await provider.load();
    if (!mounted) return;
    provider.subscribeRealtime();
  }

  Future<void> _verificarPermissao() async {
    try {
      final granted = await _checkPermission();
      if (granted) {
        // Inicia (ou confirma que está ativo) o listener ao retornar da
        // tela de configurações com permissão já concedida.
        WhatsAppNotificationService.init();
      }
      if (mounted) {
        setState(() {
          _temPermissao = granted;
          _permissaoVerificada = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _permissaoVerificada = true);
    }
  }

  Future<bool> _checkPermission() async {
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final dia = DateTime(dt.year, dt.month, dt.day);

    final hora = DateFormat('HH:mm').format(dt);
    if (dia == hoje) return hora;
    if (dia == ontem) return 'Ontem $hora';
    return DateFormat('dd/MM HH:mm').format(dt);
  }

  List<FiscalEvent> _filtrar(List<FiscalEvent> events) {
    return events.where((e) {
      final catOk = _selectedCategory == null || e.category == _selectedCategory;
      final statusOk = _selectedStatus == 'all' || e.status == _selectedStatus;
      return catOk && statusOk;
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<FiscalEventsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Text('Balcão Fiscal', style: AppTextStyles.h3),
            if (provider.totalPendentes > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${provider.totalPendentes}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_temPermissao && _permissaoVerificada)
            IconButton(
              icon: Icon(Icons.notifications_off_outlined,
                  color: AppColors.danger),
              tooltip: 'Permissão necessária',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BalcaoPermissaoScreen()),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Atualizar',
            onPressed: provider.loading ? null : provider.load,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_temPermissao && _permissaoVerificada)
            _PermissaoBanner(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BalcaoPermissaoScreen()),
              ).then((_) => _verificarPermissao()),
            ),
          _buildCategoryFilters(provider.events),
          _buildStatusTabs(),
          Expanded(child: _buildList(provider)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(List<FiscalEvent> events) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
        children: [
          _CatChip(
            label: 'Todas',
            icon: Icons.grid_view_rounded,
            color: AppColors.blueGrey,
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ..._cats.entries.map((e) {
            final count = events
                .where((ev) =>
                    ev.category == e.key && ev.status == 'pending')
                .length;
            return _CatChip(
              label: e.value.label,
              icon: e.value.icon,
              color: e.value.color(),
              selected: _selectedCategory == e.key,
              badge: count > 0 ? count : null,
              onTap: () => setState(() => _selectedCategory =
                  _selectedCategory == e.key ? null : e.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    const tabs = [
      ('pending', 'Pendentes'),
      ('resolved', 'Resolvidos'),
      ('ignored', 'Ignorados'),
      ('all', 'Todos'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingMD, 8, Dimensions.paddingMD, 4),
      child: Row(
        children: tabs.map((t) {
          final sel = _selectedStatus == t.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedStatus = t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSM, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.cardBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                border: Border.all(
                    color:
                        sel ? AppColors.cardBorder : Colors.transparent),
              ),
              child: Text(
                t.$2,
                style: AppTextStyles.caption.copyWith(
                  color: sel
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      sel ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(FiscalEventsProvider provider) {
    if (provider.loading && provider.events.isEmpty) {
      return Center(
          child:
              CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.error != null && provider.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Erro ao carregar', style: AppTextStyles.body),
            const SizedBox(height: 8),
            TextButton(
                onPressed: provider.load,
                child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    final filtered = _filtrar(provider.events);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Nenhum evento aqui', style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(
              'Novas mensagens do grupo aparecerão aqui',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingMD, 4, Dimensions.paddingMD, 24),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final event = filtered[i];
          if (event.needsReview) {
            return _MidiaCard(
              event: event,
              onFill: () => _abrirPreenchimentoMidia(event),
              onIgnore: () => _updateStatus(event, 'ignored'),
            );
          }
          return Dismissible(
            key: Key('event_${event.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: Dimensions.paddingLG),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusMD),
              ),
              child: Icon(Icons.delete_outline, color: AppColors.danger),
            ),
            confirmDismiss: (_) async {
              try {
                await provider.excluir(event.id);
                return true;
              } catch (_) {
                return false;
              }
            },
            child: _EventCard(
              event: event,
              timestamp: _formatTimestamp(event.eventDate),
              onResolve: () => _updateStatus(event, 'resolved'),
              onIgnore: () => _updateStatus(event, 'ignored'),
              onReopen: () => _updateStatus(event, 'pending'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(FiscalEvent event, String novoStatus) async {
    HapticFeedback.lightImpact();
    try {
      await context.read<FiscalEventsProvider>().atualizarStatus(event, novoStatus);
    } catch (_) {
      if (mounted) {
        AppNotif.show(context,
            titulo: 'Erro',
            mensagem: 'Não foi possível atualizar o status.',
            tipo: 'alerta',
            cor: AppColors.danger);
      }
    }
  }

  void _abrirPreenchimentoMidia(FiscalEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreenchimentoMidiaSheet(
        event: event,
        onSave: (category, description, employeeName, amount) async {
          await context.read<FiscalEventsProvider>().preencherMidia(
                event: event,
                category: category,
                description: description,
                employeeName: employeeName,
                amount: amount,
              );
          if (mounted) {
            AppNotif.show(context,
                titulo: 'Salvo',
                mensagem: 'Informações registradas.',
                tipo: 'saida',
                cor: AppColors.success);
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BANNER DE PERMISSÃO
// ─────────────────────────────────────────────

class _PermissaoBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissaoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            Dimensions.paddingMD, 0, Dimensions.paddingMD, 8),
        padding: const EdgeInsets.all(Dimensions.paddingSM),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusSM),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined,
                color: AppColors.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Permissão de notificações não concedida. Toque para ativar.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.warning),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.warning, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHIP DE CATEGORIA
// ─────────────────────────────────────────────

class _CatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSM, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(Dimensions.radiusSM),
          border: Border.all(
              color: selected ? color : AppColors.cardBorder, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: selected ? color : AppColors.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: selected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6)),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CARD: EVENTO NORMAL
// ─────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final FiscalEvent event;
  final String timestamp;
  final VoidCallback onResolve;
  final VoidCallback onIgnore;
  final VoidCallback onReopen;

  const _EventCard({
    required this.event,
    required this.timestamp,
    required this.onResolve,
    required this.onIgnore,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _catOf(event.category);
    final color = cfg.color();
    final isPending = event.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardBorder.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Linha 1: categoria + timestamp
          Row(children: [
            Icon(cfg.icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(cfg.label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 10)),
            const Spacer(),
            Text(timestamp,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 6),

          // Descrição
          Text(event.description,
              style: AppTextStyles.body.copyWith(
                  color: isPending
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  height: 1.4)),

          // Tags
          if (event.employeeName != null ||
              event.amount != null ||
              event.sender != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 6, runSpacing: 4, children: [
                if (event.employeeName != null)
                  _Tag(
                      icon: Icons.person_rounded,
                      label: event.employeeName!,
                      color: AppColors.blueGrey),
                if (event.amount != null)
                  _Tag(
                      icon: Icons.attach_money_rounded,
                      label: NumberFormat.currency(
                              locale: 'pt_BR', symbol: 'R\$')
                          .format(event.amount),
                      color: AppColors.success),
                if (event.sender != null && event.sender!.isNotEmpty)
                  _Tag(
                      icon: Icons.send_rounded,
                      label: event.sender!,
                      color: AppColors.info),
              ]),
            ),

          const SizedBox(height: 10),

          // Ações
          Row(children: [
            GestureDetector(
              onTap: () => _verOriginal(context),
              child: Text('ver original',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary)),
            ),
            const Spacer(),
            if (isPending) ...[
              _ActionBtn(
                  label: 'Ignorar',
                  icon: Icons.close_rounded,
                  color: AppColors.backgroundSection,
                  textColor: AppColors.textSecondary,
                  onTap: onIgnore),
              const SizedBox(width: 8),
              _ActionBtn(
                  label: 'Resolver',
                  icon: Icons.check_rounded,
                  color: AppColors.success.withValues(alpha: 0.15),
                  textColor: AppColors.success,
                  onTap: onResolve),
            ] else
              _ActionBtn(
                  label: 'Reabrir',
                  icon: Icons.refresh_rounded,
                  color: AppColors.backgroundSection,
                  textColor: AppColors.textSecondary,
                  onTap: onReopen),
          ]),
        ]),
      ),
    );
  }

  void _verOriginal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Dimensions.paddingLG),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('MENSAGEM ORIGINAL',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(event.rawMessage,
              style: AppTextStyles.body.copyWith(height: 1.5)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CARD: MÍDIA PENDENTE
// ─────────────────────────────────────────────

class _MidiaCard extends StatelessWidget {
  final FiscalEvent event;
  final VoidCallback onFill;
  final VoidCallback onIgnore;

  const _MidiaCard(
      {required this.event, required this.onFill, required this.onIgnore});

  @override
  Widget build(BuildContext context) {
    final isAudio = event.mediaType == 'audio';
    final emoji = isAudio ? '🎤' : '📷';
    final label = isAudio ? 'ÁUDIO' : 'FOTO';
    final color = AppColors.deepPurple;
    final dateStr = DateFormat('dd/MM HH:mm').format(event.eventDate);

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('AGUARDANDO',
                  style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 9)),
            ),
          ]),
          const SizedBox(height: 10),

          if (event.sender != null && event.sender!.isNotEmpty)
            Row(children: [
              Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: 13),
              const SizedBox(width: 4),
              Text(event.sender!,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
            ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.access_time_rounded,
                color: AppColors.textSecondary, size: 13),
            const SizedBox(width: 4),
            Text(dateStr,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ]),

          const SizedBox(height: 12),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onFill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSM)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Adicionar informações',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onIgnore,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.backgroundSection,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSM)),
              ),
              icon: Icon(Icons.close_rounded,
                  color: AppColors.textSecondary),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM SHEET: PREENCHER MÍDIA
// ─────────────────────────────────────────────

class _PreenchimentoMidiaSheet extends StatefulWidget {
  final FiscalEvent event;
  final Future<void> Function(
      String category, String description, String? employeeName, double? amount) onSave;

  const _PreenchimentoMidiaSheet(
      {required this.event, required this.onSave});

  @override
  State<_PreenchimentoMidiaSheet> createState() =>
      _PreenchimentoMidiaSheetState();
}

class _PreenchimentoMidiaSheetState
    extends State<_PreenchimentoMidiaSheet> {
  String _category = 'aviso_geral';
  final _descCtrl = TextEditingController();
  final _empCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.event.employeeName != null) {
      _empCtrl.text = widget.event.employeeName!;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _empCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_descCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final amount = double.tryParse(_amountCtrl.text
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), ''));
    try {
      await widget.onSave(
          _category, _descCtrl.text.trim(), _empCtrl.text.trim(), amount);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAudio = widget.event.mediaType == 'audio';
    final emoji = isAudio ? '🎤' : '📷';
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(Dimensions.paddingSM),
      padding: EdgeInsets.fromLTRB(
          Dimensions.paddingLG,
          Dimensions.paddingLG,
          Dimensions.paddingLG,
          Dimensions.paddingLG + bottom),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(Dimensions.radiusSheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              isAudio ? 'Informações do áudio' : 'Informações da foto',
              style: AppTextStyles.h4,
            ),
          ]),

          if (widget.event.sender != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'De: ${widget.event.sender}  •  '
                '${DateFormat('dd/MM/yyyy HH:mm').format(widget.event.eventDate)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

          const SizedBox(height: 16),

          Text('Categoria',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _CatDropdown(
            value: _category,
            onChanged: (v) => setState(() => _category = v),
          ),

          const SizedBox(height: 14),

          Text('O que aconteceu? *',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _Field(
              controller: _descCtrl,
              hint: 'Ex: Caixa da Ana faltou R\$ 5,00...',
              maxLines: 3),

          const SizedBox(height: 14),

          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Funcionário',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _Field(controller: _empCtrl, hint: 'Nome'),
                  ]),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valor (R\$)',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _Field(
                        controller: _amountCtrl,
                        hint: '0,00',
                        keyboardType: TextInputType.number),
                  ]),
            ),
          ]),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSM)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Salvar',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS AUXILIARES
// ─────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSM, vertical: 7),
          decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.circular(Dimensions.radiusSM)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: textColor, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.backgroundSection,
        border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(Dimensions.radiusSM),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSM, vertical: 10),
      ),
    );
  }
}

class _CatDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CatDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cats =
        _cats.entries.where((e) => e.key != 'midia_pendente').toList();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSM, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.backgroundSection,
          borderRadius: BorderRadius.circular(Dimensions.radiusSM)),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.cardBackground,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary),
        items: cats.map((e) {
          return DropdownMenuItem(
            value: e.key,
            child: Row(children: [
              Icon(e.value.icon, color: e.value.color(), size: 16),
              const SizedBox(width: 8),
              Text(e.value.label, style: AppTextStyles.body),
            ]),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
