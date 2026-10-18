package uz.mu1zi47.notihistory

import android.content.Context
import android.content.Intent

/** Shared with the listener so filtering also works without a Flutter engine. */
class CaptureSettings(private val context: Context, name: String = "capture_settings") {
    private val preferences = context.getSharedPreferences(name, Context.MODE_PRIVATE)

    fun enabled(packageName: String): Boolean = packageName !in blocked()
    private fun blocked(): Set<String> = preferences.getStringSet("blocked_packages", emptySet()).orEmpty().toSet()

    fun setEnabled(packageName: String, enabled: Boolean) {
        require(packageName.isNotBlank())
        val packages = blocked().toMutableSet()
        if (enabled) packages.remove(packageName) else packages.add(packageName)
        check(preferences.edit().putStringSet("blocked_packages", packages).commit())
    }

    fun enableAll() {
        check(preferences.edit().remove("blocked_packages").commit())
    }

    fun apps(store: HistoryStore): List<Map<String, Any>> {
        val manager = context.packageManager
        val packages = mutableSetOf("com.android.systemui", "android")
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        manager.queryIntentActivities(launcher, 0).forEach { packages.add(it.activityInfo.packageName) }
        val names = mutableMapOf<String, String>()
        store.readableDatabase.rawQuery("SELECT package_name, MAX(app_name) FROM history GROUP BY package_name", null).use { cursor ->
            while (cursor.moveToNext()) { packages.add(cursor.getString(0)); names[cursor.getString(0)] = cursor.getString(1) }
        }
        packages.addAll(blocked())
        val excluded = blocked()
        return packages.map { packageName ->
            val label = try { manager.getApplicationLabel(manager.getApplicationInfo(packageName, 0)).toString() }
                catch (_: Exception) { names[packageName] ?: packageName }
            mapOf<String, Any>("packageName" to packageName, "name" to label, "enabled" to (packageName !in excluded))
        }.sortedBy { (it["name"] as String).lowercase(java.util.Locale.ROOT) }
    }
}
