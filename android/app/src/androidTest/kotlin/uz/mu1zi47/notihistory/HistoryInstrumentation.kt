package uz.mu1zi47.notihistory

import android.app.Activity
import android.app.Instrumentation
import android.app.Notification
import android.database.sqlite.SQLiteDatabase
import android.os.Bundle

/** Platform-only integration tests: run on an emulator, no third-party test runtime. */
class HistoryInstrumentation : Instrumentation() {
    private var inspectSample = false
    private var inspectMarker = ""
    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        inspectSample = arguments?.getString("inspectSample") == "true"
        inspectMarker = arguments?.getString("inspectMarker").orEmpty()
        start()
    }
    override fun onStart() {
        val databaseName = "history-instrumentation.db"
        val results = Bundle()
        try {
            if (inspectSample) {
                val rows = org.json.JSONArray()
                SQLiteDatabase.openDatabase(targetContext.getDatabasePath("notification_history.db").absolutePath, null, SQLiteDatabase.OPEN_READONLY).use { db ->
                    db.rawQuery("SELECT id, body, posted_at, saved_at FROM history WHERE package_name = ? AND ((? = '' AND instr(lower(title), 'muizxo') > 0) OR (? != '' AND instr(body, ?) > 0)) ORDER BY id DESC LIMIT 15", arrayOf("org.telegram.messenger", inspectMarker, inspectMarker, inspectMarker)).use { cursor ->
                        while (cursor.moveToNext()) {
                            val body = cursor.getString(1)
                            val digest = java.security.MessageDigest.getInstance("SHA-256").digest(body.toByteArray()).joinToString("") { (it.toInt() and 255).toString(16).padStart(2, '0') }
                            rows.put(org.json.JSONObject().put("id", cursor.getLong(0)).put("length", body.length).put("digest", digest).put("tail", body.takeLast(60)).put("postedAt", cursor.getLong(2)).put("savedAt", cursor.getLong(3)).put("markers", org.json.JSONArray(listOf("TEST-A", "END-A", "TEST-B", "END-B", "TEST-C", "END-C").filter { body.contains(it) })))
                        }
                    }
                }
                results.putString("latestMuizxo", rows.toString())
                finish(Activity.RESULT_OK, results)
                return
            }
            val preferenceName = "capture-settings-instrumentation"
            targetContext.getSharedPreferences(preferenceName, 0).edit().clear().commit()
            val captureSettings = CaptureSettings(targetContext, preferenceName)
            check(captureSettings.enabled("test.app"))
            captureSettings.setEnabled("test.app", false)
            check(!CaptureSettings(targetContext, preferenceName).enabled("test.app"))
            check(captureSettings.enabled("other.app"))
            captureSettings.setEnabled("test.app", true)
            check(CaptureSettings(targetContext, preferenceName).enabled("test.app"))
            captureSettings.setEnabled("test.app", false)
            captureSettings.setEnabled("other.app", false)
            captureSettings.enableAll()
            check(CaptureSettings(targetContext, preferenceName).enabled("test.app"))
            check(CaptureSettings(targetContext, preferenceName).enabled("other.app"))
            targetContext.getSharedPreferences(preferenceName, 0).edit().clear().commit()
            results.putString("captureSettings", "PASS: default enabled, exclusion persisted, other apps unaffected, re-enable")
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
                val chargingKey = "-1|com.android.systemui|2131364006|charging_state|10063"
                store.save(chargingKey, "com.android.systemui", "System UI", "Charging", "41%", "", 1000, true)
                val chargingId = store.lastId(chargingKey)
                store.forget(chargingKey)
                store.reconcile(emptySet())
                store.save(chargingKey, "com.android.systemui", "System UI", "Charging", "42%", "", 1001)
                check(store.lastId(chargingKey) == chargingId) { "Charging repost created a new row" }
                check(store.query("", emptyList(), 0, null)["matched"] == 1)
                check(store.query("42%", emptyList(), 0, null)["matched"] == 1)
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
            val longText = "Long message ".repeat(600) + "END OF COMPLETE MESSAGE"
            val rawMessage = Bundle().apply {
                putCharSequence("text", longText)
                putLong("time", 1234)
                putCharSequence("sender", "Sender")
            }
            val longNotification = Notification.Builder(targetContext, "test").setContentTitle("Long message").setContentText("short").build()
            longNotification.extras.putParcelableArray(Notification.EXTRA_MESSAGES, arrayOf(rawMessage))
            @Suppress("DEPRECATION") val platformText = Notification.MessagingStyle.Message.getMessagesFromBundleArray(arrayOf(rawMessage)).single().text.toString()
            check(platformText.length < longText.length) { "Fixture must reproduce platform decoder truncation" }
            val longContent = NotificationContent.from(longNotification)
            check(longContent.body == "Sender: $longText") { "Messaging text was truncated" }
            check(longContent.repairedFrom == "Sender: $platformText")
            val secondMessage = Bundle().apply { putCharSequence("text", "Second"); putLong("time", 1235) }
            longNotification.extras.putParcelableArray(Notification.EXTRA_MESSAGES, arrayOf(rawMessage, secondMessage))
            check(NotificationContent.from(longNotification).body == "Sender: $longText\nSecond")
            val malformed = Bundle().apply { putInt("text", 123); putLong("time", 1236) }
            longNotification.extras.putParcelableArray(Notification.EXTRA_MESSAGES, arrayOf(malformed))
            check(NotificationContent.from(longNotification).body == "short")
            HistoryStore(targetContext, databaseName).use { store ->
                store.clear()
                store.save("long", "test", "Test", longContent.title, longContent.repairedFrom, "", 1234)
                val oldId = store.lastId("long")
                check(store.save("long", "test", "Test", longContent.title, longContent.body, "", 1234, repairedFrom = longContent.repairedFrom))
                check(store.lastId("long") == oldId) { "Repair should update the active truncated row" }
                check(store.query("", emptyList(), 0, null)["matched"] == 1)
            }
            HistoryStore(targetContext, databaseName).use { store ->
                @Suppress("UNCHECKED_CAST") val rows = store.query("", emptyList(), 0, null)["items"] as List<Map<String, Any>>
                check(rows.single()["body"] == "Sender: $longText") { "Long text failed storage round trip" }
            }
            results.putString("longMessages", "PASS: raw messages over 7K chars, multiple senders, malformed fallback, active-row repair, storage persistence")
            val completeA = NotificationMessage("Sender", "TEST-A " + "long text ".repeat(400) + " КОНЕЦ-A", 9000)
            val shortA = completeA.copy(text = completeA.text.take(1010) + "…")
            val completeB = NotificationMessage("Sender", "TEST-B " + "other text ".repeat(350) + " END-B", 9001)
            val shortB = completeB.copy(text = completeB.text.take(1010) + "…")
            val sameSecond = NotificationMessage("Sender", "A different message in the same second", 9001)
            HistoryStore(targetContext, databaseName).use { store ->
                store.clear()
                fun save(parts: List<NotificationMessage>, key: String = "chat") = store.save(key, "test", "Test", "Chat", parts.joinToString("\n") { it.formatted() }, "", 9000, messages = parts)
                save(listOf(shortA))
                val firstId = store.lastId("chat")!!
                save(listOf(completeA, shortB, sameSecond))
                val secondId = store.lastId("chat")!!
                save(listOf(completeA, completeB, sameSecond))
                @Suppress("UNCHECKED_CAST") val rows = store.query("", emptyList(), 0, null)["items"] as List<Map<String, Any>>
                check(rows.first { it["id"] == firstId }["body"] == completeA.formatted())
                check(store.notification(firstId)?.get("body") == completeA.formatted())
                check(store.notification(-1) == null)
                check(rows.first { it["id"] == secondId }["body"] == listOf(completeA, completeB, sameSecond).joinToString("\n") { it.formatted() })
                check(store.lastId("chat") == secondId) { "Full text should repair the existing snapshot" }
                check(store.query("конец-a", emptyList(), 0, null)["matched"] == 2) { "Repair must refresh Cyrillic search" }
                save(listOf(shortA), "another-chat")
                check(store.query("END-B", emptyList(), 0, null)["matched"] == 1)
            }
            HistoryStore(targetContext, databaseName).use { store ->
                store.forget("chat")
                store.save("chat", "test", "Test", "Chat", shortA.formatted(), "", 9000, messages = listOf(shortA))
                @Suppress("UNCHECKED_CAST") val rows = store.query("", emptyList(), 0, null)["items"] as List<Map<String, Any>>
                check(rows.first()["body"] == completeA.formatted()) { "A late short preview must not overwrite full text" }
                check(rows.any { it["body"] == shortA.formatted() }) { "Different chats must remain isolated" }
                store.clear()
                check(store.readableDatabase.rawQuery("SELECT COUNT(*) FROM history_messages", null).use { it.moveToFirst(); it.getInt(0) } == 0)
            }
            results.putString("messageUpdates", "PASS: short/full snapshots, earlier rows repaired, same-second isolation, persistence, no downgrade, Cyrillic search, clear cleanup")
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
