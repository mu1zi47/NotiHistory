package com.example.noti_history

import android.app.Activity
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
                    )
                }
                "clear" -> async(HistoryRuntime.worker, result) {
                    HistoryRuntime.store(activity).clear(
                        call.argument<String>("search").orEmpty(),
                        call.argument<List<String>>("packageNames").orEmpty(),
                        call.argument<Number>("since")?.toLong() ?: 0L,
                    ); HistoryRuntime.notifyChanged(); null
                }
                "delete" -> async(HistoryRuntime.worker, result) {
                    val id = call.argument<Number>("id")?.toLong()
                        ?: throw IllegalArgumentException("Missing notification id")
                    HistoryRuntime.store(activity).delete(id); HistoryRuntime.notifyChanged(); null
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
