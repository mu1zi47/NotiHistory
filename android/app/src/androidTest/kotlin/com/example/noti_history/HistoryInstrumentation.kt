package com.example.noti_history

import android.app.Activity
import android.app.Instrumentation
import android.app.Notification
import android.database.sqlite.SQLiteDatabase
import android.os.Bundle

/** Platform-only integration tests: run on an emulator, no third-party test runtime. */
class HistoryInstrumentation : Instrumentation() {
    override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); start() }
    override fun onStart() {
        val databaseName = "history-instrumentation.db"
        val results = Bundle()
        try {
            targetContext.deleteDatabase(databaseName)
            HistoryStore(targetContext, databaseName).use { store ->
                fun save(key: String = "key", body: String = "Привет Мир") = store.save(key, "test.app", "Телеграм", "Заголовок", body, "", 1000)
                check(save())
                check(!save()) { "Duplicate notification was written twice" }
                check(save(body = "Обновлённое сообщение"))
                check(store.query("ПРИВЕТ", emptyList(), 0, null)["matched"] == 1) { "Cyrillic case-insensitive search failed" }
                check(store.query("ТЕЛЕГРАМ", emptyList(), 0, null)["matched"] == 2)
                check(store.query("", listOf("other.app"), 0, null)["matched"] == 0)
                check(store.query("%", emptyList(), 0, null)["matched"] == 0) { "Search must treat wildcards literally" }
                store.clear()
                check(!save(body = "Обновлённое сообщение")) { "Cleared active notification came back" }
                store.forget("key")
                check(save(body = "Обновлённое сообщение"))
                store.clear()
                check(store.save("download", "test.app", "Download", "File", "1%", "", 1000, true))
                val downloadId = store.lastId("download")
                repeat(100) { percent ->
                    store.save("download", "test.app", "Download", "File", "$percent%", "", 1000, true)
                }
                check(store.save("download", "test.app", "Download", "File", "Completed", "", 1000))
                check(store.lastId("download") == downloadId)
                check(store.query("", emptyList(), 0, null)["matched"] == 1)
                check(store.query("Completed", emptyList(), 0, null)["matched"] == 1)
                store.forget("download")
                check(store.save("download", "test.app", "Download", "Other file", "1%", "", 1001, true))
                check(store.query("", emptyList(), 0, null)["matched"] == 2)
                store.clear()
                store.save("selected-old", "telegram", "Telegram", "Title", "match", "", 1000)
                store.save("selected-new", "telegram", "Telegram", "Title", "match", "", 1000)
                store.save("selected-other-text", "telegram", "Telegram", "Title", "other", "", 1000)
                store.save("other-app", "mail", "Mail", "Title", "match", "", 1000)
                val oldId = store.lastId("selected-old")!!
                store.writableDatabase.execSQL("UPDATE history SET saved_at = 1 WHERE id = ?", arrayOf(oldId))
                store.clear("match", listOf("telegram"), 2)
                check(store.query("", emptyList(), 0, null)["matched"] == 3)
                check(store.query("match", listOf("telegram"), 2, null)["matched"] == 0)
                check(store.query("", listOf("mail"), 0, null)["matched"] == 1)
                store.clear("", listOf("telegram"), 0)
                check(store.query("", emptyList(), 0, null)["matched"] == 1)
                store.clear()
                repeat(75) { check(save(key = "page-$it", body = "message $it")) }
                val first = store.query("", emptyList(), 0, null)
                @Suppress("UNCHECKED_CAST") val rows = first["items"] as List<Map<String, Any>>
                check(rows.size == 60 && first["hasMore"] == true)
                val second = store.query("", emptyList(), 0, (rows.last()["id"] as Number).toLong(), false)
                @Suppress("UNCHECKED_CAST") val more = second["items"] as List<Map<String, Any>>
                check(more.size == 15 && second["hasMore"] == false)
                check(!second.containsKey("apps") && !second.containsKey("stats"))
                check((rows + more).map { it["id"] }.toSet().size == 75)
                check(store.query("", emptyList(), System.currentTimeMillis() + 100_000, null)["matched"] == 0)
                check(store.readableDatabase.isWriteAheadLoggingEnabled)
                results.putString("storage", "PASS: dedup, Cyrillic, literal search, clear, cursor pages, time filter, WAL")
            }
            HistoryStore(targetContext, databaseName).use { reopened ->
                check(reopened.query("", emptyList(), 0, null)["matched"] == 75)
            }
            targetContext.deleteDatabase(databaseName)
            // Build a v1 database, then verify v2 migration preserves real history.
            SQLiteDatabase.openOrCreateDatabase(targetContext.getDatabasePath(databaseName), null).use { db ->
                db.execSQL("CREATE TABLE history (id INTEGER PRIMARY KEY AUTOINCREMENT, package_name TEXT NOT NULL, app_name TEXT NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL, sub_text TEXT NOT NULL, posted_at INTEGER NOT NULL, saved_at INTEGER NOT NULL, search_text TEXT NOT NULL)")
                db.execSQL("CREATE TABLE last_seen (notification_key TEXT PRIMARY KEY, digest TEXT NOT NULL)")
                db.execSQL("INSERT INTO history VALUES (1, 'old', 'Old app', 'Title', 'body', '', 1, 1, 'body')")
                db.version = 1
            }
            HistoryStore(targetContext, databaseName).use { upgraded ->
                check(upgraded.query("body", emptyList(), 0, null)["matched"] == 1)
                val indexes = upgraded.readableDatabase.rawQuery("SELECT name FROM sqlite_master WHERE type = 'index'", null).use { c -> buildList { while (c.moveToNext()) add(c.getString(0)) } }
                check("history_saved_at" in indexes && "history_package_date" in indexes)
            }
            results.putString("migration", "PASS: v1 history retained, v2 indexes present, persistence after reopen")
            val notification = Notification.Builder(targetContext, "test").setContentTitle("Title").setContentText("plain text").build()
            check(NotificationContent.from(notification).body == "plain text")
            val big = Notification.Builder(targetContext, "test").setContentTitle("Title").setContentText("short").setStyle(Notification.BigTextStyle().bigText("full text")).build()
            check(NotificationContent.from(big).body == "full text")
            val bitmap = android.graphics.Bitmap.createBitmap(100, 200, android.graphics.Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(android.graphics.Color.BLUE)
            val picture = Notification.Builder(targetContext, "test").setContentTitle("Screenshot")
                .setStyle(Notification.BigPictureStyle().bigPicture(bitmap)).build()
            val bytes = NotificationImage.extract(targetContext, picture) ?: error("Missing picture")
            check(android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size).height == 200)
            val iconPicture = Notification.Builder(targetContext, "test").setLargeIcon(bitmap).build()
            check(NotificationImage.extract(targetContext, iconPicture) == null)
            check(NotificationImage.extract(targetContext, notification) == null)
            HistoryStore(targetContext, databaseName).use { store ->
                store.clear()
                check(store.save("picture", "test", "Test", "Screenshot", "", "", 1, image = bytes))
                val id = store.lastId("picture")!!
                check(store.image(id)!!.contentEquals(bytes))
                check(!store.save("picture", "test", "Test", "Screenshot", "", "", 1, image = bytes))
                @Suppress("UNCHECKED_CAST") val rows = store.query("", emptyList(), 0, null)["items"] as List<Map<String, Any>>
                check(rows.single()["hasImage"] == true)
                check(store.save("picture", "test", "Test", "Screenshot", "", "", 1))
                check(store.lastId("picture") == id && store.image(id) == null)
                check(store.save("picture", "test", "Test", "Screenshot", "", "", 1, image = bytes))
                check(store.lastId("picture") == id)
            }
            HistoryStore(targetContext, databaseName).use { store ->
                val id = store.lastId("picture")!!
                check(store.image(id)!!.contentEquals(bytes))
                store.clear()
                check(store.image(id) == null)
            }
            val largeBitmap = android.graphics.Bitmap.createBitmap(1440, 3200, android.graphics.Bitmap.Config.ARGB_8888)
            largeBitmap.eraseColor(android.graphics.Color.GREEN)
            val largePicture = Notification.Builder(targetContext, "test").setStyle(Notification.BigPictureStyle().bigPicture(largeBitmap)).build()
            // Android's Builder reduces BigPicture payloads itself. Supply the
            // original bitmap directly to test that our capture adds no reduction.
            largePicture.extras.putParcelable(Notification.EXTRA_PICTURE, largeBitmap)
            val originalBytes = NotificationImage.extract(targetContext, largePicture)!!
            val decoded = android.graphics.BitmapFactory.decodeByteArray(originalBytes, 0, originalBytes.size)
            check(decoded.width == 1440 && decoded.height == 3200)
            check(decoded.getPixel(100, 100) == android.graphics.Color.GREEN)
            check(originalBytes[0] == 0x89.toByte() && originalBytes[1] == 0x50.toByte())
            val music = Notification.Builder(targetContext, "test").setCategory(Notification.CATEGORY_TRANSPORT).setLargeIcon(bitmap).build()
            check(NotificationImage.extract(targetContext, music) == null)
            val mediaStyle = Notification.Builder(targetContext, "test").setStyle(Notification.MediaStyle()).setLargeIcon(bitmap).build()
            check(NotificationImage.extract(targetContext, mediaStyle) == null)
            HistoryStore(targetContext, databaseName).use { store ->
                val bigBytes = ByteArray(3 * 1024 * 1024) { (it % 251).toByte() }
                store.save("large-image", "test", "Test", "Large", "", "", 1, image = bigBytes)
                check(store.image(store.lastId("large-image")!!)!!.contentEquals(bigBytes))
            }
            largeBitmap.recycle()
            decoded.recycle()
            bitmap.recycle()
            results.putString("images", "PASS: content picture only, no header icon, persistence, dedup, clear")
            results.putString("parser", "PASS: plain text and big text")
            finish(Activity.RESULT_OK, results)
        } catch (error: Throwable) {
            results.putString("failure", error.stackTraceToString())
            finish(Activity.RESULT_CANCELED, results)
        } finally { targetContext.deleteDatabase(databaseName) }
    }
}
