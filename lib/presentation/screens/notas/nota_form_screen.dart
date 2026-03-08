import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/nota.dart';
import '../../../domain/enums/tipo_lembrete.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/nota_provider.dart';

/// Tela de Formulário de Nota — criar ou editar anotações, tarefas e lembretes.
class NotaFormScreen extends StatefulWidget {
  final Nota? nota;
  final TipoLembrete? tipoInicial;

  const NotaFormScreen({super.key, this.nota, this.tipoInicial});

  @override
  State<NotaFormScreen> createState() => _NotaFormScreenState();
}

class _NotaFormScreenState extends State<NotaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();

  TipoLembrete _tipo = TipoLembrete.anotacao;
  bool _importante = false;
  bool _lembreteAtivo = true;
  DateTime? _dataLembrete;

  bool get _isEdicao => widget.nota != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      _tituloController.text = widget.nota!.titulo;
      _conteudoController.text = widget.nota!.conteudo;
      _tipo = widget.nota!.tipo;
      _importante = widget.nota!.importante;
      _lembreteAtivo = widget.nota!.lembreteAtivo;
      _dataLembrete = widget.nota!.dataLembrete;
    } else if (widget.tipoInicial != null) {
      _tipo = widget.tipoInicial!;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataHora() async {
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataLembrete != null && _dataLembrete!.isAfter(now)
          ? _dataLembrete!
          : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: _dataLembrete != null
          ? TimeOfDay.fromDateTime(_dataLembrete!)
          : TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (hora == null) return;

    setState(() {
      _dataLembrete = DateTime(
          data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<NotaProvider>(context, listen: false);
    final hasDate =
        _tipo == TipoLembrete.lembrete || _tipo == TipoLembrete.tarefa;

    if (_isEdicao) {
      final notaAtualizada = widget.nota!.copyWith(
        titulo: _tituloController.text.trim(),
        conteudo: _conteudoController.text.trim(),
        tipo: _tipo,
        importante: _importante,
        lembreteAtivo: _tipo == TipoLembrete.lembrete ? _lembreteAtivo : true,
        dataLembrete: hasDate ? _dataLembrete : null,
        updatedAt: DateTime.now(),
      );
      provider.atualizarNota(notaAtualizada);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nota atualizada!'),
            backgroundColor: AppColors.success),
      );
    } else {
      provider.adicionarNota(
        _tituloController.text.trim(),
        _conteudoController.text.trim(),
        _tipo,
        dataLembrete: hasDate ? _dataLembrete : null,
        importante: _importante,
        lembreteAtivo: _tipo == TipoLembrete.lembrete ? _lembreteAtivo : true,
      );
      if (!mounted) return;
      final eventoProvider = Provider.of<EventoTurnoProvider>(context, listen: false);
      if (eventoProvider.turnoAtivo) {
        final fiscalId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
        eventoProvider.registrar(
          fiscalId: fiscalId,
          tipo: TipoEvento.anotacaoCriada,
          detalhe: '${_tipo.nome}: ${_tituloController.text.trim()}',
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${_tipo.nome} criada!'),
            backgroundColor: AppColors.success),
      );
    }

    Navigator.of(context).pop(true);
  }

  String _formatDataLembrete(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} às $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final showDate =
        _tipo == TipoLembrete.lembrete || _tipo == TipoLembrete.tarefa;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEdicao ? 'Editar ${_tipo.nome}' : 'Nova ${_tipo.nome}',
          style: AppTextStyles.h3,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _importante ? Icons.star : Icons.star_border,
              color: _importante ? Colors.orange : null,
            ),
            onPressed: () => setState(() => _importante = !_importante),
            tooltip:
                _importante ? 'Remover destaque' : 'Marcar como importante',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Seletor de Tipo ─────────────────────────────────────────
              const Text('Tipo', style: AppTextStyles.h4),
              const SizedBox(height: Dimensions.spacingSM),
              Row(
                children: TipoLembrete.values.map((tipo) {
                  final sel = _tipo == tipo;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _tipo = tipo),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMD),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSM),
                          decoration: BoxDecoration(
                            color: sel
                                ? tipo.cor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: sel ? tipo.cor : AppColors.inactive,
                              width: sel ? 2 : 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusMD),
                          ),
                          child: Column(
                            children: [
                              Icon(tipo.icone,
                                  color: sel ? tipo.cor : AppColors.inactive,
                                  size: 20),
                              const SizedBox(height: 4),
                              Text(
                                tipo.nome,
                                style: AppTextStyles.caption.copyWith(
                                  color: sel
                                      ? tipo.cor
                                      : AppColors.textSecondary,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // ── Título ──────────────────────────────────────────────────
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  hintText: _tipo == TipoLembrete.tarefa
                      ? 'O que precisa fazer?'
                      : _tipo == TipoLembrete.lembrete
                          ? 'Do que quer ser lembrado?'
                          : 'Assunto da anotação',
                  prefixIcon: const Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Título é obrigatório'
                    : null,
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // ── Conteúdo ────────────────────────────────────────────────
              TextFormField(
                controller: _conteudoController,
                decoration: InputDecoration(
                  labelText: _tipo == TipoLembrete.tarefa
                      ? 'Detalhes (opcional)'
                      : 'Conteúdo',
                  hintText: _tipo == TipoLembrete.anotacao
                      ? 'Escreva sua anotação...'
                      : _tipo == TipoLembrete.tarefa
                          ? 'Mais informações sobre a tarefa...'
                          : 'Detalhes do lembrete...',
                  prefixIcon: const Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: _tipo == TipoLembrete.anotacao
                    ? (v) => (v == null || v.trim().isEmpty)
                        ? 'Conteúdo é obrigatório para anotações'
                        : null
                    : null,
              ),

              // ── Data / Prazo (Lembrete e Tarefa) ────────────────────────
              if (showDate) ...[
                const SizedBox(height: Dimensions.spacingMD),
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.alarm, color: AppColors.primary),
                    title: Text(
                      _tipo == TipoLembrete.tarefa
                          ? 'Prazo (opcional)'
                          : 'Data e Hora do Lembrete',
                    ),
                    subtitle: Text(
                      _dataLembrete != null
                          ? _formatDataLembrete(_dataLembrete!)
                          : 'Não definido',
                      style: AppTextStyles.body.copyWith(
                        color: _dataLembrete != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dataLembrete != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _dataLembrete = null),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_calendar),
                          onPressed: _selecionarDataHora,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Toggle notificação (só Lembrete) ─────────────────────────
              if (_tipo == TipoLembrete.lembrete) ...[
                SwitchListTile(
                  title: const Text('Notificação ativa'),
                  subtitle:
                      const Text('Desative se não quiser ser notificado'),
                  value: _lembreteAtivo,
                  onChanged: (v) => setState(() => _lembreteAtivo = v),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],

              const SizedBox(height: Dimensions.spacingMD),

              // ── Banner de importante ────────────────────────────────────
              if (_importante)
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusMD),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Marcado como importante',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: Dimensions.spacingXL),

              // ── Botões ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isEdicao ? 'Salvar' : 'Criar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
