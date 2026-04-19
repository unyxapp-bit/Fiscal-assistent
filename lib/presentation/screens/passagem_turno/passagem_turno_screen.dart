import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/passagem_turno_provider.dart';
import '../../../core/utils/app_notif.dart';

// ── Constantes de turno ───────────────────────────────────────────────────────

const _turnos = ['manha', 'tarde', 'noite'];
const _turnoLabels = {'manha': 'Manhã', 'tarde': 'Tarde', 'noite': 'Noite'};
const _turnoCores = {
  'manha': Color(0xFFFF9800),  // laranja
  'tarde': Color(0xFF2196F3),  // azul
  'noite': Color(0xFF3F51B5),  // índigo
};

class PassagemTurnoScreen extends StatefulWidget {
  const PassagemTurnoScreen({super.key});

  @override
  State<PassagemTurnoScreen> createState() => _PassagemTurnoScreenState();
}

class _PassagemTurnoScreenState extends State<PassagemTurnoScreen> {
  bool _showForm = false;
  String? _turnoSelecionado;
  final _resumoCtrl = TextEditingController();
  final _pendenciasCtrl = TextEditingController();
  final _recadosCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<PassagemTurnoProvider>(context, listen: false).load();
      }
    });
  }

  @override
  void dispose() {
    _resumoCtrl.dispose();
    _pendenciasCtrl.dispose();
    _recadosCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} às $h:$min';
  }

  void _salvar(PassagemTurnoProvider provider) {
    final resumo = _resumoCtrl.text.trim();
    if (resumo.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Campo Inválido',
        mensagem: 'Preencha ao menos o resumo do turno',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    provider.registrar(
      resumo: resumo,
      pendencias: _pendenciasCtrl.text.trim(),
      recados: _recadosCtrl.text.trim(),
      turno: _turnoSelecionado,
    );

    _resumoCtrl.clear();
    _pendenciasCtrl.clear();
    _recadosCtrl.clear();
    setState(() {
      _showForm = false;
      _turnoSelecionado = null;
    });

    AppNotif.show(
      context,
      titulo: 'Turno Registrado',
      mensagem: 'Passagem de turno registrada!',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  String _textoCompartilhamento(PassagemTurno p) {
    final buf = StringBuffer();
    final turnoStr =
        p.turnoLabel.isNotEmpty ? ' (${p.turnoLabel})' : '';
    buf.writeln(
        'PASSAGEM DE TURNO$turnoStr — ${_formatDateTime(p.registradaEm)}');
    buf.writeln('─' * 30);
    buf.writeln('RESUMO DO TURNO:');
    buf.writeln(p.resumo);
    if (p.pendencias.isNotEmpty) {
      buf.writeln();
      buf.writeln('PENDÊNCIAS:');
      buf.writeln(p.pendencias);
    }
    if (p.recados.isNotEmpty) {
      buf.writeln();
      buf.writeln('RECADOS:');
      buf.writeln(p.recados);
    }
    return buf.toString().trim();
  }

  Future<void> _copiar(PassagemTurno p) async {
    await Clipboard.setData(ClipboardData(text: _textoCompartilhamento(p)));
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Copiado para área de transferência',
      tipo: 'intervalo',
    );
  }

  void _compartilhar(PassagemTurno p) {
    Share.share(
      _textoCompartilhamento(p),
      subject:
          'Passagem de turno ${_formatDateTime(p.registradaEm)}',
    );
  }

  void _confirmarDelete(
    BuildContext context,
    PassagemTurno p,
    PassagemTurnoProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro'),
        content: const Text('Excluir esta passagem de turno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletar(p.id);
              Navigator.pop(ctx);
            },
            child: Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  // ── Card de resumo do dia ─────────────────────────────────────────────────

  Widget _buildDaySummary(PassagemTurnoProvider provider) {
    final hoje = provider.historicoHoje;
    if (hoje.isEmpty) return const SizedBox.shrink();

    final ultima = hoje.first;
    final turnoLabel = ultima.turnoLabel;
    final turnoColor =
        _turnoCores[ultima.turno] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingMD),
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.today, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoje: ${hoje.length} passagem${hoje.length > 1 ? 'ens' : ''} registrada${hoje.length > 1 ? 's' : ''}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Última: ',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    if (turnoLabel.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: turnoColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          turnoLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: turnoColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      ultima.resumo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card de call-to-action ────────────────────────────────────────────────

  Widget _buildCTACard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.handshake, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Registrar Passagem de Turno',
            style:
                AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Documente o que aconteceu\npara o próximo fiscal',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.add),
              label: const Text('Nova Passagem'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize:
                    const Size.fromHeight(Dimensions.buttonHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formulário de registro ────────────────────────────────────────────────

  Widget _buildForm(PassagemTurnoProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingLG),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nova Passagem de Turno',
                    style: AppTextStyles.h4,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _showForm = false;
                    _turnoSelecionado = null;
                  }),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: Dimensions.spacingSM),

            // Selector de turno
            Text(
              'Turno',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _turnos.map((t) {
                final cor = _turnoCores[t]!;
                return ButtonSegment<String>(
                  value: t,
                  label: Text(_turnoLabels[t]!),
                  icon: Icon(
                    t == 'manha'
                        ? Icons.wb_sunny_outlined
                        : t == 'tarde'
                            ? Icons.wb_cloudy_outlined
                            : Icons.nights_stay_outlined,
                    color: _turnoSelecionado == t
                        ? cor
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                );
              }).toList(),
              selected: _turnoSelecionado != null
                  ? {_turnoSelecionado!}
                  : {},
              emptySelectionAllowed: true,
              onSelectionChanged: (sel) => setState(
                  () => _turnoSelecionado = sel.isEmpty ? null : sel.first),
              style: ButtonStyle(
                iconColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.textSecondary;
                }),
              ),
            ),
            const SizedBox(height: Dimensions.spacingMD),

            // Resumo
            TextFormField(
              controller: _resumoCtrl,
              decoration: InputDecoration(
                labelText: 'Resumo do turno *',
                hintText: 'O que aconteceu de relevante no turno?',
                prefixIcon: const Icon(Icons.summarize),
                alignLabelWithHint: true,
                counterText: '${_resumoCtrl.text.length}/500',
              ),
              maxLines: 3,
              maxLength: 500,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  null, // suprime o counter padrão — usamos o counterText
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Dimensions.spacingMD),

            // Pendências
            TextFormField(
              controller: _pendenciasCtrl,
              decoration: const InputDecoration(
                labelText: 'Pendências',
                hintText: 'O que ficou para resolver no próximo turno?',
                prefixIcon: Icon(Icons.pending_actions),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.spacingMD),

            // Recados
            TextFormField(
              controller: _recadosCtrl,
              decoration: const InputDecoration(
                labelText: 'Recados',
                hintText: 'Alguma mensagem para o próximo fiscal?',
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.spacingLG),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _salvar(provider),
                icon: const Icon(Icons.save),
                label: const Text('Registrar Passagem'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize:
                      const Size.fromHeight(Dimensions.buttonHeight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de registro histórico ────────────────────────────────────────────

  Widget _buildRegistro(
    BuildContext context,
    PassagemTurno p,
    PassagemTurnoProvider provider,
  ) {
    final turnoColor = _turnoCores[p.turno] ?? AppColors.primary;
    final turnoLabel = p.turnoLabel;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(Icons.handshake, color: AppColors.primary),
        ),
        title: Row(
          children: [
            if (turnoLabel.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: turnoColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  turnoLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: turnoColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                _formatDateTime(p.registradaEm),
                style: AppTextStyles.h4,
              ),
            ),
          ],
        ),
        subtitle: Text(
          p.resumo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'compartilhar') _compartilhar(p);
            if (value == 'copiar') _copiar(p);
            if (value == 'excluir') _confirmarDelete(context, p, provider);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'compartilhar',
              child: Row(children: [
                Icon(Icons.share_outlined,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text('Compartilhar'),
              ]),
            ),
            PopupMenuItem(
              value: 'copiar',
              child: Row(children: [
                Icon(Icons.copy,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text('Copiar'),
              ]),
            ),
            PopupMenuItem(
              value: 'excluir',
              child: Row(children: [
                Icon(Icons.delete_outline,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: 8),
                Text('Excluir',
                    style: TextStyle(color: AppColors.danger)),
              ]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingMD,
              0,
              Dimensions.paddingMD,
              Dimensions.paddingMD,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildSection('Resumo do Turno', p.resumo,
                    icon: Icons.summarize,
                    cor: AppColors.textSecondary),
                if (p.pendencias.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.spacingMD),
                  _buildSection('Pendências', p.pendencias,
                      icon: Icons.pending_actions,
                      cor: AppColors.statusAtencao),
                ],
                if (p.recados.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.spacingMD),
                  _buildSection('Recados', p.recados,
                      icon: Icons.message, cor: AppColors.primary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String titulo, String conteudo,
      {IconData? icon, Color? cor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14, color: cor ?? AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              titulo,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: cor ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(conteudo, style: AppTextStyles.body),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PassagemTurnoProvider>(context);

    // Filtra histórico por query de busca
    final historico = _searchQuery.isEmpty
        ? provider.historico
        : provider.historico.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.resumo.toLowerCase().contains(q) ||
                p.pendencias.toLowerCase().contains(q) ||
                p.recados.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Passagem de Turno'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de resumo do dia
            _buildDaySummary(provider),

            // Formulário ou CTA
            if (_showForm)
              _buildForm(provider)
            else
              _buildCTACard(),

            const SizedBox(height: Dimensions.spacingLG),

            // Cabeçalho do histórico
            if (provider.historico.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Histórico',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${provider.historico.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spacingSM),

              // Busca no histórico
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar no histórico...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusMD),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase().trim()),
              ),
              const SizedBox(height: Dimensions.spacingMD),

              if (historico.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Nenhum resultado para "$_searchQuery"',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...historico.map(
                  (p) => _buildRegistro(context, p, provider),
                ),
            ] else if (!_showForm)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Icon(Icons.handshake,
                          size: 64, color: AppColors.inactive),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma passagem registrada',
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registre o que aconteceu no turno\npara o próximo fiscal',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
