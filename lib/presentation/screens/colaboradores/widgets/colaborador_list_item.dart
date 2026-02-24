import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/enums/departamento_tipo.dart';

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
        side: const BorderSide(color: AppColors.cardBorder),
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
        // Informações principais
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
            const SizedBox(width: 8),
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
              child: const Row(
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
                child: const Row(
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
