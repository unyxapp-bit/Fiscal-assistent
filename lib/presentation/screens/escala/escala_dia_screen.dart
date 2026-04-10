import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/escala_provider.dart';
import 'escala_turno_form_screen.dart';

class EscalaDiaScreen extends StatelessWidget {
  final DateTime data;

  const EscalaDiaScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalaProvider>(context);
    final turnos = provider.getTurnosByData(data);

    int entradaOrd(TurnoLocal t) {
      if (t.entrada == null) return 9999;
      final p = t.entrada!.split(':');
      if (p.length != 2) return 9999;
      return (int.tryParse(p[0]) ?? 99) * 60 + (int.tryParse(p[1]) ?? 99);
    }

    final caixas = turnos
        .where((t) =>
            t.departamento == DepartamentoTipo.caixa ||
            t.departamento == DepartamentoTipo.self)
        .toList()
      ..sort((a, b) => entradaOrd(a).compareTo(entradaOrd(b)));
    final fiscais = turnos
        .where((t) => t.departamento == DepartamentoTipo.fiscal)
        .toList()
      ..sort((a, b) => entradaOrd(a).compareTo(entradaOrd(b)));
    final outros = turnos
        .where((t) =>
            t.departamento != DepartamentoTipo.caixa &&
            t.departamento != DepartamentoTipo.self &&
            t.departamento != DepartamentoTipo.fiscal)
        .toList()
      ..sort((a, b) => entradaOrd(a).compareTo(entradaOrd(b)));

    final dateFormat = DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _capitalizar(DateFormat('EEE dd/MM', 'pt_BR').format(data)),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (turnos.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: 'Limpar dia',
              onPressed: () => _confirmarLimparDia(context, provider),
            ),
        ],
      ),
      body: turnos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today,
                      size: 64, color: AppColors.inactive),
                  SizedBox(height: 16),
                  Text(
                    _capitalizar(dateFormat.format(data)),
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nenhuma escala cadastrada para este dia',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _abrirFormulario(context, null),
                    icon: Icon(Icons.add),
                    label: Text('Adicionar Colaborador'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              children: [
                // CabeÃƒÂ§alho com data completa
                Text(
                  _capitalizar(dateFormat.format(data)),
                  style:
                      AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  '${turnos.where((t) => t.trabalhando).length} trabalhando'
                  ' Ã¢â‚¬Â¢ ${turnos.where((t) => t.folga || t.feriado).length} folga/feriado',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),

                SizedBox(height: Dimensions.spacingLG),

                // CAIXA
                if (caixas.isNotEmpty) ...[
                  _buildSecaoHeader('CAIXA / SELF'),
                  ...caixas.map((t) => _buildTurnoCard(context, t, provider)),
                  SizedBox(height: Dimensions.spacingMD),
                ],

                // FISCAL
                if (fiscais.isNotEmpty) ...[
                  _buildSecaoHeader('FISCAL'),
                  ...fiscais.map((t) => _buildTurnoCard(context, t, provider)),
                  SizedBox(height: Dimensions.spacingMD),
                ],

                // OUTROS
                if (outros.isNotEmpty) ...[
                  _buildSecaoHeader('OUTROS SETORES'),
                  ...outros.map((t) => _buildTurnoCard(context, t, provider)),
                  SizedBox(height: Dimensions.spacingMD),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context, null),
        icon: Icon(Icons.person_add),
        label: Text('Adicionar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSecaoHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            titulo,
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnoCard(
      BuildContext context, TurnoLocal turno, EscalaProvider provider) {
    final cor = turno.feriado
        ? AppColors.statusAtencao
        : turno.folga
            ? AppColors.inactive
            : AppColors.statusAtivo;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.15),
          child: Text(
            turno.colaboradorNome
                .split(' ')
                .first
                .substring(0, 1)
                .toUpperCase(),
            style: TextStyle(color: cor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(turno.colaboradorNome, style: AppTextStyles.h4),
        subtitle: turno.trabalhando
            ? Text(
                'Entrada: ${turno.entrada ?? "Ã¢â‚¬â€œ"}  '
                'Intervalo: ${turno.intervalo ?? "Ã¢â‚¬â€œ"}  '
                'Retorno: ${turno.retorno ?? "Ã¢â‚¬â€œ"}  '
                'SaÃƒÂ­da: ${turno.saida ?? "Ã¢â‚¬â€œ"}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              )
            : Text(
                turno.feriado ? 'Feriado' : 'Folga Semanal',
                style: AppTextStyles.caption.copyWith(color: cor),
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'editar') {
              _abrirFormulario(context, turno);
            } else if (value == 'remover') {
              provider.removerTurno(turno.id);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'editar',
              child: Row(children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Editar'),
              ]),
            ),
            PopupMenuItem(
              value: 'remover',
              child: Row(children: [
                Icon(Icons.delete, size: 18, color: AppColors.danger),
                SizedBox(width: 8),
                Text('Remover', style: TextStyle(color: AppColors.danger)),
              ]),
            ),
          ],
        ),
        onTap: () => _abrirFormulario(context, turno),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, TurnoLocal? turno) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EscalaTurnoFormScreen(data: data, turnoExistente: turno),
      ),
    );
  }

  void _confirmarLimparDia(BuildContext context, EscalaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Limpar dia'),
        content:
            Text('Deseja remover todos os turnos cadastrados para este dia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.limparDia(data);
              Navigator.pop(ctx);
            },
            child: Text('Limpar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
