package uz.mu1zi47.notihistory

import android.app.Activity
import android.content.Intent
import android.content.ActivityNotFoundException
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

/** Flutter transport only. Storage and notification capture are independent. */
class HistoryPlatformBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, "notihistory/history")
    private val events = EventChannel(messenger, "notihistory/changes")
    private val access = NotificationAccess(activity)
    private val icons = AppIconLoader(activity.applicationContext)
    private var listener: (() -> Unit)? = null

    init {
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                listener = { sink.success(null) }
                HistoryRuntime.onChange = listener
            }
            override fun onCancel(arguments: Any?) { detachListener() }
        })
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "openFeedback" -> {
                    val destination = call.argument<String>("destination")
                    val intent = when (destination) {
                        "email" -> Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:valiyevmuiz0407@gmail.com"))
                        "telegram" -> Intent(Intent.ACTION_VIEW, Uri.parse("https://mu1zi47.vercel.app/#contacts"))
                        else -> null
                    }
                    if (intent == null) {
                        result.error("invalid", "Unknown feedback destination", null)
                    } else try {
                        activity.startActivity(intent)
                        result.success(null)
                    } catch (_: ActivityNotFoundException) {
                        result.error("unavailable", "No app available", null)
                    }
                }
                "appVersion" -> {
                    @Suppress("DEPRECATION")
                    val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
                    result.success(info.versionName)
                }
                "appPreferences" -> {
                    val preferences = activity.getSharedPreferences("app_preferences", 0)
                    result.success(mapOf("language" to preferences.getString("language", null), "theme" to preferences.getString("theme", "system")))
                }
                "setAppPreferences" -> async(HistoryRuntime.worker, result) {
                    val language = call.argument<String>("language") ?: error("Missing language")
                    val theme = call.argument<String>("theme") ?: error("Missing theme")
                    require(language in listOf("ru", "en") && theme in listOf("system", "light", "dark"))
                    check(activity.getSharedPreferences("app_preferences", 0).edit().putString("language", language).putString("theme", theme).commit())
                    activity.runOnUiThread { AppNightMode.apply(activity, theme) }
                    null
                }
                "captureApps" -> async(HistoryRuntime.worker, result) {
                    CaptureSettings(activity.applicationContext).apps(HistoryRuntime.store(activity))
                }
                "enableAllCaptureApps" -> async(HistoryRuntime.worker, result) {
                    CaptureSettings(activity.applicationContext).enableAll()
                    null
                }
                "setCaptureEnabled" -> async(HistoryRuntime.worker, result) {
                    val packageName = call.argument<String>("packageName") ?: error("Missing package")
                    val enabled = call.argument<Boolean>("enabled") ?: error("Missing enabled")
                    CaptureSettings(activity.applicationContext).setEnabled(packageName, enabled)
                    null
                }
                "imageFullscreen" -> {
                    val hidden = call.argument<Boolean>("hidden") == true
                    if (android.os.Build.VERSION.SDK_INT >= 30) {
                        val controller = activity.window.insetsController
                        if (hidden) {
                            controller?.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                            controller?.hide(android.view.WindowInsets.Type.systemBars())
                        } else controller?.show(android.view.WindowInsets.Type.systemBars())
                    }
                    result.success(null)
                }
                "status" -> result.success(mapOf("supported" to true, "granted" to access.granted(), "connected" to HistoryRuntime.connected, "error" to HistoryRuntime.error))
                "openAccess" -> {
                    try { access.open(); result.success(null) }
                    catch (_: Exception) { result.error("settings", "Не удалось открыть настройки доступа.", null) }
                }
                "canOpenNotification" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    result.success((id != null && HistoryRuntime.actions.get(id) != null) ||
                        launchIntent(call.argument<String>("packageName").orEmpty()) != null)
                }
                "openNotification" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    val action = id?.let { HistoryRuntime.actions.get(it) }
                    var opened = false
                    if (action != null) {
                        try {
                            val options = android.app.ActivityOptions.makeBasic()
                            if (android.os.Build.VERSION.SDK_INT >= 34) {
                                options.setPendingIntentBackgroundActivityStartMode(
                                    android.app.ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                                )
                            }
                            action.send(activity, 0, null, null, null, null, options.toBundle())
                            opened = true
                        } catch (_: Exception) { HistoryRuntime.actions.remove(id) }
                    }
                    if (!opened) {
                        try {
                            val intent = launchIntent(call.argument<String>("packageName").orEmpty())
                            if (intent != null) { activity.startActivity(intent); opened = true }
                        } catch (_: Exception) { /* Report only after both destinations failed. */ }
                    }
                    if (opened) result.success(null)
                    else result.error("unavailable", "Уведомление и приложение недоступны.", null)
                }
                "reconnect" -> { access.reconnect(); result.success(null) }
                "query" -> async(HistoryRuntime.reader, result) {
                    HistoryRuntime.store(activity).query(
                        call.argument<String>("search").orEmpty(),
                        call.argument<List<String>>("packageNames").orEmpty(),
                        call.argument<Number>("since")?.toLong() ?: 0L,
                        call.argument<Number>("beforeId")?.toLong(),
                        call.argument<Boolean>("includeOverview") ?: true,
                        call.argument<Boolean>("archived") ?: false,
                    )
                }
                "clear" -> async(HistoryRuntime.worker, result) {
                    HistoryRuntime.store(activity).clear(
                        call.argument<String>("search").orEmpty(),
                        call.argument<List<String>>("packageNames").orEmpty(),
                        call.argument<Number>("since")?.toLong() ?: 0L,
                        call.argument<Boolean>("archived") ?: false,
                    ); HistoryRuntime.notifyChanged(); null
                }
                "setArchived" -> async(HistoryRuntime.worker, result) {
                    val id = call.argument<Number>("id")?.toLong() ?: error("Missing id")
                    val archived = call.argument<Boolean>("archived") ?: error("Missing archive state")
                    HistoryRuntime.store(activity).setArchived(id, archived)
                    HistoryRuntime.notifyChanged(); null
                }
                "delete" -> async(HistoryRuntime.worker, result) {
                    val id = call.argument<Number>("id")?.toLong()
                        ?: throw IllegalArgumentException("Missing notification id")
                    HistoryRuntime.store(activity).delete(id); HistoryRuntime.notifyChanged(); null
                }
                "notification" -> async(HistoryRuntime.reader, result) {
                    val id = call.argument<Number>("id")?.toLong() ?: error("Missing id")
                    HistoryRuntime.store(activity).notification(id)
                }
                "image" -> async(HistoryRuntime.reader, result) {
                    val id = call.argument<Number>("id")?.toLong() ?: throw IllegalArgumentException("Missing id")
                    HistoryRuntime.store(activity).image(id)
                }
                "icon" -> async(HistoryRuntime.icons, result) { icons.load(call.argument<String>("packageName").orEmpty()) }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchIntent(packageName: String): android.content.Intent? = try {
        packageName.takeIf { it.isNotBlank() }?.let { activity.packageManager.getLaunchIntentForPackage(it) }
    } catch (_: Exception) { null }

    private fun async(executor: Executor, result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try { val value = block(); activity.runOnUiThread { result.success(value) } }
            catch (_: Exception) { activity.runOnUiThread { result.error("storage", "Не удалось прочитать или изменить историю.", null) } }
        }
    }

    private fun detachListener() {
        if (HistoryRuntime.onChange === listener) HistoryRuntime.onChange = null
        listener = null
    }

    fun close() { detachListener(); methods.setMethodCallHandler(null); events.setStreamHandler(null) }
}
