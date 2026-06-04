package com.app.fiscal_assistant

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.app.fiscal_assistant/shared_content"
    private val pendingItems = mutableListOf<Map<String, Any?>>()
    private var sharedContentChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sharedContentChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        collectSharedItems(intent)
        sharedContentChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeSharedContent" -> {
                    val copy = pendingItems.toList()
                    pendingItems.clear()
                    result.success(copy)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val added = collectSharedItems(intent)
        if (added > 0) {
            sharedContentChannel?.invokeMethod("sharedContentAvailable", added)
        }
    }

    private fun collectSharedItems(intent: Intent?): Int {
        if (intent == null) return 0
        val before = pendingItems.size
        when (intent.action) {
            Intent.ACTION_SEND -> {
                val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (!text.isNullOrBlank()) {
                    pendingItems.add(
                        mapOf(
                            "text" to text,
                            "mimeType" to "text/plain",
                            "sourceApp" to intent.`package`
                        )
                    )
                }
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let {
                    pendingItems.add(safeReadUriItem(it, intent.type, intent.`package`))
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val streams = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                streams?.forEach {
                    pendingItems.add(safeReadUriItem(it, intent.type, intent.`package`))
                }
            }
        }
        return pendingItems.size - before
    }

    private fun safeReadUriItem(uri: Uri, fallbackMimeType: String?, sourceApp: String?): Map<String, Any?> {
        return try {
            readUriItem(uri, fallbackMimeType, sourceApp)
        } catch (e: Exception) {
            mapOf(
                "error" to "Nao foi possivel ler o arquivo compartilhado: ${e.message ?: "erro desconhecido"}",
                "sourceApp" to sourceApp
            )
        }
    }

    private fun readUriItem(uri: Uri, fallbackMimeType: String?, sourceApp: String?): Map<String, Any?> {
        val mimeType = contentResolver.getType(uri) ?: fallbackMimeType ?: "application/octet-stream"
        val fileName = displayName(uri) ?: uri.lastPathSegment ?: "arquivo"
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: ByteArray(0)
        return mapOf(
            "fileName" to fileName,
            "mimeType" to mimeType,
            "bytesBase64" to Base64.encodeToString(bytes, Base64.NO_WRAP),
            "sourceApp" to sourceApp
        )
    }

    private fun displayName(uri: Uri): String? {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) cursor.getString(index) else null
            } else {
                null
            }
        } finally {
            cursor?.close()
        }
    }
}
