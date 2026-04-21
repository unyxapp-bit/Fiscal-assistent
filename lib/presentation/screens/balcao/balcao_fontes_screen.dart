import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_notif.dart';
import '../../../data/services/whatsapp_notification_service.dart';

/// Tela para configurar quais grupos/contatos do WhatsApp são monitorados.
/// As fontes são salvas em SharedPreferences e carregadas automaticamente
/// no próximo init() do WhatsAppNotificationService.
class BalcaoFontesScreen extends StatefulWidget {
  const BalcaoFontesScreen({super.key});

  @override
  State<BalcaoFontesScreen> createState() => _BalcaoFontesScreenState();
}

class _BalcaoFontesScreenState extends State<BalcaoFontesScreen> {
  late List<String> _fontes;
  final _ctrl = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _fontes = List.of(WhatsAppNotificationService.fontesAceitas);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _adicionar() {
    final v = _ctrl.text.trim().toLowerCase();
    if (v.isEmpty) return;
    if (_fontes.contains(v)) {
      AppNotif.show(context,
          titulo: 'Já existe',
          mensagem: '"$v" já está na lista.',
          tipo: 'alerta',
          cor: AppColors.warning);
      return;
    }
    setState(() => _fontes.add(v));
    _ctrl.clear();
  }

  void _remover(String fonte) {
    setState(() => _fontes.remove(fonte));
  }

  Future<void> _salvar() async {
    if (_fontes.isEmpty) {
      AppNotif.show(context,
          titulo: 'Lista vazia',
          mensagem: 'Adicione pelo menos uma fonte.',
          tipo: 'alerta',
          cor: AppColors.danger);
      return;
    }
    setState(() => _salvando = true);
    await WhatsAppNotificationService.salvarFontes(_fontes);
    await WhatsAppNotificationService.reset();
    if (!mounted) return;
    setState(() => _salvando = false);
    AppNotif.show(context,
        titulo: 'Fontes salvas',
        mensagem: 'O listener foi reiniciado com as novas fontes.',
        tipo: 'saida',
        cor: AppColors.success);
    Navigator.pop(context);
  }

  Future<void> _resetar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar padrão?'),
        content: const Text(
            'As fontes voltarão para o padrão ("balcão fiscal", "pyetro filho").'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Restaurar',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmar != true) return;
    await WhatsAppNotificationService.resetarFontes();
    await WhatsAppNotificationService.reset();
    if (!mounted) return;
    setState(() {
      _fontes = List.of(WhatsAppNotificationService.fontesAceitas);
    });
    AppNotif.show(context,
        titulo: 'Padrão restaurado',
        mensagem: 'Listener reiniciado com as fontes padrão.',
        tipo: 'saida',
        cor: AppColors.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Fontes monitoradas', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _resetar,
            child: Text('Restaurar padrão',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 0, Dimensions.paddingMD, Dimensions.spacingMD),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Digite o nome exato do grupo ou contato do WhatsApp '
                      'em letras minúsculas. O app captura mensagens somente '
                      'das fontes desta lista.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Campo para adicionar nova fonte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: AppTextStyles.body,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      hintText: 'Ex: balcão fiscal',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.backgroundSection,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSM, vertical: 12),
                    ),
                    onSubmitted: (_) => _adicionar(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _adicionar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSM)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.spacingMD),

          // Lista de fontes
          Expanded(
            child: _fontes.isEmpty
                ? Center(
                    child: Text('Nenhuma fonte adicionada.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingMD),
                    itemCount: _fontes.length,
                    itemBuilder: (_, i) {
                      final f = _fontes[i];
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.spacingSM),
                        child: ListTile(
                          leading: Icon(Icons.chat_bubble_outline_rounded,
                              color: AppColors.primary, size: 20),
                          title: Text(f, style: AppTextStyles.body),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => _remover(f),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Botão salvar
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: SizedBox(
              width: double.infinity,
              height: Dimensions.buttonHeight,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSM)),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Salvar e reiniciar listener',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
