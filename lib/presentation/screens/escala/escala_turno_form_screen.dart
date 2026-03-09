import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/entities/registro_ponto.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import '../../providers/registro_ponto_provider.dart';
import '../../../core/utils/app_notif.dart';

class EscalaTurnoFormScreen extends StatefulWidget {
  final DateTime data;
  final TurnoLocal? turnoExistente;

  const EscalaTurnoFormScreen({
    super.key,
    required this.data,
    this.turnoExistente,
  });

  @override
  State<EscalaTurnoFormScreen> createState() =>
      _EscalaTurnoFormScreenState();
}

class _EscalaTurnoFormScreenState extends State<EscalaTurnoFormScreen> {
  final _entradaController = TextEditingController();
  final _intervaloController = TextEditingController();
  final _retornoController = TextEditingController();
  final _saidaController = TextEditingController();
  final _observacaoController = TextEditingController();

  Colaborador? _colaboradorSelecionado;
  String _tipoTurno = 'trabalho'; // 'trabalho' | 'folga' | 'feriado'

  @override
  void initState() {
    super.initState();
    final t = widget.turnoExistente;
    if (t != null) {
      _entradaController.text = t.entrada ?? '';
      _intervaloController.text = t.intervalo ?? '';
      _retornoController.text = t.retorno ?? '';
      _saidaController.text = t.saida ?? '';
      _observacaoController.text = t.observacao ?? '';
      if (t.feriado) {
        _tipoTurno = 'feriado';
      } else if (t.folga) {
        _tipoTurno = 'folga';
      } else {
        _tipoTurno = 'trabalho';
      }

      // Colaborador já selecionado (será preenchido no build)
    }
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _intervaloController.dispose();
    _retornoController.dispose();
    _saidaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _onColaboradorChanged(Colaborador? c) {
    setState(() => _colaboradorSelecionado = c);
    if (c != null && widget.turnoExistente == null) {
      _preencherHorariosDoRegistro(c.id);
    }
  }

  /// Busca o registro de ponto do colaborador para o dia do turno e preenche os campos.
  Future<void> _preencherHorariosDoRegistro(String colaboradorId) async {
    final provider =
        Provider.of<RegistroPontoProvider>(context, listen: false);
    await provider.loadRegistros(colaboradorId);

    if (!mounted) return;

    // Procura o registro cujo campo 'data' bate com o dia do turno
    RegistroPonto? registro;
    try {
      registro = provider.registros.firstWhere(
        (r) =>
            r.data.year == widget.data.year &&
            r.data.month == widget.data.month &&
            r.data.day == widget.data.day,
      );
    } catch (_) {
      registro = null;
    }

    if (registro != null && mounted) {
      setState(() {
        _entradaController.text = registro!.entrada ?? '';
        _intervaloController.text = registro.intervaloSaida ?? '';
        _retornoController.text = registro.intervaloRetorno ?? '';
        _saidaController.text = registro.saida ?? '';
        // Se for folga/feriado, selecionar o tipo correto
        final obs = registro.observacao?.toUpperCase();
        if (obs == 'FOLGA') {
          _tipoTurno = 'folga';
        } else if (obs == 'FERIADO') {
          _tipoTurno = 'feriado';
        } else {
          _tipoTurno = 'trabalho';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);
    final colaboradores = colaboradorProvider.colaboradores
        .where((c) => c.ativo)
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    // Pré-selecionar colaborador na edição
    if (_colaboradorSelecionado == null && widget.turnoExistente != null) {
      try {
        _colaboradorSelecionado = colaboradores.firstWhere(
            (c) => c.id == widget.turnoExistente!.colaboradorId);
      } catch (_) {}
    }

    final editando = widget.turnoExistente != null;
    final dateLabel = DateFormat(
            "EEEE, dd 'de' MMMM", 'pt_BR')
        .format(widget.data);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(editando ? 'Editar Turno' : 'Novo Turno'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(Dimensions.borderRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _capitalizar(dateLabel),
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // Colaborador
            const Text('Colaborador *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            colaboradores.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.alertWarning,
                      borderRadius:
                          BorderRadius.circular(Dimensions.borderRadius),
                    ),
                    child: const Text(
                      'Nenhum colaborador cadastrado. Vá em Colaboradores e cadastre primeiro.',
                      style: AppTextStyles.body,
                    ),
                  )
                : DropdownButtonFormField<Colaborador>(
                    initialValue: _colaboradorSelecionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            Dimensions.borderRadius),
                      ),
                      prefixIcon: const Icon(Icons.person),
                      hintText: 'Selecione o colaborador',
                    ),
                    items: colaboradores.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.nome} (${c.departamento.nome})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _onColaboradorChanged,
                  ),

            const SizedBox(height: Dimensions.spacingLG),

            // Tipo do turno
            const Text('Tipo do Turno *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTipoChip('trabalho', 'Trabalhando',
                    Icons.work, AppColors.statusAtivo),
                const SizedBox(width: 8),
                _buildTipoChip('folga', 'Folga Semanal',
                    Icons.weekend, AppColors.inactive),
                const SizedBox(width: 8),
                _buildTipoChip('feriado', 'Feriado',
                    Icons.celebration, AppColors.statusAtencao),
              ],
            ),

