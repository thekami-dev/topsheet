package com.thekami.topsheet

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Read the app's own saved theme preference (written by
        // shared_preferences from Dart) BEFORE the window/splash is created,
        // so the native splash matches what the user picked in Settings
        // instead of just following the phone's system dark/light mode.
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        when (prefs.getString("flutter.themeMode", "system")) {
            "light" -> setTheme(R.style.LaunchThemeLight)
            "dark" -> setTheme(R.style.LaunchThemeDark)
            // "system" (or not set yet) -> keep manifest-declared LaunchTheme,
            // which already follows values/values-night (device setting).
        }
        super.onCreate(savedInstanceState)
    }
}
