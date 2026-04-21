# Flutter: mantém classes de plugins que o R8 não deve renomear/remover

# notification_listener_service — declarado no AndroidManifest pelo nome completo.
# O Android instancia esse Service por reflexão; se o R8 renomear, o service
# não é encontrado e as notificações nunca chegam ao app.
-keep class com.pravera.notification_listener_service.** { *; }
-dontwarn com.pravera.notification_listener_service.**

# Supabase / OkHttp (segurança para chamadas HTTP dentro do plugin)
-dontwarn okhttp3.**
-dontwarn okio.**
