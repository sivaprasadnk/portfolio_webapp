package dev.sivaprasadnk.yt_downloader_mobile

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "dev.sivaprasadnk.yt_downloader_mobile/share_intent"
    private var initialSharedText: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialSharedText = extractSharedText(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedText" -> {
                        val pending = initialSharedText
                        initialSharedText = null
                        result.success(pending)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val shared = extractSharedText(intent)
        if (!shared.isNullOrBlank()) {
            methodChannel?.invokeMethod("onSharedText", shared)
        }
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true) {
            return intent.getStringExtra(Intent.EXTRA_TEXT)
        }
        return null
    }
}
