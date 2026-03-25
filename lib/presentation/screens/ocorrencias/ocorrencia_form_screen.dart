import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/app_notif.dart';
import '../../../data/services/anexo_upload_service.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/ocorrencia_provider.dart';

class OcorrenciaFormScreen extends StatefulWidget {
  final Ocorrencia? ocorrencia;
  final String? caixaId;
  final String? caixaNome;
  final String? colaboradorId;
  final String? colaboradorNome;

  const OcorrenciaFormScreen({
    super.key,
    this.ocorrencia,
    this.caixaId,
    this.caixaNome,
    this.colaboradorId,
    this.colaboradorNome,
  });

  @override
  State<OcorrenciaFormScreen> createState() => _OcorrenciaFormScreenState();
}

class _OcorrenciaFormScreenState extends State<OcorrenciaFormScreen> {
  final _tipoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _anexoUploadService = AnexoUploadService();

  GravidadeOcorrencia _gravidade = GravidadeOcorrencia.media;
  bool _salvando = false;
  AnexoSelecionado? _fotoSelecionada;
  AnexoSelecionado? _arquivoSelecionado;

  String? _fotoUrlAtual;
  String? _fotoNomeAtual;
  String? _arquivoUrlAtual;
  String? _arquivoNomeAtual;
  bool _deveRemoverFoto = false;
  bool _deveRemoverArquivo = false;

