package uz.mu1zi47.notihistory

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.security.MessageDigest
import java.util.Calendar
import java.util.Locale

/** Writes are serialized; a separate reader uses WAL. No Flutter engine is needed. */
class HistoryStore(context: Context, databaseName: String = "notification_history.db") : SQLiteOpenHelper(context, databaseName, null, 6) {
    init { setWriteAheadLoggingEnabled(true) }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            package_name TEXT NOT NULL, app_name TEXT NOT NULL,
            title TEXT NOT NULL, body TEXT NOT NULL, sub_text TEXT NOT NULL,
            posted_at INTEGER NOT NULL, saved_at INTEGER NOT NULL,
            search_text TEXT NOT NULL, image BLOB, archived INTEGER NOT NULL DEFAULT 0
        )""")
        db.execSQL("CREATE INDEX history_package ON history(package_name, id)")
        db.execSQL("CREATE TABLE last_seen (notification_key TEXT PRIMARY KEY, digest TEXT NOT NULL, history_id INTEGER, coalescing INTEGER NOT NULL DEFAULT 0)")
        addIndexes(db)
        addMessageTable(db)
        addArchiveIndexes(db)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 6) {
            db.execSQL("ALTER TABLE history ADD COLUMN archived INTEGER NOT NULL DEFAULT 0")
            addArchiveIndexes(db)
        }
        if (oldVersion < 5) addMessageTable(db)
        if (oldVersion < 4) db.execSQL("ALTER TABLE history ADD COLUMN image BLOB")
        if (oldVersion < 2) addIndexes(db)
        if (oldVersion < 3) {
            db.execSQL("ALTER TABLE last_seen ADD COLUMN history_id INTEGER")
            db.execSQL("ALTER TABLE last_seen ADD COLUMN coalescing INTEGER NOT NULL DEFAULT 0")
        }
    }

    private fun addArchiveIndexes(db: SQLiteDatabase) {
        db.execSQL("CREATE INDEX IF NOT EXISTS history_archive_id ON history(archived, id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS history_archive_package ON history(archived, package_name)")
    }

    fun setArchived(id: Long, archived: Boolean) {
        writableDatabase.update("history", ContentValues().apply { put("archived", if (archived) 1 else 0) }, "id = ?", arrayOf(id.toString()))
    }

    private fun addIndexes(db: SQLiteDatabase) {
        db.execSQL("CREATE INDEX IF NOT EXISTS history_saved_at ON history(saved_at)")
        db.execSQL("CREATE INDEX IF NOT EXISTS history_package_date ON history(package_name, saved_at)")
    }

    fun save(key: String, packageName: String, appName: String, title: String,
             body: String, subText: String, postedAt: Long, coalesce: Boolean = false, image: ByteArray? = null, repairedFrom: String? = null, messages: List<NotificationMessage> = emptyList()): Boolean {
        val db = writableDatabase
        db.beginTransaction()
        try {
            val (resolvedMessages, repaired) = repairMessages(db, key, messages)
            val effectiveBody = if (resolvedMessages.isEmpty()) body else resolvedMessages.joinToString("\n") { it.formatted() }
            val hasher = MessageDigest.getInstance("SHA-256")
            hasher.update("$title\u0000$effectiveBody\u0000$subText".toByteArray())
            if (image != null) hasher.update(image)
            val digest = hasher.digest().joinToString("") { (it.toInt() and 0xff).toString(16).padStart(2, '0') }
            val previous = db.rawQuery("SELECT digest, history_id, coalescing FROM last_seen WHERE notification_key = ?", arrayOf(key))
                .use { if (it.moveToFirst()) Triple(it.getString(0), if (it.isNull(1)) null else it.getLong(1), it.getInt(2) != 0) else null }
            if (previous?.first == digest) {
                previous.second?.let { id ->
                    val exists = db.rawQuery("SELECT 1 FROM history WHERE id = ?", arrayOf(id.toString())).use { it.moveToFirst() }
                    if (exists && resolvedMessages.isNotEmpty()) saveMessages(db, id, key, resolvedMessages)
                }
                db.setTransactionSuccessful()
                return repaired
            }
            val values = ContentValues().apply {
                put("package_name", packageName); put("app_name", appName)
                put("title", title); put("body", effectiveBody); put("sub_text", subText); put("image", image)
                put("posted_at", postedAt); put("saved_at", System.currentTimeMillis())
                put("search_text", "$appName\n$packageName\n$title\n$effectiveBody\n$subText".lowercase(Locale.ROOT))
            }
            val coalescing = coalesce || isChargingKey(key) || previous?.third == true
            val previousId = previous?.second
            val sameContent = if (previousId == null) false else db.rawQuery(
                "SELECT title, body, sub_text FROM history WHERE id = ?", arrayOf(previousId.toString())
            ).use { it.moveToFirst() && it.getString(0) == title && (it.getString(1) == effectiveBody || (repairedFrom != null && it.getString(1) == repairedFrom)) && it.getString(2) == subText }
            val updated = if ((coalescing || sameContent) && previousId != null) db.update("history", values, "id = ?", arrayOf(previousId.toString())) else 0
            val id = if (updated > 0) previousId!! else db.insertOrThrow("history", null, values)
            saveMessages(db, id, key, resolvedMessages)
            db.insertWithOnConflict("last_seen", null, ContentValues().apply {
                put("notification_key", key); put("digest", digest); put("history_id", id); put("coalescing", if (coalescing) 1 else 0)
            }, SQLiteDatabase.CONFLICT_REPLACE)
            db.setTransactionSuccessful()
            return true
        } finally { db.endTransaction() }
    }

    private fun saveMessages(db: SQLiteDatabase, id: Long, key: String, messages: List<NotificationMessage>) {
        db.delete("history_messages", "history_id = ?", arrayOf(id.toString()))
        messages.forEachIndexed { position, message ->
            db.insertOrThrow("history_messages", null, ContentValues().apply {
                put("history_id", id); put("position", position); put("notification_key", key)
                put("sender", message.sender); put("sent_at", message.time); put("body", message.text)
            })
        }
    }

    private fun addMessageTable(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE history_messages (history_id INTEGER NOT NULL, position INTEGER NOT NULL, notification_key TEXT NOT NULL, sender TEXT NOT NULL, sent_at INTEGER NOT NULL, body TEXT NOT NULL, PRIMARY KEY(history_id, position))")
        db.execSQL("CREATE INDEX history_message_identity ON history_messages(notification_key, sent_at, sender)")
        db.execSQL("CREATE TRIGGER history_messages_cleanup AFTER DELETE ON history BEGIN DELETE FROM history_messages WHERE history_id = OLD.id; END")
    }

    /** A later Telegram snapshot can contain the full text of an earlier short push. */
    private fun repairMessages(db: SQLiteDatabase, key: String, incoming: List<NotificationMessage>): Pair<List<NotificationMessage>, Boolean> {
        val affected = mutableSetOf<Long>()
        val resolved = incoming.map { message ->
            data class Previous(val id: Long, val position: Int, val message: NotificationMessage)
            val previous = db.rawQuery(
                "SELECT history_id, position, body FROM history_messages WHERE notification_key = ? AND sent_at = ? AND sender = ?",
                arrayOf(key, message.time.toString(), message.sender)
            ).use { cursor -> buildList {
                while (cursor.moveToNext()) add(Previous(cursor.getLong(0), cursor.getInt(1), message.copy(text = cursor.getString(2))))
            } }
            // Never replace complete text with a shorter preview, including after a reconnect.
            val candidates = previous.map { it.message }.filter { message.isExpandedBy(it) }.distinctBy { it.text }
            val full = if (candidates.size == 1) candidates.single() else message
            previous.filter { it.message.isExpandedBy(full) }.forEach { old ->
                db.execSQL("UPDATE history_messages SET body = ? WHERE history_id = ? AND position = ?", arrayOf<Any>(full.text, old.id, old.position))
                affected.add(old.id)
            }
            full
        }
        affected.forEach { id ->
            val body = db.rawQuery("SELECT sender, body FROM history_messages WHERE history_id = ? ORDER BY position", arrayOf(id.toString())).use { cursor ->
                buildList { while (cursor.moveToNext()) {
                    val sender = cursor.getString(0); val text = cursor.getString(1)
                    add(if (sender.isBlank()) text else "$sender: $text")
                } }.joinToString("\n")
            }
            val searchText = db.rawQuery("SELECT app_name, package_name, title, sub_text FROM history WHERE id = ?", arrayOf(id.toString())).use { cursor ->
                if (!cursor.moveToFirst()) return@forEach
                "${cursor.getString(0)}\n${cursor.getString(1)}\n${cursor.getString(2)}\n$body\n${cursor.getString(3)}".lowercase(Locale.ROOT)
            }
            db.execSQL("UPDATE history SET body = ?, search_text = ? WHERE id = ?", arrayOf<Any>(body, searchText, id))
        }
        return resolved to affected.isNotEmpty()
    }

    fun notification(id: Long): Map<String, Any>? = readableDatabase.rawQuery(
        "SELECT id, package_name, app_name, title, body, sub_text, posted_at, saved_at, image IS NOT NULL FROM history WHERE id = ?", arrayOf(id.toString())
    ).use { c ->
        if (!c.moveToFirst()) null else mapOf(
            "id" to c.getLong(0), "packageName" to c.getString(1), "appName" to c.getString(2),
            "title" to c.getString(3), "body" to c.getString(4), "subText" to c.getString(5),
            "postedAt" to c.getLong(6), "savedAt" to c.getLong(7), "hasImage" to (c.getInt(8) != 0),
            "messages" to readableDatabase.rawQuery("SELECT sender, body FROM history_messages WHERE history_id = ? ORDER BY position", arrayOf(id.toString())).use { messages ->
                buildList { while (messages.moveToNext()) {
                    val sender = messages.getString(0)
                    val text = messages.getString(1)
                    add(if (sender.isBlank()) text else "$sender: $text")
                } }
            }
        )
    }

    fun image(id: Long): ByteArray? {
        val db = readableDatabase
        db.beginTransactionNonExclusive()
        try {
            val length = db.rawQuery("SELECT length(image) FROM history WHERE id = ?", arrayOf(id.toString()))
                .use { if (it.moveToFirst() && !it.isNull(0)) it.getInt(0) else return null }
            // Read in chunks: full-resolution PNGs can exceed CursorWindow's limit.
            return java.io.ByteArrayOutputStream(length).use { output ->
                var offset = 1
                while (offset <= length) {
                    db.rawQuery("SELECT substr(image, ?, 262144) FROM history WHERE id = ?", arrayOf(offset.toString(), id.toString()))
                        .use { if (it.moveToFirst()) output.write(it.getBlob(0)) }
                    offset += 262144
                }
                output.toByteArray()
            }
        } finally { db.endTransaction() }
    }

    fun lastId(key: String): Long? = readableDatabase.rawQuery(
        "SELECT history_id FROM last_seen WHERE notification_key = ?", arrayOf(key)
    ).use { if (it.moveToFirst() && !it.isNull(0)) it.getLong(0) else null }

    fun forget(key: String) {
        // Samsung removes and reposts charging_state as the battery changes.
        // Keep its row identity across removals and listener reconciliation.
        if (isChargingKey(key)) return
        writableDatabase.delete("last_seen", "notification_key = ?", arrayOf(key))
    }

    private fun isChargingKey(key: String): Boolean {
        val parts = key.split('|')
        return parts.size >= 4 && parts[1] == "com.android.systemui" && parts[3] == "charging_state"
    }

    fun reconcile(activeKeys: Set<String>) {
        val db = writableDatabase
        val obsolete = db.rawQuery("SELECT notification_key FROM last_seen", null).use { cursor ->
            buildList { while (cursor.moveToNext()) { val key = cursor.getString(0); if (key !in activeKeys) add(key) } }
        }
        obsolete.forEach { forget(it) }
    }

    fun clear(search: String = "", packageNames: List<String> = emptyList(), since: Long = 0, archived: Boolean = false) {
        // Keep last_seen so active notifications do not reappear after a reconnect.
        val (conditions, args) = filters(search, packageNames, since, archived)
        writableDatabase.delete("history", conditions.takeIf { it.isNotEmpty() }?.joinToString(" AND "), args.toTypedArray())
    }

    fun delete(id: Long) {
        writableDatabase.delete("history", "id = ?", arrayOf(id.toString()))
    }

    private fun filters(search: String, packageNames: List<String>, since: Long, archived: Boolean): Pair<MutableList<String>, MutableList<String>> {
        val conditions = mutableListOf("archived = ${if (archived) 1 else 0}")
        val args = mutableListOf<String>()
        if (since > 0) { conditions.add("saved_at >= ?"); args.add(since.toString()) }
        if (search.isNotBlank()) {
            conditions.add("instr(search_text, ?) > 0")
            args.add(search.trim().lowercase(Locale.ROOT))
        }
        if (packageNames.isNotEmpty()) {
            conditions.add("package_name IN (${packageNames.joinToString(",") { "?" }})")
            args.addAll(packageNames)
        }
        return conditions to args
    }

    fun query(search: String, packageNames: List<String>, since: Long, beforeId: Long?, includeOverview: Boolean = true, archived: Boolean = false): Map<String, Any> {
        val (conditions, args) = filters(search, packageNames, since, archived)
        val db = readableDatabase
        fun where() = if (conditions.isEmpty()) "" else "WHERE ${conditions.joinToString(" AND ")}"
        // A cursor page does not need to recount all matches or rebuild the app list.
        val matched = if (beforeId == null) db.rawQuery("SELECT COUNT(*) FROM history ${where()}", args.toTypedArray())
            .use { it.moveToFirst(); it.getInt(0) } else 0
        if (beforeId != null) { conditions.add("id < ?"); args.add(beforeId.toString()) }
        val rows = db.rawQuery("SELECT id, package_name, app_name, title, body, sub_text, posted_at, saved_at, image IS NOT NULL FROM history ${where()} ORDER BY id DESC LIMIT 61", args.toTypedArray()).use { c ->
            buildList {
                while (c.moveToNext()) add(mapOf<String, Any>(
                    "id" to c.getLong(0), "packageName" to c.getString(1), "appName" to c.getString(2),
                    "title" to c.getString(3), "body" to c.getString(4), "subText" to c.getString(5),
                    "postedAt" to c.getLong(6), "savedAt" to c.getLong(7), "hasImage" to (c.getInt(8) != 0)
                ))
            }
        }
        val result = mutableMapOf<String, Any>("items" to rows.take(60), "hasMore" to (rows.size > 60), "matched" to matched)
        if (!includeOverview) return result
        val midnight = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val scope = if (archived) 1 else 0
        val stats = db.rawQuery("SELECT (SELECT COUNT(*) FROM history WHERE archived = $scope), (SELECT COUNT(*) FROM history WHERE archived = $scope AND saved_at >= ?), (SELECT COUNT(*) FROM history WHERE archived = 1)", arrayOf(midnight.toString()))
            .use { it.moveToFirst(); mapOf("total" to it.getInt(0), "today" to it.getInt(1), "archived" to it.getInt(2)) }
        val apps = db.rawQuery("SELECT package_name, MAX(app_name), COUNT(*) FROM history WHERE archived = $scope GROUP BY package_name ORDER BY COUNT(*) DESC", null).use { c ->
            buildList { while (c.moveToNext()) add(mapOf("packageName" to c.getString(0), "appName" to c.getString(1), "count" to c.getInt(2))) }
        }
        result["stats"] = stats
        result["apps"] = apps
        return result
    }
}
