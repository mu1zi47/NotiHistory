package uz.mu1zi47.notihistory

import android.app.Activity
import android.app.UiModeManager
import android.os.Build

/** Persists the app override so Android also uses it for the next launch screen. */
object AppNightMode {
    fun apply(activity: Activity, theme: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            activity.getSystemService(UiModeManager::class.java).setApplicationNightMode(
                when (theme) {
                    "light" -> UiModeManager.MODE_NIGHT_NO
                    "dark" -> UiModeManager.MODE_NIGHT_YES
                    else -> UiModeManager.MODE_NIGHT_AUTO
                }
            )
        }
    }
}
