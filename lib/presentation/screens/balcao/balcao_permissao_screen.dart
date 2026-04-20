import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/whatsapp_notification_service.dart';

/// Tela explicativa que guia o usuário para conceder a permissão
/// de leitura de notificações ao Fiscal Assistant.
class BalcaoPermissaoScreen extends StatefulWidget {
  const BalcaoPermissaoScreen({super.key});

  @override
  State<BalcaoPermissaoScreen> createState() => _BalcaoPermissaoScreenState();
}

class _BalcaoPermissaoScreenState extends State<BalcaoPermissaoScreen> {
  bool _verificando = false;

  Future<void> _abrirConfiguracoes() async {
    setState(() => _verificando = true);
    await WhatsAppNotificationService.requestPermission();
    // Aguarda retorno para o app (o usuário vai nas configurações e volta)
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _verificando = false);
      Navigator.pop(context); // Volta para a tela do Balcão
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Ativar Balcão Fiscal', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone ilustrativo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.campaign_outlined,
                      size: 44, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: Dimensions.spacingLG),

              Text('Como funciona', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingSM),
              Text(
                'O Fiscal Assistant lê as notificações do grupo '
                '"Balcão Fiscal" no WhatsApp e registra automaticamente '
                'os eventos (faltas, caixa, atestados etc.) sem precisar '
                'que você abra o WhatsApp.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary, height: 1.5),
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Passos
              _Passo(
                numero: '1',
                titulo: 'Toque em "Abrir configurações"',
                descricao:
                    'O Android vai abrir a tela de Acesso a Notificações.',
                color: AppColors.primary,
              ),
              const SizedBox(height: Dimensions.spacingMD),
              _Passo(
                numero: '2',
                titulo: 'Encontre "Fiscal Assistant"',
                descricao:
                    'Localize o app na lista e ative o acesso às notificações.',
                color: AppColors.primary,
              ),
              const SizedBox(height: Dimensions.spacingMD),
              _Passo(
                numero: '3',
                titulo: 'Volte para o app',
                descricao:
                    'Após ativar, volte aqui. O Balcão começa a capturar automaticamente.',
                color: AppColors.primary,
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Aviso de privacidade
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSection,
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusSM),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Somente mensagens do grupo "Balcão Fiscal" são '
                        'processadas. Nenhuma outra conversa é lida ou armazenada.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Botão principal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _verificando ? null : _abrirConfiguracoes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSM)),
                  ),
                  icon: _verificando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.settings_outlined, size: 18),
                  label: Text(
                    _verificando
                        ? 'Aguardando...'
                        : 'Abrir configurações do Android',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spacingSM),

              // Link secundário
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Fazer isso depois',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descricao;
  final Color color;

  const _Passo({
    required this.numero,
    required this.titulo,
    required this.descricao,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              numero,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(descricao,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
