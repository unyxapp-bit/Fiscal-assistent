import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/services/anexo_upload_service.dart';
import '../../../domain/entities/nota.dart';
import '../../../domain/enums/tipo_lembrete.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/nota_provider.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de FormulÃƒÆ’Ã‚Â¡rio de Nota ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â criar ou editar anotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes, tarefas e lembretes.
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
  final _anexoUploadService = AnexoUploadService();

  TipoLembrete _tipo = TipoLembrete.anotacao;
  bool _importante = false;
  bool _lembreteAtivo = true;
  DateTime? _dataLembrete;
  bool _salvando = false;

  AnexoSelecionado? _fotoSelecionada;
  AnexoSelecionado? _arquivoSelecionado;
  String? _fotoUrlAtual;
  String? _fotoNomeAtual;
  String? _arquivoUrlAtual;
  String? _arquivoNomeAtual;
  bool _deveRemoverFoto = false;
  bool _deveRemoverArquivo = false;

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
      _fotoUrlAtual = widget.nota!.fotoUrl;
      _fotoNomeAtual = widget.nota!.fotoNome;
      _arquivoUrlAtual = widget.nota!.arquivoUrl;
      _arquivoNomeAtual = widget.nota!.arquivoNome;
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
          colorScheme: ColorScheme.light(primary: AppColors.primary),
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
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (hora == null) return;

    setState(() {
      _dataLembrete =
          DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _selecionarFoto() async {
    final selecionado = await _anexoUploadService.selecionarFoto();
    if (!mounted || selecionado == null) return;
    setState(() {
      _fotoSelecionada = selecionado;
      _deveRemoverFoto = false;
    });
  }

  Future<void> _selecionarArquivo() async {
    final selecionado = await _anexoUploadService.selecionarArquivo();
    if (!mounted || selecionado == null) return;
    setState(() {
      _arquivoSelecionado = selecionado;
      _deveRemoverArquivo = false;
    });
  }

  void _removerFoto() {
    setState(() {
      _fotoSelecionada = null;
      _fotoUrlAtual = null;
      _fotoNomeAtual = null;
      _deveRemoverFoto = true;
    });
  }

  void _removerArquivo() {
    setState(() {
      _arquivoSelecionado = null;
      _arquivoUrlAtual = null;
      _arquivoNomeAtual = null;
      _deveRemoverArquivo = true;
    });
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      final provider = Provider.of<NotaProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final hasDate =
          _tipo == TipoLembrete.lembrete || _tipo == TipoLembrete.tarefa;
      final fiscalId = auth.user?.id ?? '';
      final notaId = _isEdicao ? widget.nota!.id : const Uuid().v4();

      String? fotoUrl = _fotoUrlAtual;
      String? fotoNome = _fotoNomeAtual;
      String? arquivoUrl = _arquivoUrlAtual;
      String? arquivoNome = _arquivoNomeAtual;

      if (_deveRemoverFoto) {
        fotoUrl = null;
        fotoNome = null;
      }
      if (_deveRemoverArquivo) {
        arquivoUrl = null;
        arquivoNome = null;
      }

      if ((_fotoSelecionada != null || _arquivoSelecionado != null) &&
          fiscalId.isEmpty) {
        throw Exception(
            'UsuÃƒÆ’Ã‚Â¡rio nÃƒÆ’Ã‚Â£o autenticado para upload de anexo');
      }

      if (_fotoSelecionada != null) {
        fotoUrl = await _anexoUploadService.upload(
          anexo: _fotoSelecionada!,
          fiscalId: fiscalId,
          modulo: 'notas',
          entidadeId: notaId,
        );
        fotoNome = _fotoSelecionada!.nomeArquivo;
      }

      if (_arquivoSelecionado != null) {
        arquivoUrl = await _anexoUploadService.upload(
          anexo: _arquivoSelecionado!,
          fiscalId: fiscalId,
          modulo: 'notas',
          entidadeId: notaId,
        );
        arquivoNome = _arquivoSelecionado!.nomeArquivo;
      }

      if (_isEdicao) {
        final notaAtualizada = widget.nota!.copyWith(
          titulo: _tituloController.text.trim(),
          conteudo: _conteudoController.text.trim(),
          tipo: _tipo,
          importante: _importante,
          lembreteAtivo: _tipo == TipoLembrete.lembrete ? _lembreteAtivo : true,
          dataLembrete: hasDate ? _dataLembrete : null,
          fotoUrl: fotoUrl,
          fotoNome: fotoNome,
          arquivoUrl: arquivoUrl,
          arquivoNome: arquivoNome,
          updatedAt: DateTime.now(),
        );
        provider.atualizarNota(notaAtualizada);
        if (!mounted) return;
        AppNotif.show(
          context,
          titulo: 'Nota Atualizada',
          mensagem: 'Nota atualizada!',
          tipo: 'saida',
          cor: AppColors.success,
        );
      } else {
        provider.adicionarNota(
          _tituloController.text.trim(),
          _conteudoController.text.trim(),
          _tipo,
          id: notaId,
          dataLembrete: hasDate ? _dataLembrete : null,
          importante: _importante,
          lembreteAtivo: _tipo == TipoLembrete.lembrete ? _lembreteAtivo : true,
          fotoUrl: fotoUrl,
          fotoNome: fotoNome,
          arquivoUrl: arquivoUrl,
          arquivoNome: arquivoNome,
        );
        if (!mounted) return;
        final eventoProvider =
            Provider.of<EventoTurnoProvider>(context, listen: false);
        if (eventoProvider.turnoAtivo) {
          final fiscalEvento =
              Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
          eventoProvider.registrar(
            fiscalId: fiscalEvento,
            tipo: TipoEvento.anotacaoCriada,
            detalhe: '${_tipo.nome}: ${_tituloController.text.trim()}',
          );
        }
        AppNotif.show(
          context,
          titulo: 'Nota Criada',
          mensagem: '${_tipo.nome} criada!',
          tipo: 'saida',
          cor: AppColors.success,
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppNotif.show(
        context,
        titulo: 'Erro ao salvar',
        mensagem: 'NÃƒÆ’Ã‚Â£o foi possÃƒÆ’Ã‚Â­vel salvar com anexos: $e',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String _formatDataLembrete(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} ÃƒÆ’Ã‚Â s $h:$m';
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
              // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Seletor de Tipo ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
              Text('Tipo', style: AppTextStyles.h4),
              SizedBox(height: Dimensions.spacingSM),
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
                              SizedBox(height: 4),
                              Text(
                                tipo.nome,
                                style: AppTextStyles.caption.copyWith(
                                  color:
                                      sel ? tipo.cor : AppColors.textSecondary,
                                  fontWeight:
                                      sel ? FontWeight.bold : FontWeight.normal,
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

              SizedBox(height: Dimensions.spacingLG),

              // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ TÃƒÆ’Ã‚Â­tulo ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'TÃƒÆ’Ã‚Â­tulo *',
                  hintText: _tipo == TipoLembrete.tarefa
                      ? 'O que precisa fazer?'
                      : _tipo == TipoLembrete.lembrete
                          ? 'Do que quer ser lembrado?'
                          : 'Assunto da anotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'TÃƒÆ’Ã‚Â­tulo ÃƒÆ’Ã‚Â© obrigatÃƒÆ’Ã‚Â³rio'
                    : null,
              ),

              SizedBox(height: Dimensions.spacingMD),

              // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ConteÃƒÆ’Ã‚Âºdo ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
              TextFormField(
                controller: _conteudoController,
                decoration: InputDecoration(
                  labelText: _tipo == TipoLembrete.tarefa
                      ? 'Detalhes (opcional)'
                      : 'ConteÃƒÆ’Ã‚Âºdo',
                  hintText: _tipo == TipoLembrete.anotacao
                      ? 'Escreva sua anotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o...'
                      : _tipo == TipoLembrete.tarefa
                          ? 'Mais informaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes sobre a tarefa...'
                          : 'Detalhes do lembrete...',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: _tipo == TipoLembrete.anotacao
                    ? (v) => (v == null || v.trim().isEmpty)
                        ? 'ConteÃƒÆ’Ã‚Âºdo ÃƒÆ’Ã‚Â© obrigatÃƒÆ’Ã‚Â³rio para anotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes'
                        : null
                    : null,
              ),

              // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Data / Prazo (Lembrete e Tarefa) ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

              SizedBox(height: Dimensions.spacingMD),
              Text('Anexos (opcional)', style: AppTextStyles.h4),
              SizedBox(height: Dimensions.spacingSM),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.photo_camera_outlined),
                      title: Text('Foto'),
                      subtitle: Text(
                        _fotoSelecionada?.nomeArquivo ??
                            _fotoNomeAtual ??
                            'Nenhuma foto selecionada',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_fotoSelecionada != null || _fotoUrlAtual != null)
                            IconButton(
                              onPressed: _salvando ? null : _removerFoto,
                              icon: Icon(Icons.delete_outline),
                              tooltip: 'Remover foto',
                            ),
                          IconButton(
                            onPressed: _salvando ? null : _selecionarFoto,
                            icon: Icon(Icons.add_a_photo_outlined),
                            tooltip: 'Selecionar foto',
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.attach_file),
                      title: Text('Arquivo'),
                      subtitle: Text(
                        _arquivoSelecionado?.nomeArquivo ??
                            _arquivoNomeAtual ??
                            'Nenhum arquivo selecionado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_arquivoSelecionado != null ||
                              _arquivoUrlAtual != null)
                            IconButton(
                              onPressed: _salvando ? null : _removerArquivo,
                              icon: Icon(Icons.delete_outline),
                              tooltip: 'Remover arquivo',
                            ),
                          IconButton(
                            onPressed: _salvando ? null : _selecionarArquivo,
                            icon: Icon(Icons.upload_file_outlined),
                            tooltip: 'Selecionar arquivo',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (showDate) ...[
                SizedBox(height: Dimensions.spacingMD),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.alarm, color: AppColors.primary),
                    title: Text(
                      _tipo == TipoLembrete.tarefa
                          ? 'Prazo (opcional)'
                          : 'Data e Hora do Lembrete',
                    ),
                    subtitle: Text(
                      _dataLembrete != null
                          ? _formatDataLembrete(_dataLembrete!)
                          : 'NÃƒÆ’Ã‚Â£o definido',
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
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _dataLembrete = null),
                          ),
                        IconButton(
                          icon: Icon(Icons.edit_calendar),
                          onPressed: _selecionarDataHora,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Toggle notificaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o (sÃƒÆ’Ã‚Â³ Lembrete) ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
              if (_tipo == TipoLembrete.lembrete) ...[
                SwitchListTile(
                  title: Text('NotificaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o ativa'),
                  subtitle:
                      Text('Desative se nÃƒÆ’Ã‚Â£o quiser ser notificado'),
                  value: _lembreteAtivo,
                  onChanged: (v) => setState(() => _lembreteAtivo = v),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],

              SizedBox(height: Dimensions.spacingMD),

              // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Banner de importante ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
              if (_importante)
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
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

              SizedBox(height: Dimensions.spacingXL),

              // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ BotÃƒÆ’Ã‚Âµes ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _salvando ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _salvando
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdicao ? 'Salvar' : 'Criar'),
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
