import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/entities/alocacao.dart';
import '../../../../domain/enums/departamento_tipo.dart';

/// Card compacto para exibição em grade (3 colunas)
class ColaboradorGridCard extends StatelessWidget {
  final Colaborador colaborador;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Alocacao? alocacaoAtual;
  final bool showDetails;

  const ColaboradorGridCard({
    super.key,
    required this.colaborador,
    required this.onTap,
    this.onDelete,
    this.alocacaoAtual,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = colaborador.departamento.cor;
    final dept = colaborador.departamento.nome;
    final deptIcon = colaborador.departamento.icone;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null
          ? () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 4),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    color.withValues(alpha: 0.15),
                                child:
                                    Icon(deptIcon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    colaborador.nome.split(' ').first,
                                    style: AppTextStyles.subtitle,
                                  ),
                                  Text(
                                    dept,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.edit, color: AppColors.primary),
                          title: const Text('Editar'),
                          onTap: () {
                            Navigator.pop(context);
                            onTap();
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          title: Text('Excluir',
                              style: TextStyle(color: AppColors.danger)),
                          onTap: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              )
          : null,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: 22,
                child: Text(
                  colaborador.gerarIniciais(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                colaborador.nome.split(' ').first,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dept,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showDetails) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 6),
                if (alocacaoAtual != null) ...[
                  _detalhe(
                    Icons.login,
                    _fmtHora(alocacaoAtual!.alocadoEm),
                    AppColors.statusAtivo,
                  ),
                  const SizedBox(height: 4),
                  _detalhe(
                    Icons.coffee,
                    alocacaoAtual!.intervaloMarcadoFeito
                        ? 'Feito'
                        : 'Pendente',
                    alocacaoAtual!.intervaloMarcadoFeito
                        ? AppColors.statusCafe
                        : AppColors.statusAtencao,
                  ),
                  const SizedBox(height: 4),
                  _detalhe(
                    Icons.logout,
                    alocacaoAtual!.liberadoEm != null
                        ? _fmtHora(alocacaoAtual!.liberadoEm!)
                        : 'Em caixa',
                    alocacaoAtual!.liberadoEm != null
                        ? AppColors.statusSaida
                        : AppColors.textSecondary,
                  ),
                ] else
                  Text(
                    'Disponível',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.statusAtivo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detalhe(IconData icon, String label, Color cor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 11, color: cor),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: cor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _fmtHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Item da lista de colaboradores
class ColaboradorListItem extends StatelessWidget {
  final Colaborador colaborador;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ColaboradorListItem({
    super.key,
    required this.colaborador,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = colaborador.departamento.cor;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: Dimensions.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(Dimensions.paddingSM),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 24,
          child: Text(
            colaborador.gerarIniciais(),
            style: AppTextStyles.title.copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          colaborador.nome,
          style: AppTextStyles.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(colaborador.departamento.icone,
                      size: 11, color: color),
                  const SizedBox(width: 4),
                  Text(
                    colaborador.departamento.nome,
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (colaborador.observacoes != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  colaborador.observacoes!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              onTap: onTap,
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Editar'),
                ],
              ),
            ),
            if (onDelete != null)
              PopupMenuItem(
                onTap: onDelete,
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text('Excluir',
                        style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
