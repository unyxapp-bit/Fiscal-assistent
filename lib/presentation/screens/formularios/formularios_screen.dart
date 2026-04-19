import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';
import 'formulario_editor_screen.dart';
import 'formulario_preenchimento_screen.dart';
import 'formulario_respostas_screen.dart';
import '../../../core/utils/app_notif.dart';

class FormulariosScreen extends StatefulWidget {
  const FormulariosScreen({super.key});

  @override
  State<FormulariosScreen> createState() => _FormulariosScreenState();
}

class _FormulariosScreenState extends State<FormulariosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<FormularioProvider>(context, listen: false).load();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<Formulario> _filtrar(List<Formulario> lista) {
    if (_query.isEmpty) return lista;
    return lista
        .where((f) =>
            f.titulo.toLowerCase().contains(_query) ||
            f.descricao.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FormularioProvider>(context);
    final templates = _filtrar(provider.templates);
    final personalizados = _filtrar(provider.personalizados);
    final todasRespostas = _buildRespostasFiltradas(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Formulários'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              text: 'Templates (${provider.templates.length})',
              icon: const Icon(Icons.library_books, size: 18),
            ),
            Tab(
              text: 'Meus (${provider.personalizados.length})',
              icon: const Icon(Icons.edit_note, size: 18),
            ),
            Tab(
              text: 'Respostas (${provider.respostas.length})',
              icon: const Icon(Icons.history, size: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Busca com debounce ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 10, Dimensions.paddingMD, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar formulário...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                ),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 200), () {
                  setState(() => _query = v.toLowerCase().trim());
                });
              },
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLista(context, provider, templates, isTemplate: true),
                _buildLista(context, provider, personalizados,
                    isTemplate: false),
                _buildTodasRespostas(context, provider, todasRespostas),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const FormularioEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Criar Formulário'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ── Lista de formulários ──────────────────────────────────────────────────

  Widget _buildLista(
    BuildContext context,
    FormularioProvider provider,
    List<Formulario> formularios, {
    required bool isTemplate,
  }) {
    if (formularios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: AppColors.inactive),
            const SizedBox(height: 16),
            Text(
              _query.isNotEmpty
                  ? 'Nenhum resultado para "$_query"'
                  : isTemplate
                      ? 'Nenhum template disponível'
                      : 'Nenhum formulário personalizado',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const FormularioEditorScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Criar Formulário'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      itemCount: formularios.length,
      itemBuilder: (context, index) {
        final f = formularios[index];
        final totalRespostas =
            provider.totalRespostasPorFormulario(f.id);
        final hoje = provider.respostasHoje(f.id);
        final inativo = !isTemplate && !f.ativo;

        return Opacity(
          opacity: inativo ? 0.55 : 1.0,
          child: Card(
            margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusMD),
              onTap: inativo
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            FormularioPreenchimentoScreen(formulario: f),
                      )),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading com badge de hoje
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (inativo
                                    ? AppColors.inactive
                                    : AppColors.primary)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.description,
                            color: inativo
                                ? AppColors.inactive
                                : AppColors.primary,
                          ),
                        ),
                        if (hoje > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.background, width: 1.5),
                              ),
                              child: Text(
                                '$hoje',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Conteúdo principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(f.titulo,
                                    style: AppTextStyles.h4),
                              ),
                              if (inativo)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.inactive
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Inativo',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.inactive),
                                  ),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (value) => _onMenuSelected(
                                    value, f, provider, isTemplate),
                                itemBuilder: (_) => [
                                  if (!inativo)
                                    PopupMenuItem(
                                      value: 'preencher',
                                      child: Row(children: [
                                        const Icon(Icons.edit_note, size: 18),
                                        const SizedBox(width: 8),
                                        const Text('Preencher'),
                                      ]),
                                    ),
                                  PopupMenuItem(
                                    value: 'respostas',
                                    child: Row(children: [
                                      const Icon(Icons.history, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Ver Respostas'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Row(children: [
                                      const Icon(Icons.edit, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Editar'),
                                    ]),
                                  ),
                                  if (isTemplate)
                                    PopupMenuItem(
                                      value: 'duplicar',
                                      child: Row(children: [
                                        const Icon(Icons.content_copy,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        const Text('Usar como base'),
                                      ]),
                                    ),
                                  if (!isTemplate)
                                    PopupMenuItem(
                                      value: 'toggle_ativo',
                                      child: Row(children: [
                                        Icon(
                                          f.ativo
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(f.ativo
                                            ? 'Desativar'
                                            : 'Ativar'),
                                      ]),
                                    ),
                                  if (!isTemplate)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete,
                                            size: 18,
                                            color: AppColors.danger),
                                        const SizedBox(width: 8),
                                        Text('Deletar',
                                            style: TextStyle(
                                                color: AppColors.danger)),
                                      ]),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (f.descricao.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              f.descricao,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${f.campos.length} campos  •  $totalRespostas respostas',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (hoje > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '+$hoje hoje',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Aba Respostas ─────────────────────────────────────────────────────────

  List<RespostaFormulario> _buildRespostasFiltradas(
      FormularioProvider provider) {
    var todas = provider.respostas;
    if (_query.isNotEmpty) {
      final ids = provider.formularios
          .where((f) => f.titulo.toLowerCase().contains(_query))
          .map((f) => f.id)
          .toSet();
      todas = todas.where((r) => ids.contains(r.formularioId)).toList();
    }
    return todas;
  }

  Widget _buildTodasRespostas(
    BuildContext context,
    FormularioProvider provider,
    List<RespostaFormulario> todas,
  ) {
    if (todas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.inactive),
            const SizedBox(height: 16),
            Text(
              _query.isNotEmpty
                  ? 'Nenhuma resposta para "$_query"'
                  : 'Nenhuma resposta registrada',
              style: AppTextStyles.h4
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha um formulário para\nver as respostas aqui',
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      itemCount: todas.length,
      itemBuilder: (context, index) {
        final r = todas[index];
        Formulario? form;
        for (final f in provider.formularios) {
          if (f.id == r.formularioId) {
            form = f;
            break;
          }
        }
        final titulo = form?.titulo ?? 'Formulário removido';
        final filled = r.valores.values
            .where((v) => v != null && v.toString().isNotEmpty)
            .length;
        final total = r.valores.length;
        final progresso = total > 0 ? filled / total : 0.0;

        // Preview inline: primeiras 2 respostas não-vazias
        final preview = r.valores.entries
            .where((e) => e.value != null && e.value.toString().isNotEmpty)
            .take(2)
            .map((e) => '${e.key}: ${e.value}')
            .join('  •  ');

        return Card(
          margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
          child: InkWell(
            borderRadius: BorderRadius.circular(Dimensions.radiusMD),
            onTap: () => _mostrarDetalhesResposta(context, r, titulo, form),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.description,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo,
                            style: AppTextStyles.h4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          _fmtDt(r.preenchidoEm),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progresso,
                                  minHeight: 4,
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progresso == 1.0
                                        ? AppColors.success
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$filled/$total',
                              style: AppTextStyles.caption.copyWith(
                                color: progresso == 1.0
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.copy,
                            size: 18, color: AppColors.textSecondary),
                        tooltip: 'Copiar',
                        onPressed: () => _copiarResposta(r, titulo),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: AppColors.danger),
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarDeleteResposta(
                            context, r, provider, titulo),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDt(DateTime dt) {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final alvo = DateTime(dt.year, dt.month, dt.day);
    final diff = hoje.difference(alvo).inDays;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');

    if (diff == 0) return 'Hoje às $h:$min';
    if (diff == 1) return 'Ontem às $h:$min';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} às $h:$min';
  }

  void _copiarResposta(RespostaFormulario r, String titulo) {
    final buf = StringBuffer();
    buf.writeln(titulo);
    buf.writeln(_fmtDt(r.preenchidoEm));
    buf.writeln('─' * 30);
    for (final e in r.valores.entries) {
      final v = e.value?.toString().isNotEmpty == true
          ? e.value.toString()
          : '(não preenchido)';
      buf.writeln('${e.key}: $v');
    }
    Clipboard.setData(ClipboardData(text: buf.toString().trim()));
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Copiado para área de transferência',
      tipo: 'intervalo',
    );
  }

  void _confirmarDeleteResposta(
    BuildContext context,
    RespostaFormulario r,
    FormularioProvider provider,
    String titulo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir resposta'),
        content: Text('Excluir resposta de "$titulo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletarResposta(r.id);
              Navigator.pop(ctx);
            },
            child: Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhesResposta(
    BuildContext context,
    RespostaFormulario r,
    String titulo,
    Formulario? form,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: AppTextStyles.h3),
                        Text(
                          _fmtDt(r.preenchidoEm),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: r.valores.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 24),
                itemBuilder: (ctx, i) {
                  final entry = r.valores.entries.elementAt(i);
                  final valStr =
                      entry.value?.toString().isNotEmpty == true
                          ? entry.value.toString()
                          : '(não preenchido)';
                  final preenchido =
                      entry.value?.toString().isNotEmpty == true;

                  TipoCampo? tipo;
                  if (form != null) {
                    for (final c in form.campos) {
                      if (c.label == entry.key) {
                        tipo = c.tipo;
                        break;
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (tipo == TipoCampo.simNao && preenchido)
                        Row(
                          children: [
                            Icon(
                              valStr == 'Sim'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: valStr == 'Sim'
                                  ? AppColors.success
                                  : AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              valStr,
                              style: AppTextStyles.body.copyWith(
                                color: valStr == 'Sim'
                                    ? AppColors.success
                                    : AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          valStr,
                          style: AppTextStyles.body.copyWith(
                            color: preenchido
                                ? AppColors.textPrimary
                                : AppColors.inactive,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuSelected(
    String value,
    Formulario f,
    FormularioProvider provider,
    bool isTemplate,
  ) {
    switch (value) {
      case 'preencher':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FormularioPreenchimentoScreen(formulario: f),
        ));
      case 'respostas':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FormularioRespostasScreen(formulario: f),
        ));
      case 'duplicar':
        provider.duplicarTemplate(f);
        AppNotif.show(
          context,
          titulo: 'Cópia Criada',
          mensagem: 'Cópia criada na aba Meus!',
          tipo: 'saida',
          cor: AppColors.success,
        );
      case 'editar':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FormularioEditorScreen(formulario: f),
        ));
      case 'toggle_ativo':
        provider.toggleAtivo(f.id);
      case 'delete':
        final totalRespostas =
            provider.totalRespostasPorFormulario(f.id);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: Text(
              totalRespostas > 0
                  ? 'Deletar "${f.titulo}"? Isso também excluirá $totalRespostas resposta(s).'
                  : 'Deletar "${f.titulo}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  provider.deletarFormulario(f.id);
                  Navigator.pop(ctx);
                },
                child: Text('Deletar',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
    }
  }
}
