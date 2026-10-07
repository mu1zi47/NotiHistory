package uz.mu1zi47.notihistory

import android.app.Notification
import android.os.Build

data class NotificationContent(val title: String, val body: String, val subText: String) {
    companion object {
        fun from(notification: Notification): NotificationContent {
            val extras = notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString().orEmpty()
            val messages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                @Suppress("DEPRECATION") val bundles = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
                Notification.MessagingStyle.Message.getMessagesFromBundleArray(bundles).joinToString("\n") {
                    @Suppress("DEPRECATION") val sender = it.sender?.toString().orEmpty()
                    val text = it.text?.toString().orEmpty()
                    if (sender.isBlank()) text else "$sender: $text"
                }
            } else ""
            // Parse large alternative payloads only if the preferred one is absent.
            val body = messages.takeIf { it.isNotBlank() }
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.takeIf { it.isNotBlank() }
                ?: extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.joinToString("\n")?.takeIf { it.isNotBlank() }
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
            return NotificationContent(title, body, subText)
        }
    }
}
