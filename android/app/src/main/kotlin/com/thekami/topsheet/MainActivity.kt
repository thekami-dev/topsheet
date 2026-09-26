package com.thekami.topsheet

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "topsheet/install_source"

    override fun onCreate(savedInstanceState: Bundle?) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        when (prefs.getString("flutter.themeMode", "system")) {
            "light" -> setTheme(R.style.LaunchThemeLight)
            "dark" -> setTheme(R.style.LaunchThemeDark)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstaller") {
                result.success(installerPackageName())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun installerPackageName(): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName)
            }
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }
}