            // Campos de horário (só se trabalhando)
            if (_tipoTurno == 'trabalho') ...[
              const SizedBox(height: Dimensions.spacingLG),
              const Text('Horários', style: AppTextStyles.label),
              const SizedBox(height: 8),

              // Grid 2x2
              Row(
                children: [
                  Expanded(
                    child: _buildHorarioField(
                      label: 'Entrada',
                      controller: _entradaController,
                      icon: Icons.login,
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: _buildHorarioField(
                      label: 'Intervalo',
                      controller: _intervaloController,
                      icon: Icons.coffee,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spacingSM),
              Row(
                children: [
                  Expanded(
                    child: _buildHorarioField(
                      label: 'Retorno',
                      controller: _retornoController,
                      icon: Icons.keyboard_return,
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: _buildHorarioField(
                      label: 'Saída',
                      controller: _saidaController,
                      icon: Icons.logout,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),
              // Atalhos de horários frequentes
              _buildAtalhosHorarios(),
            ],

            const SizedBox(height: Dimensions.spacingLG),

            // Observação
            TextFormField(
              controller: _observacaoController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Observação (opcional)',
                hintText: 'Ex: Cobertura, troca de folga...',
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                ),
              ),
            ),

            const SizedBox(height: Dimensions.spacingXL),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _colaboradorSelecionado == null ? null : _salvar,
                icon: const Icon(Icons.check),
                label: Text(editando ? 'Atualizar' : 'Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoChip(
      String tipo, String label, IconData icon, Color cor) {
    final sel = _tipoTurno == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoTurno = tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: sel ? cor.withValues(alpha: 0.15) : AppColors.backgroundSection,
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            border: Border.all(
              color: sel ? cor : AppColors.border,
              width: sel ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: sel ? cor : AppColors.textSecondary, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: sel ? cor : AppColors.textSecondary,
                  fontWeight:
                      sel ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorarioField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        hintText: 'HH:MM',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        ),
        isDense: true,
      ),
      onTap: () => _selecionarHorario(controller),
      readOnly: true,
    );
  }

  Widget _buildAtalhosHorarios() {
    // Atalhos de turnos comuns em supermercados
    final atalhos = [
      ('07:40–17:40', '07:40', '12:30', '13:30', '17:40'),
      ('08:00–18:00', '08:00', '12:00', '13:00', '18:00'),
      ('09:00–18:00', '09:00', '13:00', '14:00', '18:00'),
      ('11:20–21:20', '11:20', '14:20', '16:20', '21:20'),
      ('12:00–21:40', '12:00', '16:00', '17:00', '21:40'),
      ('14:00–22:00', '14:00', '18:00', '18:40', '22:00'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atalhos de turno',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: atalhos.map((a) {
            return ActionChip(
              label: Text(
                a.$1,
                style: AppTextStyles.caption,
              ),
              onPressed: () {
                setState(() {
                  _entradaController.text = a.$2;
                  _intervaloController.text = a.$3;
                  _retornoController.text = a.$4;
                  _saidaController.text = a.$5;
                });
              },
              backgroundColor: AppColors.backgroundSection,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selecionarHorario(
      TextEditingController controller) async {
    // Parsear valor atual se houver
    TimeOfDay? inicial;
    if (controller.text.isNotEmpty) {
      final partes = controller.text.split(':');
      if (partes.length == 2) {
        inicial = TimeOfDay(
          hour: int.tryParse(partes[0]) ?? 8,
          minute: int.tryParse(partes[1]) ?? 0,
        );
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: inicial ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.hour.toString().padLeft(2, "0")}:${picked.minute.toString().padLeft(2, "0")}';
      });
    }
  }

  void _salvar() {
    if (_colaboradorSelecionado == null) return;

    final provider =
        Provider.of<EscalaProvider>(context, listen: false);

    provider.adicionarOuAtualizarTurno(
      colaboradorId: _colaboradorSelecionado!.id,
      colaboradorNome: _colaboradorSelecionado!.nome,
      departamento: _colaboradorSelecionado!.departamento,
      data: widget.data,
      entrada: _tipoTurno == 'trabalho'
          ? _entradaController.text.trim().isEmpty
              ? null
              : _entradaController.text.trim()
          : null,
      intervalo: _tipoTurno == 'trabalho'
          ? _intervaloController.text.trim().isEmpty
              ? null
              : _intervaloController.text.trim()
          : null,
      retorno: _tipoTurno == 'trabalho'
          ? _retornoController.text.trim().isEmpty
              ? null
              : _retornoController.text.trim()
          : null,
      saida: _tipoTurno == 'trabalho'
          ? _saidaController.text.trim().isEmpty
              ? null
              : _saidaController.text.trim()
          : null,
      folga: _tipoTurno == 'folga',
      feriado: _tipoTurno == 'feriado',
      observacao: _observacaoController.text.trim().isEmpty
          ? null
          : _observacaoController.text.trim(),
    );

    AppNotif.show(
      context,
      titulo: 'Escala Salva',
      mensagem: '${_colaboradorSelecionado!.nome} '
          '${widget.turnoExistente != null ? "atualizado" : "adicionado"} na escala!',
      tipo: 'saida',
      cor: AppColors.success,
    );

    Navigator.pop(context);
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
