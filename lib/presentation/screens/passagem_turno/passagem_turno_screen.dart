import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/passagem_turno_provider.dart';
import '../../../core/utils/app_notif.dart';

class PassagemTurnoScreen extends StatefulWidget {
  const PassagemTurnoScreen({super.key});

  @override
  State<PassagemTurnoScreen> createState() => _PassagemTurnoScreenState();
}

class _PassagemTurnoScreenState extends State<PassagemTurnoScreen> {
  bool _showForm = false;
  final _resumoCtrl = TextEditingController();
  final _pendenciasCtrl = TextEditingController();
  final _recadosCtrl = TextEditingController();

  @override
  void dispose() {
    _resumoCtrl.dispose();
    _pendenciasCtrl.dispose();
    _recadosCtrl.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} ÃƒÆ’Ã‚Â s $h:$min';
  }

  void _salvar(PassagemTurnoProvider provider) {
    final resumo = _resumoCtrl.text.trim();
    if (resumo.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Campo InvÃƒÆ’Ã‚Â¡lido',
        mensagem: 'Preencha ao menos o resumo do turno',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    provider.registrar(
      resumo: resumo,
      pendencias: _pendenciasCtrl.text.trim(),
      recados: _recadosCtrl.text.trim(),
    );

    _resumoCtrl.clear();
    _pendenciasCtrl.clear();
    _recadosCtrl.clear();
    setState(() => _showForm = false);

    AppNotif.show(
      context,
      titulo: 'Turno Registrado',
      mensagem: 'Passagem de turno registrada!',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  String _textoCompartilhamento(PassagemTurno p) {
    final buf = StringBuffer();
    buf.writeln(
        'PASSAGEM DE TURNO ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${_formatDateTime(p.registradaEm)}');
    buf.writeln('ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬' * 30);
    buf.writeln('RESUMO DO TURNO:');
    buf.writeln(p.resumo);
    if (p.pendencias.isNotEmpty) {
      buf.writeln();
      buf.writeln('PENDÃƒÆ’Ã…Â NCIAS:');
      buf.writeln(p.pendencias);
    }
    if (p.recados.isNotEmpty) {
      buf.writeln();
      buf.writeln('RECADOS:');
      buf.writeln(p.recados);
    }
    return buf.toString().trim();
  }

  Future<void> _copiar(PassagemTurno p) async {
    await Clipboard.setData(ClipboardData(text: _textoCompartilhamento(p)));
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Copiado para ÃƒÆ’Ã‚Â¡rea de transferÃƒÆ’Ã‚Âªncia',
      tipo: 'intervalo',
    );
  }

  void _compartilhar(PassagemTurno p) {
    Share.share(
      _textoCompartilhamento(p),
      subject: 'Passagem de turno ${_formatDateTime(p.registradaEm)}',
    );
  }

  void _confirmarDelete(
    BuildContext context,
    PassagemTurno p,
    PassagemTurnoProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir registro'),
        content: Text('Excluir esta passagem de turno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletar(p.id);
              Navigator.pop(ctx);
            },
            child: Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(PassagemTurnoProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingLG),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child:
                      Text('Nova Passagem de Turno', style: AppTextStyles.h4),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => setState(() => _showForm = false),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: Dimensions.spacingSM),

            // Resumo
            TextFormField(
              controller: _resumoCtrl,
              decoration: InputDecoration(
                labelText: 'Resumo do turno *',
                hintText: 'O que aconteceu de relevante no turno?',
                prefixIcon: Icon(Icons.summarize),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.spacingMD),

            // PendÃƒÆ’Ã‚Âªncias
            TextFormField(
              controller: _pendenciasCtrl,
              decoration: InputDecoration(
                labelText: 'PendÃƒÆ’Ã‚Âªncias',
                hintText: 'O que ficou para resolver no prÃƒÆ’Ã‚Â³ximo turno?',
                prefixIcon: Icon(Icons.pending_actions),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.spacingMD),

            // Recados
            TextFormField(
              controller: _recadosCtrl,
              decoration: InputDecoration(
                labelText: 'Recados',
                hintText: 'Alguma mensagem para o prÃƒÆ’Ã‚Â³ximo fiscal?',
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.spacingLG),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _salvar(provider),
                icon: Icon(Icons.save),
                label: Text('Registrar Passagem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistro(
    BuildContext context,
    PassagemTurno p,
    PassagemTurnoProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(0x1A1976D2),
          child: Icon(Icons.handshake, color: AppColors.primary),
        ),
        title: Text(_formatDateTime(p.registradaEm), style: AppTextStyles.h4),
        subtitle: Text(
          p.resumo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.share_outlined,
                  size: 18, color: AppColors.textSecondary),
              tooltip: 'Compartilhar',
              onPressed: () => _compartilhar(p),
            ),
            IconButton(
              icon: Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
              tooltip: 'Copiar',
              onPressed: () => _copiar(p),
            ),
            IconButton(
              icon:
                  Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              tooltip: 'Excluir',
              onPressed: () => _confirmarDelete(context, p, provider),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingMD, 0,
                Dimensions.paddingMD, Dimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                _buildSection('Resumo do Turno', p.resumo),
                if (p.pendencias.isNotEmpty) ...[
                  SizedBox(height: Dimensions.spacingMD),
                  _buildSection('PendÃƒÆ’Ã‚Âªncias', p.pendencias,
                      icon: Icons.pending_actions,
                      cor: AppColors.statusAtencao),
                ],
                if (p.recados.isNotEmpty) ...[
                  SizedBox(height: Dimensions.spacingMD),
                  _buildSection('Recados', p.recados,
                      icon: Icons.message, cor: AppColors.primary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String titulo, String conteudo,
      {IconData? icon, Color? cor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: cor ?? AppColors.textSecondary),
              SizedBox(width: 4),
            ],
            Text(
              titulo,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: cor ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(conteudo, style: AppTextStyles.body),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PassagemTurnoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Passagem de Turno'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FormulÃƒÆ’Ã‚Â¡rio ou botÃƒÆ’Ã‚Â£o para iniciar
            if (_showForm)
              _buildForm(provider)
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: Icon(Icons.add),
                  label: Text('Registrar Passagem de Turno'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                  ),
                ),
              ),

            SizedBox(height: Dimensions.spacingLG),

            // HistÃƒÆ’Ã‚Â³rico
            if (provider.historico.isNotEmpty) ...[
              Text(
                'HistÃƒÆ’Ã‚Â³rico (${provider.historico.length})',
                style: AppTextStyles.h3,
              ),
              SizedBox(height: Dimensions.spacingMD),
              ...provider.historico.map(
                (p) => _buildRegistro(context, p, provider),
              ),
            ] else if (!_showForm)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Icon(Icons.handshake,
                          size: 64, color: AppColors.inactive),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma passagem registrada',
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Registre o que aconteceu no turno\npara o prÃƒÆ’Ã‚Â³ximo fiscal',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
