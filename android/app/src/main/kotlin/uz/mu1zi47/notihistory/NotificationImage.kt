package uz.mu1zi47.notihistory

import android.app.Notification
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Icon
import android.os.Build
import java.io.ByteArrayOutputStream
import kotlin.math.max

/** Store a bounded preview, without depending on the source app's URI lifetime. */
object NotificationImage {
    fun isMedia(notification: Notification): Boolean =
        notification.category == Notification.CATEGORY_TRANSPORT ||
        notification.extras.containsKey(Notification.EXTRA_MEDIA_SESSION) ||
        notification.extras.getString(Notification.EXTRA_TEMPLATE).orEmpty().contains("MediaStyle")

    @Suppress("DEPRECATION")
    fun extract(context: Context, notification: Notification): ByteArray? {
        return try {
        if (isMedia(notification)) return null
        val extras = notification.extras
        val picture = extras.getParcelable<android.os.Parcelable>(Notification.EXTRA_PICTURE)
        val icon = if (Build.VERSION.SDK_INT >= 31)
            extras.getParcelable<Icon>(Notification.EXTRA_PICTURE_ICON) else null
        val bitmap = picture as? Bitmap
        val drawable = if (bitmap == null) icon?.loadDrawable(context) else null
        val source = bitmap ?: (drawable as? BitmapDrawable)?.bitmap
        val width = source?.width ?: drawable?.intrinsicWidth ?: 0
        val height = source?.height ?: drawable?.intrinsicHeight ?: 0
        if (width <= 0 || height <= 0) null else {
            val scale = minOf(1.0, 4096.0 / max(width, height))
            val preview = Bitmap.createBitmap(max(1, (width * scale).toInt()), max(1, (height * scale).toInt()), Bitmap.Config.ARGB_8888)
            val canvas = Canvas(preview)
            canvas.drawColor(android.graphics.Color.WHITE)
            if (source != null) canvas.drawBitmap(source, null, android.graphics.Rect(0, 0, preview.width, preview.height), android.graphics.Paint(android.graphics.Paint.FILTER_BITMAP_FLAG))
            else { drawable!!.setBounds(0, 0, preview.width, preview.height); drawable.draw(canvas) }
            val bytes = ByteArrayOutputStream().use { stream -> preview.compress(Bitmap.CompressFormat.PNG, 100, stream); stream.toByteArray() }
            preview.recycle()
            bytes.takeIf { it.size <= 24 * 1024 * 1024 }
        }
    } catch (_: Exception) { null }
    }
}
