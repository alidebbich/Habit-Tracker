package com.habittracker.alarm

import android.app.KeyguardManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.habittracker.alarm/device_info"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockscreen()
    }

    override fun onResume() {
        super.onResume()
        showOverLockscreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Device info ──────────────────────────────────────────
                    "getManufacturer" -> {
                        result.success(Build.MANUFACTURER)
                    }

                    // ── MIUI AutoStart ───────────────────────────────────────
                    "openAutoStart" -> {
                        val opened = tryStartActivity(
                            Intent().apply {
                                component = ComponentName(
                                    "com.miui.securitycenter",
                                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                                )
                            }
                        )
                        if (!opened) {
                            // Fallback: open app info page
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            })
                        }
                        result.success(null)
                    }

                    // ── Battery Optimization ─────────────────────────────────
                    "openBatteryOptimization" -> {
                        val opened = tryStartActivity(
                            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                        )
                        if (!opened) {
                            tryStartActivity(
                                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            )
                        }
                        result.success(null)
                    }

                    // ── MIUI Background Pop-up Windows ───────────────────────
                    "openBackgroundPopup" -> {
                        // Try MIUI-specific permission manager first
                        val opened = tryStartActivity(
                            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                                setClassName(
                                    "com.miui.securitycenter",
                                    "com.miui.permcenter.permissions.PermissionsEditorActivity"
                                )
                                putExtra("extra_pkgname", packageName)
                            }
                        ) || tryStartActivity(
                            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                                putExtra("extra_pkgname", packageName)
                            }
                        )
                        if (!opened) {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            })
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /** Tries to start an intent; returns false if no activity can handle it. */
    private fun tryStartActivity(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun showOverLockscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager =
                getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }
}


