# Flutter: mantém classes de plugins que o R8 não deve renomear/remover

# notification_listener_service — classe declarada pelo nome no AndroidManifest.
# O Android instancia esse Service por reflexão; se o R8 renomear, o service
# não é encontrado e o app crasha ao abrir as configurações de notificação.
# Pacote real do plugin: notification.listener.service (NÃO com.pravera.*)
-keep class notification.listener.service.** { *; }
-dontwarn notification.listener.service.**

# Supabase / OkHttp (segurança para chamadas HTTP dentro do plugin)
-dontwarn okhttp3.**
-dontwarn okio.**