  bool get _isEdicao => widget.ocorrencia != null;
  String? get _caixaId => widget.ocorrencia?.caixaId ?? widget.caixaId;
  String? get _caixaNome => widget.ocorrencia?.caixaNome ?? widget.caixaNome;
  String? get _colaboradorId =>
      widget.ocorrencia?.colaboradorId ?? widget.colaboradorId;
  String? get _colaboradorNome =>
      widget.ocorrencia?.colaboradorNome ?? widget.colaboradorNome;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      final ocorrencia = widget.ocorrencia!;
      _tipoCtrl.text = ocorrencia.tipo;
      _descricaoCtrl.text = ocorrencia.descricao;
      _gravidade = ocorrencia.gravidade;
      _fotoUrlAtual = ocorrencia.fotoUrl;
      _fotoNomeAtual = ocorrencia.fotoNome;
      _arquivoUrlAtual = ocorrencia.arquivoUrl;
      _arquivoNomeAtual = ocorrencia.arquivoNome;
    }
  }

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
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

    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Campo invalido',
        mensagem: 'Descreva o que aconteceu',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ocorrenciaProvider =
        Provider.of<OcorrenciaProvider>(context, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    setState(() => _salvando = true);
    try {
      final tipo =
          _tipoCtrl.text.trim().isEmpty ? 'Outro' : _tipoCtrl.text.trim();
      final fiscalId = auth.user?.id ?? '';
      final ocorrenciaId =
          _isEdicao ? widget.ocorrencia!.id : const Uuid().v4();

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
        throw Exception('Usuario nao autenticado para upload de anexo');
      }

      if (_fotoSelecionada != null) {
        fotoUrl = await _anexoUploadService.upload(
          anexo: _fotoSelecionada!,
          fiscalId: fiscalId,
          modulo: 'ocorrencias',
          entidadeId: ocorrenciaId,
        );
        fotoNome = _fotoSelecionada!.nomeArquivo;
      }

      if (_arquivoSelecionado != null) {
        arquivoUrl = await _anexoUploadService.upload(
          anexo: _arquivoSelecionado!,
          fiscalId: fiscalId,
          modulo: 'ocorrencias',
          entidadeId: ocorrenciaId,
        );
        arquivoNome = _arquivoSelecionado!.nomeArquivo;
      }

      if (_isEdicao) {
        final atual = widget.ocorrencia!;
        ocorrenciaProvider.atualizar(
          Ocorrencia(
            id: atual.id,
            tipo: tipo,
            caixaId: _caixaId,
            caixaNome: _caixaNome,
            colaboradorId: _colaboradorId,
            colaboradorNome: _colaboradorNome,
            descricao: descricao,
            fotoUrl: fotoUrl,
            fotoNome: fotoNome,
            arquivoUrl: arquivoUrl,
            arquivoNome: arquivoNome,
            gravidade: _gravidade,
            resolvida: atual.resolvida,
            registradaEm: atual.registradaEm,
            resolvidaEm: atual.resolvidaEm,
          ),
        );
      } else {
        ocorrenciaProvider.registrar(
          id: ocorrenciaId,
          tipo: tipo,
          caixaId: _caixaId,
          caixaNome: _caixaNome,
          colaboradorId: _colaboradorId,
          colaboradorNome: _colaboradorNome,
          descricao: descricao,
          gravidade: _gravidade,
          fotoUrl: fotoUrl,
          fotoNome: fotoNome,
          arquivoUrl: arquivoUrl,
          arquivoNome: arquivoNome,
        );

        if (eventoProvider.turnoAtivo) {
          eventoProvider.registrar(
            fiscalId: fiscalId,
            tipo: TipoEvento.ocorrenciaRegistrada,
            detalhe: '$tipo - ${_gravidade.nome}',
          );
        }
      }

      if (!mounted) return;
      AppNotif.show(
        context,
        titulo: _isEdicao ? 'Ocorrencia atualizada' : 'Ocorrencia registrada',
        mensagem:
            _isEdicao ? 'Ocorrencia atualizada!' : 'Ocorrencia registrada!',
        tipo: 'saida',
        cor: AppColors.success,
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppNotif.show(
        context,
        titulo: _isEdicao ? 'Erro ao atualizar' : 'Erro ao registrar',
        mensagem: 'Nao foi possivel salvar com anexos: $e',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoAtual = _tipoCtrl.text.trim();
    final hasContexto = (_caixaNome != null && _caixaNome!.isNotEmpty) ||
        (_colaboradorNome != null && _colaboradorNome!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEdicao ? 'Editar Ocorrencia' : 'Registrar Ocorrencia',
          style: AppTextStyles.h3,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasContexto) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSection,
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_caixaNome != null && _caixaNome!.isNotEmpty)
                      Text('Caixa: ${_caixaNome!}', style: AppTextStyles.body),
                    if (_colaboradorNome != null &&
                        _colaboradorNome!.isNotEmpty)
                      Text(
                        'Colaborador: ${_colaboradorNome!}',
                        style: AppTextStyles.body,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spacingMD),
            ],
            const Text('Tipo de ocorrencia', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            TextField(
              controller: _tipoCtrl,
              decoration: InputDecoration(
                hintText: 'Ex: Briga, Erro de Caixa, Furto...',
                prefixIcon:
                    Icon(iconForTipo(tipoAtual), color: AppColors.danger),
                suffixIcon: tipoAtual.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _tipoCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Dimensions.spacingSM),
            Text(
              'Sugestoes:',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kTiposSugestao.map((s) {
                final sel = tipoAtual == s;
                return GestureDetector(
                  onTap: () {
                    _tipoCtrl.text = s;
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: sel ? AppColors.danger : AppColors.inactive,
                        width: sel ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        color: sel ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Dimensions.spacingLG),
            const Text('Gravidade', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Row(
              children: GravidadeOcorrencia.values.map((g) {
                final sel = _gravidade == g;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _gravidade = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel
                              ? g.cor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          border: Border.all(
                            color: sel ? g.cor : AppColors.inactive,
                            width: sel ? 2 : 1,
                          ),
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusMD),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              sel
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: sel ? g.cor : AppColors.inactive,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              g.nome,
                              style: TextStyle(
                                color: sel ? g.cor : AppColors.textSecondary,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 13,
                              ),
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
            const Text('O que aconteceu? *', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(
                hintText: 'Descreva com detalhes: quem, o que, onde...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.spacingMD),
            const Text('Anexos (opcional)', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Foto'),
                    subtitle: Text(
                      _fotoSelecionada?.nomeArquivo ??
                          _fotoNomeAtual ??
                          (_fotoUrlAtual != null
                              ? 'Foto anexada'
                              : 'Nenhuma foto selecionada'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_fotoSelecionada != null || _fotoUrlAtual != null)
                          IconButton(
                            onPressed: _salvando ? null : _removerFoto,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        IconButton(
                          onPressed: _salvando ? null : _selecionarFoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: const Text('Arquivo'),
                    subtitle: Text(
                      _arquivoSelecionado?.nomeArquivo ??
                          _arquivoNomeAtual ??
                          (_arquivoUrlAtual != null
                              ? 'Arquivo anexado'
                              : 'Nenhum arquivo selecionado'),
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
                            icon: const Icon(Icons.delete_outline),
                          ),
                        IconButton(
                          onPressed: _salvando ? null : _selecionarArquivo,
                          icon: const Icon(Icons.upload_file_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.spacingXL),
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
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_isEdicao ? Icons.check : Icons.save),
                    label: Text(
                      _salvando
                          ? 'Salvando...'
                          : (_isEdicao ? 'Salvar' : 'Registrar'),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(Dimensions.buttonHeight),
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
