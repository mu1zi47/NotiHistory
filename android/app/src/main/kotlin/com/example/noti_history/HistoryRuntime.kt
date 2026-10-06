package com.example.noti_history

import android.content.Context
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors

object HistoryRuntime {
    // PendingIntent tokens cannot be persisted across process/device restarts.
    val actions = android.util.LruCache<Long, android.app.PendingIntent>(1000)
    val worker = Executors.newSingleThreadExecutor()
    // Reads and icon rendering must not queue in front of notification writes.
    val reader = Executors.newSingleThreadExecutor()
    val icons = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    @Volatile var connected = false
    @Volatile var error: String? = null
    var onChange: (() -> Unit)? = null
    private var database: HistoryStore? = null

    @Synchronized fun store(context: Context): HistoryStore = database ?: HistoryStore(context.applicationContext).also { database = it }
    fun notifyChanged() { main.post { onChange?.invoke() } }
}
