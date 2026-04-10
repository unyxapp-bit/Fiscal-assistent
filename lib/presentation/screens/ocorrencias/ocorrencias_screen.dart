import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/app_notif.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/ocorrencia_provider.dart';
import 'ocorrencia_detail_screen.dart';
import 'ocorrencia_form_screen.dart';

class OcorrenciasScreen extends StatefulWidget {
  const OcorrenciasScreen({super.key});

  @override
  State<OcorrenciasScreen> createState() => _OcorrenciasScreenState();
}

class _OcorrenciasScreenState extends State<OcorrenciasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _textoOcorrencia(Ocorrencia oc) {
    final fmt = _formatDateTime(oc.registradaEm);
    final buf = StringBuffer();
    buf.writeln('*OcorrÃƒÂªncia - ${oc.gravidade.nome}*');
    buf.writeln();
    buf.writeln('Tipo: ${oc.tipo}');
    if (oc.caixaId != null && oc.caixaId!.isNotEmpty) {
      buf.writeln('Caixa: ${oc.caixaNome ?? oc.caixaId}');
    }
    if (oc.colaboradorNome != null && oc.colaboradorNome!.isNotEmpty) {
      buf.writeln('Colaborador: ${oc.colaboradorNome}');
    }
    buf.writeln();
    buf.writeln(oc.descricao);
    buf.writeln();
    buf.write('Registrada em: $fmt');
    return buf.toString();
  }

  void _compartilharOcorrencia(Ocorrencia oc) {
    Share.share(
      _textoOcorrencia(oc),
      subject: 'OcorrÃƒÂªncia ${oc.gravidade.nome}',
    );
  }

  Future<void> _copiarOcorrencia(Ocorrencia oc) async {
    await Clipboard.setData(ClipboardData(text: _textoOcorrencia(oc)));
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'OcorrÃƒÂªncia copiada para a ÃƒÂ¡rea de transferÃƒÂªncia',
      tipo: 'intervalo',
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} ÃƒÂ s $h:$min';
  }

  void _confirmarDelete(
    BuildContext context,
    Ocorrencia oc,
    OcorrenciaProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir ocorrÃƒÂªncia'),
        content: Text('Deseja excluir esta ocorrÃƒÂªncia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletar(oc.id);
              Navigator.pop(ctx);
            },
            child: Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(
    BuildContext context,
    List<Ocorrencia> lista,
    OcorrenciaProvider provider,
    bool showResolver,
  ) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.inactive),
            SizedBox(height: 16),
            Text(
              showResolver
                  ? 'Nenhuma ocorrÃƒÂªncia aberta'
                  : 'Nenhuma ocorrÃƒÂªncia resolvida',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      itemCount: lista.length,
      itemBuilder: (ctx, i) {
        final oc = lista[i];
        return Card(
          margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
          child: ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OcorrenciaDetailScreen(
                  ocorrenciaId: oc.id,
                  ocorrenciaInicial: oc,
                ),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: oc.gravidade.cor.withValues(alpha: 0.15),
              child:
                  Icon(iconForTipo(oc.tipo), color: oc.gravidade.cor, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(oc.tipo, style: AppTextStyles.h4),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: oc.gravidade.cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    oc.gravidade.nome,
                    style: TextStyle(
                      color: oc.gravidade.cor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  oc.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  _formatDateTime(oc.registradaEm),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (oc.caixaNome != null && oc.caixaNome!.isNotEmpty)
                  Text(
                    'Caixa: ${oc.caixaNome}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                if (oc.colaboradorNome != null &&
                    oc.colaboradorNome!.isNotEmpty)
                  Text(
                    'Colaborador: ${oc.colaboradorNome}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                if (oc.resolvida && oc.resolvidaEm != null)
                  Text(
                    'Resolvida em ${_formatDateTime(oc.resolvidaEm!)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'resolver') {
                  provider.resolver(oc.id);
                  final eventoProvider =
                      Provider.of<EventoTurnoProvider>(ctx, listen: false);
                  if (eventoProvider.turnoAtivo) {
                    final fiscalId =
                        Provider.of<AuthProvider>(ctx, listen: false)
                                .user
                                ?.id ??
                            '';
                    eventoProvider.registrar(
                      fiscalId: fiscalId,
                      tipo: TipoEvento.ocorrenciaResolvida,
                      detalhe: '${oc.tipo} Ã¢â‚¬â€ ${oc.gravidade.nome}',
                    );
                  }
                }
                if (v == 'copiar') _copiarOcorrencia(oc);
                if (v == 'compartilhar') _compartilharOcorrencia(oc);
                if (v == 'deletar') _confirmarDelete(ctx, oc, provider);
              },
              itemBuilder: (_) => [
                if (showResolver)
                  PopupMenuItem(
                    value: 'resolver',
                    child: Row(children: [
                      Icon(Icons.check_circle,
                          size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Marcar como resolvida'),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'copiar',
                  child: Row(children: [
                    Icon(Icons.copy_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Copiar'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'compartilhar',
                  child: Row(children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Compartilhar'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'deletar',
                  child: Row(children: [
                    Icon(Icons.delete, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: AppColors.danger)),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OcorrenciaProvider>(context);
    final abertas = provider.abertas;
    final resolvidas = provider.resolvidas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('OcorrÃƒÂªncias'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Abertas'),
                  if (abertas.isNotEmpty) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${abertas.length}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Resolvidas'),
                  if (resolvidas.isNotEmpty) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${resolvidas.length}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildLista(context, abertas, provider, true),
          _buildLista(context, resolvidas, provider, false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OcorrenciaFormScreen()),
        ),
        icon: Icon(Icons.add),
        label: Text('Registrar'),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
