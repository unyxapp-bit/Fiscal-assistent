import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/colors.dart';

const _systemPrompt = '''
Você é o Assistente Fiscal, um assistente inteligente especializado em apoiar
fiscais de caixa e supervisores de loja no dia a dia operacional.

Seu foco:
- Gestão de escala de trabalho e turnos
- Procedimentos de abertura e fechamento de caixa
- Resolução de ocorrências e problemas no PDV
- Orientações sobre sangria, suprimento e conferência de valores
- Dúvidas sobre atendimento ao cliente
- Legislação trabalhista básica (intervalos, jornada)
- Boas práticas de supervisão de equipe

Seja direto, prático e use linguagem simples. Quando listar passos, use
listas numeradas. Responda sempre em português brasileiro.
''';

class AssistenteScreen extends StatefulWidget {
  const AssistenteScreen({super.key});

  @override
  State<AssistenteScreen> createState() => _AssistenteScreenState();
}

class _AssistenteScreenState extends State<AssistenteScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  late final GenerativeModel _model;
  late final ChatSession _chat;

  final List<Content> _history = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  void _initGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyCuVRU2IzD301Qq0Nm5HscuwPsixfgLCvw';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _chat = _model.startChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isGenerating) return;

    setState(() {
      _history.add(Content.text(text));
      _history.add(Content.model([TextPart('')]));
      _isGenerating = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final responseStream = _chat.sendMessageStream(Content.text(text));
      String accumulated = '';

      await for (final chunk in responseStream) {
        accumulated += chunk.text ?? '';
        setState(() {
          _history[_history.length - 1] =
              Content.model([TextPart(accumulated)]);
        });
        _scrollToBottom();
      }
    } catch (e) {
      final errorMsg = _parseGeminiError(e);
      debugPrint('[AssistenteIA] erro: $e');
      setState(() {
        _history[_history.length - 1] =
            Content.model([TextPart('⚠️ $errorMsg')]);
      });
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  String _parseGeminiError(Object e) {
    final msg = e.toString();
    if (msg.contains('API_KEY_INVALID') || msg.contains('API key not valid')) {
      return 'Chave de API inválida. Verifique o GEMINI_API_KEY no arquivo .env.';
    }
    if (msg.contains('PERMISSION_DENIED') || msg.contains('403')) {
      return 'Acesso negado (403). A chave não tem permissão para usar este modelo.';
    }
    if (msg.contains('RESOURCE_EXHAUSTED') || msg.contains('429')) {
      return 'Limite de requisições atingido (429). Aguarde um momento e tente novamente.';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'Modelo não encontrado (404). Verifique se "gemini-1.5-flash" está disponível.';
    }
    if (msg.contains('SocketException') || msg.contains('NetworkException')) {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Tempo de resposta esgotado. Tente novamente.';
    }
    // Erro desconhecido — mostra o texto real para diagnóstico
    return 'Erro: $msg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assistente Fiscal'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Limpar conversa',
              onPressed: () => setState(() => _history.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _history.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (_, i) => _buildBubble(_history[i]),
                  ),
          ),
          if (_isGenerating)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.backgroundSection,
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.alertInfo,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.support_agent,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Assistente Fiscal',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tire dúvidas sobre escala, procedimentos de caixa, ocorrências e muito mais.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            _buildSuggestion('Como fazer sangria de caixa?'),
            _buildSuggestion('Qual o intervalo obrigatório para 6h de trabalho?'),
            _buildSuggestion('O que fazer quando o caixa fechar com diferença?'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundSection,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.primary, fontSize: 13)),
      ),
    );
  }

  Widget _buildBubble(Content content) {
    final isUser = content.role == 'user';
    final text =
        content.parts.whereType<TextPart>().map((e) => e.text).join();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.backgroundSection,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.border, width: 0.5),
        ),
        child: text.isEmpty && !isUser
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4),
                  listBullet: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary),
                  strong: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold),
                  code: TextStyle(
                      backgroundColor:
                          isUser ? Colors.blue[800] : Colors.black12,
                      fontSize: 13),
                ),
              ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Escreva sua dúvida...',
                  hintStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundSection,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _isGenerating ? AppColors.inactive : AppColors.primary,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: _isGenerating ? null : _sendMessage,
                borderRadius: BorderRadius.circular(22),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
