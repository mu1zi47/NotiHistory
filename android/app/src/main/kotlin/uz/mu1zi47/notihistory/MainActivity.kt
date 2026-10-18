package uz.mu1zi47.notihistory

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        AppNightMode.apply(this, getSharedPreferences("app_preferences", 0).getString("theme", "system")!!)
        super.onCreate(savedInstanceState)
    }
    private var bridge: HistoryPlatformBridge? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = HistoryPlatformBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        bridge?.close()
        bridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
