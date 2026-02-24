import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/entities/registro_ponto.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/registro_ponto_provider.dart';
import 'colaborador_form_screen.dart';
import 'registro_ponto_form_screen.dart';

/// Tela de Detalhes do Colaborador
class ColaboradorDetailScreen extends StatefulWidget {
  final Colaborador colaborador;

  const ColaboradorDetailScreen({
    super.key,
    required this.colaborador,
  });

  @override
  State<ColaboradorDetailScreen> createState() => _ColaboradorDetailScreenState();
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
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context, listen: false);
    final registroPontoProvider =
        Provider.of<RegistroPontoProvider>(context, listen: false);

    await Future.wait([
      alocacaoProvider.loadAlocacoes(widget.colaborador.fiscalId),
      registroPontoProvider.loadRegistros(widget.colaborador.id),
    ]);
  }

  Color _getDepartamentoColor(DepartamentoTipo tipo) {
    switch (tipo) {
      case DepartamentoTipo.caixa:
        return AppColors.primary;
      case DepartamentoTipo.acougue:
        return Colors.red.shade700;
      case DepartamentoTipo.padaria:
        return Colors.orange.shade700;
      case DepartamentoTipo.hortifruti:
        return Colors.green.shade700;
      case DepartamentoTipo.deposito:
        return Colors.brown.shade600;
      case DepartamentoTipo.limpeza:
        return Colors.blue.shade600;
      case DepartamentoTipo.seguranca:
        return Colors.grey.shade700;
      case DepartamentoTipo.gerencia:
        return Colors.purple.shade700;
      case DepartamentoTipo.fiscal:
        return Colors.indigo.shade700;
      case DepartamentoTipo.pacote:
        return Colors.teal.shade600;
      case DepartamentoTipo.self:
        return Colors.cyan.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Detalhes do Colaborador', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Registro',
            style: TextStyle(color: Colors.white)),
      ),
      body: Consumer2<AlocacaoProvider, RegistroPontoProvider>(
        builder: (context, alocacaoProvider, registroPontoProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar e Info Principal
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingLG),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: _getDepartamentoColor(widget.colaborador.departamento),
                          child: Text(
                            widget.colaborador.iniciais,
                            style: AppTextStyles.h1.copyWith(color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: Dimensions.spacingMD),

                        // Nome
                        Text(
                          widget.colaborador.nome,
                          style: AppTextStyles.h2,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: Dimensions.spacingSM),

                        // Departamento Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSM,
                            vertical: Dimensions.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: _getDepartamentoColor(widget.colaborador.departamento),
                            borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                          ),
                          child: Text(
                            widget.colaborador.departamento.nome,
                            style: AppTextStyles.caption.copyWith(color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: Dimensions.spacingMD),

                        // Status Atual
                        _buildStatusChip(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: Dimensions.spacingLG),

                // Informações
                const Text('Informações', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingSM),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    child: Column(
                      children: [
                        _buildInfoRow('ID', widget.colaborador.id.substring(0, 8)),
                        const Divider(height: 24),
                        _buildInfoRow('Status', widget.colaborador.ativo ? 'Ativo' : 'Inativo'),
                        const Divider(height: 24),
                        _buildInfoRow('Criado em', _formatDate(widget.colaborador.createdAt)),
                        if (widget.colaborador.observacoes != null && widget.colaborador.observacoes!.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildInfoRow('Observações', widget.colaborador.observacoes!),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: Dimensions.spacingLG),

                // Alocações de Hoje
                const Text('Alocações de Hoje', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingSM),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    child: _buildHistoricoHoje(alocacaoProvider),
                  ),
                ),

                const SizedBox(height: Dimensions.spacingLG),

                // Registros de Ponto
                const Text('Registros de Ponto', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingSM),
                _buildRegistrosPonto(registroPontoProvider),

                const SizedBox(height: Dimensions.spacingLG),

                // Estatísticas
                const Text('Estatísticas', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingSM),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    child: Column(
                      children: [
                        _buildStatRow('Alocações Hoje',
                            alocacaoProvider.alocacoes
                                .where((a) => a.colaboradorId == widget.colaborador.id)
                                .length
                                .toString()),
                        const Divider(height: 24),
                        _buildStatRow('Registros de Ponto',
                            registroPontoProvider.registros.length.toString()),
                        const Divider(height: 24),
                        _buildStatRow('Pontualidade', '--'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
              const Text('Nenhum registro de ponto cadastrado.',
                  style: AppTextStyles.body),
              const SizedBox(height: Dimensions.spacingSM),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegistroPontoFormScreen(
                      colaboradorId: widget.colaborador.id,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar registro'),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
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
          const SizedBox(width: 8),
          // Conteúdo
          Expanded(
            child: isSpecial
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        _horarioBadge('Int: ${r.intervaloSaida}', AppColors.statusCafe),
                      if (r.intervaloRetorno != null)
                        _horarioBadge('Ret: ${r.intervaloRetorno}', AppColors.statusAtivo),
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
                icon: const Icon(Icons.edit, size: 16),
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
                icon: const Icon(Icons.delete_outline, size: 16),
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
        title: const Text('Excluir registro?'),
        content: Text(
            'Remover o registro de ${_formatDate(r.data)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteRegistroPonto(r.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Registro excluído' : 'Erro ao excluir registro'),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
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
    Color color;
    String label;

    if (widget.colaborador.statusAtual == null) {
      color = Colors.grey;
      label = 'Disponível';
    } else {
      switch (widget.colaborador.statusAtual!.name) {
        case 'alocado':
          color = AppColors.statusAtivo;
          label = 'Alocado';
          break;
        case 'intervalo':
          color = AppColors.statusIntervalo;
          label = 'Intervalo';
          break;
        case 'folga':
          color = AppColors.statusFolga;
          label = 'Folga';
          break;
        default:
          color = Colors.grey;
          label = 'Disponível';
      }
    }

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
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
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
        const SizedBox(width: Dimensions.spacingSM),
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

  Widget _buildHistoricoHoje(AlocacaoProvider provider) {
    final alocacoesHoje = provider.alocacoes
        .where((a) => a.colaboradorId == widget.colaborador.id)
        .toList();

    if (alocacoesHoje.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingMD),
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
        return ListTile(
          leading: const Icon(Icons.point_of_sale, color: AppColors.primary),
          title: Text('Caixa ${alocacao.caixaId.substring(0, 8)}'),
          subtitle: Text(
            'Início: ${_formatTime(alocacao.alocadoEm)}\n'
            '${alocacao.liberadoEm != null ? 'Fim: ${_formatTime(alocacao.liberadoEm!)}' : 'Em operação'}',
          ),
          trailing: alocacao.liberadoEm == null
              ? const Icon(Icons.circle, color: AppColors.success, size: 12)
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
