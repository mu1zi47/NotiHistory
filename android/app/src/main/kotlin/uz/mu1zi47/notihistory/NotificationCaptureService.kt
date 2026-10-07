package uz.mu1zi47.notihistory

import android.content.ComponentName
import android.os.Build
import android.os.SystemClock
import android.util.LruCache
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationCaptureService : NotificationListenerService() {
    private data class Label(val text: String, val expiresAt: Long)
    private val labels = LruCache<String, Label>(80)

    private fun appName(packageName: String): String {
        val now = SystemClock.elapsedRealtime()
        labels.get(packageName)?.takeIf { it.expiresAt > now }?.let { return it.text }
        val name = try { packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString() }
            catch (_: Exception) { packageName }
        labels.put(packageName, Label(name, now + 300_000))
        return name
    }
    override fun onListenerConnected() {
        HistoryRuntime.connected = true
        HistoryRuntime.error = null
        HistoryRuntime.notifyChanged()
        // Recover notifications still visible when Android reconnects the listener.
        val active = try { activeNotifications?.toList().orEmpty() } catch (_: SecurityException) { emptyList() }
        HistoryRuntime.worker.execute {
            try {
                HistoryRuntime.store(this).reconcile(active.map { it.key }.toSet())
            } catch (_: Exception) { reportFailure() }
        }
        active.sortedBy { it.postTime }.forEach { capture(it) }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) { capture(sbn) }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        HistoryRuntime.worker.execute {
            try { HistoryRuntime.store(this).forget(sbn.key) } catch (_: Exception) { reportFailure() }
        }
    }

    override fun onListenerDisconnected() {
        HistoryRuntime.connected = false
        HistoryRuntime.notifyChanged()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try { requestRebind(ComponentName(this, NotificationCaptureService::class.java)) } catch (_: Exception) { /* Android owns reconnection. */ }
        }
    }

    override fun onDestroy() {
        HistoryRuntime.connected = false
        HistoryRuntime.notifyChanged()
        super.onDestroy()
    }

    private fun reportFailure() {
        HistoryRuntime.error = "Не удалось сохранить уведомление. Проверьте свободное место на телефоне."
        HistoryRuntime.notifyChanged()
    }

    private fun capture(sbn: StatusBarNotification) {
        HistoryRuntime.worker.execute {
            try {
                val content = NotificationContent.from(sbn.notification)
                val store = HistoryRuntime.store(this)
                val extras = sbn.notification.extras
                val coalesce = NotificationImage.isMedia(sbn.notification) || sbn.isOngoing || extras.getInt(android.app.Notification.EXTRA_PROGRESS_MAX, 0) > 0 ||
                    extras.getBoolean(android.app.Notification.EXTRA_PROGRESS_INDETERMINATE, false)
                val changed = store.save(sbn.key, sbn.packageName, appName(sbn.packageName), content.title, content.body, content.subText, sbn.postTime, coalesce, NotificationImage.extract(this, sbn.notification))
                store.lastId(sbn.key)?.let { id ->
                    val action = sbn.notification.contentIntent
                    if (action != null) HistoryRuntime.actions.put(id, action)
                    else HistoryRuntime.actions.remove(id)
                }
                if (changed) {
                    HistoryRuntime.error = null
                    HistoryRuntime.notifyChanged()
                }
            } catch (_: Exception) { reportFailure() }
        }
    }
}
