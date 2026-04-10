import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/entities/alocacao.dart';
import '../../../../domain/enums/departamento_tipo.dart';

/// Card compacto para exibiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o em grade (3 colunas)
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

  Color _getDepartamentoColor() {
    switch (colaborador.departamento) {
      case DepartamentoTipo.caixa:
        return Colors.blue;
      case DepartamentoTipo.fiscal:
        return Colors.orange;
      case DepartamentoTipo.pacote:
        return Colors.green;
      case DepartamentoTipo.self:
        return Colors.purple;
      case DepartamentoTipo.gerencia:
        return Colors.red;
      case DepartamentoTipo.acougue:
        return Colors.brown;
      case DepartamentoTipo.padaria:
        return Colors.amber;
      case DepartamentoTipo.hortifruti:
        return Colors.greenAccent;
      case DepartamentoTipo.deposito:
        return Colors.grey;
      case DepartamentoTipo.limpeza:
        return Colors.blueGrey;
      case DepartamentoTipo.seguranca:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDepartamentoColor();
    final dept = colaborador.departamento.nome;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null
          ? () => showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                        onTap: () {
                          Navigator.pop(context);
                          onTap();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Deletar',
                            style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          onDelete!();
                        },
                      ),
                    ],
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(
                colaborador.nome.split(' ').first,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                SizedBox(height: 8),
                Divider(height: 1, thickness: 0.5),
                SizedBox(height: 6),
                if (alocacaoAtual != null) ...[
                  _detalhe(
                    Icons.login,
                    _fmtHora(alocacaoAtual!.alocadoEm),
                    AppColors.statusAtivo,
                  ),
                  SizedBox(height: 4),
                  _detalhe(
                    Icons.coffee,
                    alocacaoAtual!.intervaloMarcadoFeito ? 'Feito' : 'Pendente',
                    alocacaoAtual!.intervaloMarcadoFeito
                        ? AppColors.statusCafe
                        : AppColors.statusAtencao,
                  ),
                  SizedBox(height: 4),
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
                    'DisponÃƒÆ’Ã‚Â­vel',
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
        SizedBox(width: 3),
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

  Color _getDepartamentoColor() {
    switch (colaborador.departamento) {
      case DepartamentoTipo.caixa:
        return Colors.blue;
      case DepartamentoTipo.fiscal:
        return Colors.orange;
      case DepartamentoTipo.pacote:
        return Colors.green;
      case DepartamentoTipo.self:
        return Colors.purple;
      case DepartamentoTipo.gerencia:
        return Colors.red;
      case DepartamentoTipo.acougue:
        return Colors.brown;
      case DepartamentoTipo.padaria:
        return Colors.amber;
      case DepartamentoTipo.hortifruti:
        return Colors.greenAccent;
      case DepartamentoTipo.deposito:
        return Colors.grey;
      case DepartamentoTipo.limpeza:
        return Colors.blueGrey;
      case DepartamentoTipo.seguranca:
        return Colors.indigo;
    }
  }

  String _getDepartamentoLabel() {
    return colaborador.departamento.toString().split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: Dimensions.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(Dimensions.paddingSM),
        onTap: onTap,
        // Avatar com iniciais
        leading: CircleAvatar(
          backgroundColor: _getDepartamentoColor(),
          radius: 24,
          child: Text(
            colaborador.gerarIniciais(),
            style: AppTextStyles.title.copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        // InformaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes principais
        title: Text(
          colaborador.nome,
          style: AppTextStyles.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            // Badge de departamento
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getDepartamentoColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getDepartamentoLabel(),
                style: AppTextStyles.caption.copyWith(
                  color: _getDepartamentoColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
            if (colaborador.observacoes != null) ...[
              SizedBox(width: 6),
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
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            if (onDelete != null)
              PopupMenuItem(
                onTap: onDelete,
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Deletar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
