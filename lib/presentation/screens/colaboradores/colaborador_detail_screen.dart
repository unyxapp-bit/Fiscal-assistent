import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/entities/registro_ponto.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/fiscal_events_provider.dart';
import '../../providers/registro_ponto_provider.dart';
import 'colaborador_form_screen.dart';
import 'registro_ponto_form_screen.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de Detalhes do Colaborador
class ColaboradorDetailScreen extends StatefulWidget {
  final Colaborador colaborador;

  const ColaboradorDetailScreen({
    super.key,
    required this.colaborador,
  });

  @override
  State<ColaboradorDetailScreen> createState() =>
      _ColaboradorDetailScreenState();
}

class _ColaboradorDetailScreenState extends State<ColaboradorDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final registroPontoProvider =
        Provider.of<RegistroPontoProvider>(context, listen: false);

    await Future.wait([
      alocacaoProvider.loadAlocacoes(widget.colaborador.fiscalId),
      registroPontoProvider.loadRegistros(widget.colaborador.id),
    ]);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Detalhes do Colaborador', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ColaboradorFormScreen(
                    colaboradorId: widget.colaborador.id,
                  ),
                ),
              );
            },
            tooltip: 'Editar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RegistroPontoFormScreen(
                colaboradorId: widget.colaborador.id,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Registro'),
      ),
      body: Consumer3<AlocacaoProvider, RegistroPontoProvider, CaixaProvider>(
        builder: (context, alocacaoProvider, registroPontoProvider,
            caixaProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho de Perfil
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar com iniciais
                        CircleAvatar(
                          radius: 38,
                          backgroundColor:
                              widget.colaborador.departamento.cor,
                          child: Text(
                            widget.colaborador.iniciais,
                            style:
                                AppTextStyles.h2.copyWith(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingMD),
                        // Nome e informações
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.colaborador.nome,
                                style: AppTextStyles.h3,
                              ),
                              SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      widget.colaborador.departamento.cor,
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSM),
                                ),
                                child: Text(
                                  widget.colaborador.departamento.nome,
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                              SizedBox(height: 10),
                              _buildStatusChip(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: Dimensions.spacingLG),

                // Menu de seções
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: [
                    _buildMenuCard(
                      icon: Icons.info_outline,
                      label: 'Informações',
                      color: AppColors.primary,
                      onTap: () => _showInfoSheet(context),
                    ),
                    _buildMenuCard(
                      icon: Icons.swap_horiz,
                      label: 'Alocações',
                      color: AppColors.teal,
                      onTap: () => _showAlocacoesSheet(
                          context, alocacaoProvider, caixaProvider),
                    ),
                    _buildMenuCard(
                      icon: Icons.access_time,
                      label: 'Registros de Ponto',
                      color: AppColors.success,
                      onTap: () =>
                          _showRegistrosSheet(context, registroPontoProvider),
                    ),
                    _buildMenuCard(
                      icon: Icons.bar_chart,
                      label: 'Estatísticas',
                      color: AppColors.pink,
                      onTap: () => _showEstatisticasSheet(
                          context, alocacaoProvider, registroPontoProvider),
                    ),
                    _buildMenuCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'Eventos Fiscais',
                      color: AppColors.warning,
                      onTap: () => _showEventosFiscaisSheet(context),
                    ),
                  ],
                ),

                SizedBox(height: Dimensions.spacingXL),
              ],
            ),
          );
        },
      ),
    );
  }

  // â”€â”€ Menu cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.borderRadius),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 13),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(title, style: AppTextStyles.h3),
        SizedBox(height: Dimensions.spacingMD),
      ],
    );
  }

  // â”€â”€ Bottom sheets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetHandle('Informações'),
            _buildInfoRow('ID', widget.colaborador.id.substring(0, 8)),
            Divider(height: 24),
            _buildInfoRow(
                'Status', widget.colaborador.ativo ? 'Ativo' : 'Inativo'),
            Divider(height: 24),
            _buildInfoRow(
                'Criado em', _formatDate(widget.colaborador.createdAt)),
            if (widget.colaborador.observacoes != null &&
                widget.colaborador.observacoes!.isNotEmpty) ...[
              Divider(height: 24),
              _buildInfoRow('Observações', widget.colaborador.observacoes!),
            ],
            SizedBox(height: Dimensions.spacingMD),
          ],
        ),
      ),
    );
  }

  void _showAlocacoesSheet(BuildContext context, AlocacaoProvider provider,
      CaixaProvider caixaProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingMD,
            Dimensions.paddingMD,
            Dimensions.paddingMD,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle('Alocações de Hoje'),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: _buildHistoricoHoje(provider, caixaProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegistrosSheet(
      BuildContext context, RegistroPontoProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD,
                Dimensions.paddingMD,
                Dimensions.paddingMD,
                0,
              ),
              child: _buildSheetHandle('Registros de Ponto'),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: _buildRegistrosPonto(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEstatisticasSheet(
    BuildContext context,
    AlocacaoProvider alocacaoProvider,
    RegistroPontoProvider registroPontoProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetHandle('Estatísticas'),
            _buildStatRow(
              'Alocações Hoje',
              alocacaoProvider.alocacoes
                  .where((a) => a.colaboradorId == widget.colaborador.id)
                  .length
                  .toString(),
            ),
            Divider(height: 24),
            _buildStatRow(
              'Registros de Ponto',
              registroPontoProvider.registros.length.toString(),
            ),
            Divider(height: 24),
            _buildStatRow(
              'Dias com Entrada',
              registroPontoProvider.registros
                  .where((r) => r.entrada != null)
                  .length
                  .toString(),
            ),
            SizedBox(height: Dimensions.spacingMD),
          ],
        ),
      ),
    );
  }

  // ── Eventos Fiscais ───────────────────────────────────────────────────────

  void _showEventosFiscaisSheet(BuildContext context) {
    final fiscalProvider = context.read<FiscalEventsProvider>();
    final eventos =
        fiscalProvider.eventosDoColaborador(widget.colaborador.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingMD, Dimensions.paddingMD,
                  Dimensions.paddingMD, 0),
              child: _buildSheetHandle(
                  'Eventos Fiscais (${eventos.length})'),
            ),
            Expanded(
              child: eventos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 48,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Nenhum evento vinculado.',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingMD),
                      itemCount: eventos.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final e = eventos[i];
                        final catColors = <String, Color>{
                          'caixa': AppColors.statusCafe,
                          'ausencia': AppColors.danger,
                          'atestado': AppColors.statusAtencao,
                          'horario_especial': AppColors.info,
                          'ferias': AppColors.teal,
                          'vale': AppColors.indigo,
                          'problema_operacional': AppColors.warning,
                          'aviso_geral': AppColors.blueGrey,
                        };
                        final cor =
                            catColors[e.category] ?? AppColors.blueGrey;
                        return Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                Dimensions.radiusSM),
                            side: BorderSide(
                                color: cor.withValues(alpha: 0.35)),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  cor.withValues(alpha: 0.12),
                              child: Icon(Icons.receipt_long_rounded,
                                  color: cor, size: 16),
                            ),
                            title: Text(
                              e.description,
                              style: AppTextStyles.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(children: [
                              Container(
                                margin: const EdgeInsets.only(
                                    right: 6, top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cor.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                child: Text(e.category,
                                    style: AppTextStyles.caption
                                        .copyWith(color: cor)),
                              ),
                              Text(
                                '${e.eventDate.day.toString().padLeft(2, '0')}/${e.eventDate.month.toString().padLeft(2, '0')}',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ]),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: e.status == 'pending'
                                    ? AppColors.warning
                                        .withValues(alpha: 0.12)
                                    : AppColors.success
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                e.status == 'pending'
                                    ? 'Pendente'
                                    : 'Resolvido',
                                style: AppTextStyles.caption.copyWith(
                                  color: e.status == 'pending'
                                      ? AppColors.warning
                                      : AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrosPonto(RegistroPontoProvider provider) {
    if (provider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingMD),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (provider.registros.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            children: [
              Text('Nenhum registro de ponto cadastrado.',
                  style: AppTextStyles.body),
              SizedBox(height: Dimensions.spacingSM),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegistroPontoFormScreen(
                      colaboradorId: widget.colaborador.id,
                    ),
                  ),
                ),
                icon: Icon(Icons.add),
                label: Text('Adicionar registro'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: provider.registros
            .map((r) => _buildRegistroRow(r, provider))
            .toList(),
      ),
    );
  }

  Widget _buildRegistroRow(RegistroPonto r, RegistroPontoProvider provider) {
    final obs = r.observacao?.toLowerCase() ?? '';
    final isFolgaOuFeriado =
        obs == 'folga' || obs == 'feriado' || r.entrada == null;
    final isSpecial = obs == 'folga' || obs == 'feriado';

    return Container(
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingMD, vertical: 8),
      child: Row(
        children: [
          // Data
          SizedBox(
            width: 78,
            child: Text(
              _formatDate(r.data),
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isFolgaOuFeriado
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 8),
          // Conteúdo
          Expanded(
            child: isSpecial
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.inactive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.observacao!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (r.observacao != null && r.observacao!.isNotEmpty)
                        _horarioBadge(r.observacao!, AppColors.statusAtencao),
                      if (r.entrada != null)
                        _horarioBadge('E: ${r.entrada}', AppColors.primary),
                      if (r.intervaloSaida != null)
                        _horarioBadge(
                            'Int: ${r.intervaloSaida}', AppColors.statusCafe),
                      if (r.intervaloRetorno != null)
                        _horarioBadge('Ret: ${r.intervaloRetorno}',
                            AppColors.statusAtivo),
                      if (r.saida != null)
                        _horarioBadge('S: ${r.saida}', AppColors.statusSaida),
                    ],
                  ),
          ),
          // Ações
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 16),
                color: AppColors.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Editar',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegistroPontoFormScreen(
                      colaboradorId: widget.colaborador.id,
                      registroExistente: r,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 16),
                color: AppColors.danger,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Excluir',
                onPressed: () => _confirmDelete(r, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      RegistroPonto r, RegistroPontoProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir registro?'),
        content: Text('Remover o registro de ${_formatDate(r.data)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteRegistroPonto(r.id);
      if (mounted) {
        AppNotif.show(
          context,
          titulo: success ? 'Registro Excluído' : 'Erro',
          mensagem: success ? 'Registro excluído' : 'Erro ao excluir registro',
          tipo: success ? 'saida' : 'alerta',
          cor: success ? AppColors.success : AppColors.danger,
        );
      }
    }
  }

  Widget _horarioBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = widget.colaborador.statusAtual;
    final color = status?.cor ?? AppColors.statusAtivo;
    final label = status?.label ?? 'Disponível';
    final icon = status?.icone ?? Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingMD,
        vertical: Dimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: Dimensions.spacingSM),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricoHoje(
      AlocacaoProvider provider, CaixaProvider caixaProvider) {
    final alocacoesHoje = provider.alocacoes
        .where((a) => a.colaboradorId == widget.colaborador.id)
        .toList();

    if (alocacoesHoje.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Text(
            'Nenhuma alocação hoje',
            style: AppTextStyles.body,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alocacoesHoje.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final alocacao = alocacoesHoje[index];
        final caixa = caixaProvider.caixas
            .where((cx) => cx.id == alocacao.caixaId)
            .firstOrNull;
        final nomeCaixa = caixa?.nomeExibicao ?? 'Caixa ${alocacao.caixaId.substring(0, 6)}';
        final emOperacao = alocacao.liberadoEm == null;
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.point_of_sale,
                color: AppColors.primary, size: 18),
          ),
          title: Text(nomeCaixa, style: AppTextStyles.h4),
          subtitle: Text(
            'Início: ${_formatTime(alocacao.alocadoEm)}'
            '${alocacao.liberadoEm != null ? '  •  Fim: ${_formatTime(alocacao.liberadoEm!)}' : ''}',
            style: AppTextStyles.caption,
          ),
          trailing: emOperacao
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Text(
                    'Em operação',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
