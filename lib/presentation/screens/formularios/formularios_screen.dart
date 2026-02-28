import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';
import 'formulario_editor_screen.dart';
import 'formulario_preenchimento_screen.dart';
import 'formulario_respostas_screen.dart';

class FormulariosScreen extends StatefulWidget {
  const FormulariosScreen({super.key});

  @override
  State<FormulariosScreen> createState() => _FormulariosScreenState();
}

class _FormulariosScreenState extends State<FormulariosScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<FormularioProvider>(context, listen: false).load();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Formulários'),
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Templates', icon: Icon(Icons.library_books)),
              Tab(text: 'Personalizados', icon: Icon(Icons.edit_note)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Busca
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
                onChanged: (v) =>
                    setState(() => _query = v.toLowerCase().trim()),
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildLista(context, provider,
                      _filtrar(provider.templates), isTemplate: true),
                  _buildLista(context, provider,
                      _filtrar(provider.personalizados),
                      isTemplate: false),
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
      ),
    );
  }

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
            const Icon(Icons.description_outlined,
                size: 64, color: AppColors.inactive),
            const SizedBox(height: 16),
            Text(
              _query.isNotEmpty
                  ? 'Nenhum resultado para "$_query"'
                  : isTemplate
                      ? 'Nenhum template disponível'
                      : 'Nenhum formulário personalizado',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
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
        final totalRespostas = provider.totalRespostasPorFormulario(f.id);
        final hoje = provider.respostasHoje(f.id);
        final inativo = !isTemplate && !f.ativo;

        return Opacity(
          opacity: inativo ? 0.55 : 1.0,
          child: Card(
            margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
            child: ListTile(
              leading: Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (inativo ? AppColors.inactive : AppColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description,
                      color: inativo ? AppColors.inactive : AppColors.primary,
                    ),
                  ),
                  if (hoje > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$hoje',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(f.titulo, style: AppTextStyles.h4),
                  ),
                  if (inativo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.inactive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Inativo',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.inactive),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (f.descricao.isNotEmpty)
                    Text(
                      f.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 4),
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
                          '(+$hoje hoje)',
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
              trailing: PopupMenuButton<String>(
                onSelected: (value) =>
                    _onMenuSelected(value, f, provider, isTemplate),
                itemBuilder: (_) => [
                  if (!inativo)
                    const PopupMenuItem(
                      value: 'preencher',
                      child: Row(children: [
                        Icon(Icons.edit_note, size: 18),
                        SizedBox(width: 8),
                        Text('Preencher'),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'respostas',
                    child: Row(children: [
                      Icon(Icons.history, size: 18),
                      SizedBox(width: 8),
                      Text('Ver Respostas'),
                    ]),
                  ),
                  if (isTemplate)
                    const PopupMenuItem(
                      value: 'duplicar',
                      child: Row(children: [
                        Icon(Icons.content_copy, size: 18),
                        SizedBox(width: 8),
                        Text('Usar como base'),
                      ]),
                    ),
                  if (!isTemplate)
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ]),
                    ),
                  if (!isTemplate)
                    PopupMenuItem(
                      value: 'toggle_ativo',
                      child: Row(children: [
                        Icon(
                          f.ativo ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(f.ativo ? 'Desativar' : 'Ativar'),
                      ]),
                    ),
                  if (!isTemplate)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Deletar',
                            style: TextStyle(color: AppColors.danger)),
                      ]),
                    ),
                ],
              ),
              onTap: inativo
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FormularioPreenchimentoScreen(
                            formulario: f,
                          ),
                        ),
                      ),
            ),
          ),
        );
      },
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cópia criada na aba Personalizados!'),
            backgroundColor: AppColors.success,
          ),
        );
      case 'editar':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FormularioEditorScreen(formulario: f),
        ));
      case 'toggle_ativo':
        provider.toggleAtivo(f.id);
      case 'delete':
        final totalRespostas = provider.totalRespostasPorFormulario(f.id);
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
                child: const Text('Deletar',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
    }
  }
}
