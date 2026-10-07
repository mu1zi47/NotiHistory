package uz.mu1zi47.notihistory

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.LruCache
import java.io.ByteArrayOutputStream

class AppIconLoader(private val context: Context) {
    private val cache = object : LruCache<String, ByteArray>(2 * 1024 * 1024) {
        override fun sizeOf(key: String, value: ByteArray) = value.size
    }

    fun load(packageName: String): ByteArray? {
        cache.get(packageName)?.let { return it }
        return try {
            val drawable = context.packageManager.getApplicationIcon(packageName)
            val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
            try {
                drawable.setBounds(0, 0, 96, 96)
                drawable.draw(Canvas(bitmap))
                ByteArrayOutputStream().use {
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                    it.toByteArray().also { bytes -> cache.put(packageName, bytes) }
                }
            } finally { bitmap.recycle() }
        } catch (_: Exception) { null }
    }
}
