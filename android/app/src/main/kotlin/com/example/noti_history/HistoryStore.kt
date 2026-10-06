package com.example.noti_history

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.security.MessageDigest
import java.util.Calendar
import java.util.Locale

/** Writes are serialized; a separate reader uses WAL. No Flutter engine is needed. */
class HistoryStore(context: Context, databaseName: String = "notification_history.db") : SQLiteOpenHelper(context, databaseName, null, 4) {
    init { setWriteAheadLoggingEnabled(true) }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            package_name TEXT NOT NULL, app_name TEXT NOT NULL,
            title TEXT NOT NULL, body TEXT NOT NULL, sub_text TEXT NOT NULL,
            posted_at INTEGER NOT NULL, saved_at INTEGER NOT NULL,
            search_text TEXT NOT NULL, image BLOB
        )""")
        db.execSQL("CREATE INDEX history_package ON history(package_name, id)")
        db.execSQL("CREATE TABLE last_seen (notification_key TEXT PRIMARY KEY, digest TEXT NOT NULL, history_id INTEGER, coalescing INTEGER NOT NULL DEFAULT 0)")
        addIndexes(db)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 4) db.execSQL("ALTER TABLE history ADD COLUMN image BLOB")
        if (oldVersion < 2) addIndexes(db)
        if (oldVersion < 3) {
            db.execSQL("ALTER TABLE last_seen ADD COLUMN history_id INTEGER")
            db.execSQL("ALTER TABLE last_seen ADD COLUMN coalescing INTEGER NOT NULL DEFAULT 0")
        }
    }

    private fun addIndexes(db: SQLiteDatabase) {
        db.execSQL("CREATE INDEX IF NOT EXISTS history_saved_at ON history(saved_at)")
        db.execSQL("CREATE INDEX IF NOT EXISTS history_package_date ON history(package_name, saved_at)")
    }

    fun save(key: String, packageName: String, appName: String, title: String,
             body: String, subText: String, postedAt: Long, coalesce: Boolean = false, image: ByteArray? = null): Boolean {
        val hasher = MessageDigest.getInstance("SHA-256")
        hasher.update("$title\u0000$body\u0000$subText".toByteArray())
        if (image != null) hasher.update(image)
        val digest = hasher.digest()
            .joinToString("") { (it.toInt() and 0xff).toString(16).padStart(2, '0') }
        val db = writableDatabase
        db.beginTransaction()
        try {
            val previous = db.rawQuery("SELECT digest, history_id, coalescing FROM last_seen WHERE notification_key = ?", arrayOf(key))
                .use { if (it.moveToFirst()) Triple(it.getString(0), if (it.isNull(1)) null else it.getLong(1), it.getInt(2) != 0) else null }
            if (previous?.first == digest) { db.setTransactionSuccessful(); return false }
            val values = ContentValues().apply {
                put("package_name", packageName); put("app_name", appName)
                put("title", title); put("body", body); put("sub_text", subText); put("image", image)
                put("posted_at", postedAt); put("saved_at", System.currentTimeMillis())
                put("search_text", "$appName\n$packageName\n$title\n$body\n$subText".lowercase(Locale.ROOT))
            }
            val coalescing = coalesce || previous?.third == true
            val previousId = previous?.second
            val sameContent = if (previousId == null) false else db.rawQuery(
                "SELECT title, body, sub_text FROM history WHERE id = ?", arrayOf(previousId.toString())
            ).use { it.moveToFirst() && it.getString(0) == title && it.getString(1) == body && it.getString(2) == subText }
            val updated = if ((coalescing || sameContent) && previousId != null) db.update("history", values, "id = ?", arrayOf(previousId.toString())) else 0
            val id = if (updated > 0) previousId!! else db.insertOrThrow("history", null, values)
            db.insertWithOnConflict("last_seen", null, ContentValues().apply {
                put("notification_key", key); put("digest", digest); put("history_id", id); put("coalescing", if (coalescing) 1 else 0)
            }, SQLiteDatabase.CONFLICT_REPLACE)
            db.setTransactionSuccessful()
            return true
        } finally { db.endTransaction() }
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
        writableDatabase.delete("last_seen", "notification_key = ?", arrayOf(key))
    }

    fun reconcile(activeKeys: Set<String>) {
        val db = writableDatabase
        val obsolete = db.rawQuery("SELECT notification_key FROM last_seen", null).use { cursor ->
            buildList { while (cursor.moveToNext()) { val key = cursor.getString(0); if (key !in activeKeys) add(key) } }
        }
        obsolete.forEach { forget(it) }
    }

    fun clear(search: String = "", packageNames: List<String> = emptyList(), since: Long = 0) {
        // Keep last_seen so active notifications do not reappear after a reconnect.
        val (conditions, args) = filters(search, packageNames, since)
        writableDatabase.delete("history", conditions.takeIf { it.isNotEmpty() }?.joinToString(" AND "), args.toTypedArray())
    }

    fun delete(id: Long) {
        writableDatabase.delete("history", "id = ?", arrayOf(id.toString()))
    }

    private fun filters(search: String, packageNames: List<String>, since: Long): Pair<MutableList<String>, MutableList<String>> {
        val conditions = mutableListOf<String>()
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

    fun query(search: String, packageNames: List<String>, since: Long, beforeId: Long?, includeOverview: Boolean = true): Map<String, Any> {
        val (conditions, args) = filters(search, packageNames, since)
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
        val stats = db.rawQuery("SELECT (SELECT COUNT(*) FROM history), (SELECT COUNT(*) FROM history WHERE saved_at >= ?)", arrayOf(midnight.toString()))
            .use { it.moveToFirst(); mapOf("total" to it.getInt(0), "today" to it.getInt(1)) }
        val apps = db.rawQuery("SELECT package_name, MAX(app_name), COUNT(*) FROM history GROUP BY package_name ORDER BY COUNT(*) DESC", null).use { c ->
            buildList { while (c.moveToNext()) add(mapOf("packageName" to c.getString(0), "appName" to c.getString(1), "count" to c.getInt(2))) }
        }
        result["stats"] = stats
        result["apps"] = apps
        return result
    }
}
