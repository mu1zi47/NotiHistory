package uz.mu1zi47.notihistory

import android.app.Notification
import android.os.Build
import android.os.Bundle

data class NotificationMessage(val sender: String, val text: String, val time: Long) {
    fun formatted() = if (sender.isBlank()) text else "$sender: $text"

    // Android/Telegram's short push preview ends near 1024 characters with an ellipsis.
    // Match the timestamp and sender separately; ordinary short messages are never expanded.
    fun isExpandedBy(other: NotificationMessage): Boolean {
        if (time <= 0 || sender != other.sender || time != other.time || text.length !in 900..1024) return false
        val prefix = when {
            text.endsWith("…") -> text.dropLast(1)
            text.endsWith("...") -> text.dropLast(3)
            else -> return false
        }.trimEnd()
        return other.text.length > text.length && other.text.startsWith(prefix)
    }
}

/** repairedFrom identifies the exact text produced by the former Android decoder. */
data class NotificationContent(val title: String, val body: String, val subText: String, val repairedFrom: String? = null, val messages: List<NotificationMessage> = emptyList()) {
    companion object {
        fun from(notification: Notification): NotificationContent {
            val extras = notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString().orEmpty()
            val messages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                @Suppress("DEPRECATION") val bundles = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
                bundles.orEmpty().mapNotNull { parcel ->
                    val bundle = parcel as? Bundle ?: return@mapNotNull null
                    try {
                        if (!bundle.containsKey("text") || !bundle.containsKey("time")) return@mapNotNull null
                        // Message.getMessagesFromBundleArray reconstructs Message objects,
                        // whose constructor truncates text. Read the original bundle instead.
                        val text = bundle.getCharSequence("text")?.toString().orEmpty()
                        if (text.isBlank()) return@mapNotNull null
                        @Suppress("DEPRECATION") val person = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            bundle.getParcelable("sender_person") as? android.app.Person
                        } else null
                        val sender = person?.name?.toString()
                            ?: bundle.getCharSequence("sender")?.toString().orEmpty()
                        NotificationMessage(sender, text, bundle.getLong("time"))
                    } catch (_: RuntimeException) { null }
                }
            } else emptyList()
            val fullMessages = messages.joinToString("\n") { it.formatted() }
            val body = fullMessages.takeIf { it.isNotBlank() }
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.takeIf { it.isNotBlank() }
                ?: extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.joinToString("\n")?.takeIf { it.isNotBlank() }
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
            // Only use the former decoder to recognize and repair its exact old output.
            // Its result is never used as the saved text.
            val oldMessages = if (fullMessages.length > 1024 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                @Suppress("DEPRECATION") val bundles = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
                Notification.MessagingStyle.Message.getMessagesFromBundleArray(bundles).joinToString("\n") {
                    @Suppress("DEPRECATION") val sender = it.sender?.toString().orEmpty()
                    val text = it.text?.toString().orEmpty()
                    if (sender.isBlank()) text else "$sender: $text"
                }
            } else fullMessages
            return NotificationContent(title, body, subText, oldMessages.takeIf { fullMessages.isNotBlank() && it != fullMessages }, messages)
        }
    }
}
