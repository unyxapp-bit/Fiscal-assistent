import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/ocorrencia_provider.dart';
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

  void _compartilharOcorrencia(Ocorrencia oc) {
    final fmt = _formatDateTime(oc.registradaEm);
    final buf = StringBuffer();
    buf.writeln('⚠️ *Ocorrência — ${oc.gravidade.nome}*');
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
    buf.write('🕐 Registrada em: $fmt');
    Share.share(buf.toString(), subject: 'Ocorrência ${oc.gravidade.nome}');
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} às $h:$min';
  }

  void _confirmarDelete(
    BuildContext context,
    Ocorrencia oc,
    OcorrenciaProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ocorrência'),
        content: const Text('Deseja excluir esta ocorrência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletar(oc.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
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
            const Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.inactive),
            const SizedBox(height: 16),
            Text(
              showResolver
                  ? 'Nenhuma ocorrência aberta'
                  : 'Nenhuma ocorrência resolvida',
              style:
                  AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
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
            leading: CircleAvatar(
              backgroundColor: oc.gravidade.cor.withValues(alpha: 0.15),
              child: Icon(iconForTipo(oc.tipo), color: oc.gravidade.cor, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(oc.tipo, style: AppTextStyles.h4),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
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
                const SizedBox(height: 4),
                Text(
                  oc.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
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
                  final eventoProvider = Provider.of<EventoTurnoProvider>(ctx, listen: false);
                  if (eventoProvider.turnoAtivo) {
                    final fiscalId = Provider.of<AuthProvider>(ctx, listen: false).user?.id ?? '';
                    eventoProvider.registrar(
                      fiscalId: fiscalId,
                      tipo: TipoEvento.ocorrenciaResolvida,
                      detalhe: '${oc.tipo} — ${oc.gravidade.nome}',
                    );
                  }
                }
                if (v == 'compartilhar') _compartilharOcorrencia(oc);
                if (v == 'deletar') _confirmarDelete(ctx, oc, provider);
              },
              itemBuilder: (_) => [
                if (showResolver)
                  const PopupMenuItem(
                    value: 'resolver',
                    child: Row(children: [
                      Icon(Icons.check_circle, size: 18,
                          color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Marcar como resolvida'),
                    ]),
                  ),
                const PopupMenuItem(
                  value: 'compartilhar',
                  child: Row(children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Compartilhar'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'deletar',
                  child: Row(children: [
                    Icon(Icons.delete, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Excluir',
                        style: TextStyle(color: AppColors.danger)),
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
        title: const Text('Ocorrências'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Abertas'),
                  if (abertas.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${abertas.length}',
                        style: const TextStyle(
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
                  const Text('Resolvidas'),
                  if (resolvidas.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${resolvidas.length}',
                        style: const TextStyle(
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
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
