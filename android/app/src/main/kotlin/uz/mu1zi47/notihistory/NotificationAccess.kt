package uz.mu1zi47.notihistory

import android.app.Activity
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService

class NotificationAccess(private val activity: Activity) {
    private val component = ComponentName(activity, NotificationCaptureService::class.java)
    fun granted(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            return activity.getSystemService(NotificationManager::class.java).isNotificationListenerAccessGranted(component)
        }
        return Settings.Secure.getString(activity.contentResolver, "enabled_notification_listeners")
            ?.split(':')?.any { ComponentName.unflattenFromString(it) == component } == true
    }
    fun open() { activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)) }
    fun reconnect() {
        if (granted() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try { NotificationListenerService.requestRebind(component) } catch (_: Exception) { }
        }
    }
}
