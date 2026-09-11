# ── Flutter Local Notifications ───────────────────────────────────────────────
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }

# ── SQLite / sqflite ──────────────────────────────────────────────────────────
-keep class io.flutter.plugins.sqflite.** { *; }
-keepclassmembers class io.flutter.plugins.sqflite.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keepclassmembers class com.tekartik.sqflite.** { *; }

# ── AudioPlayers ──────────────────────────────────────────────────────────────
-keep class xyz.luan.audioplayers.** { *; }
-keepclassmembers class xyz.luan.audioplayers.** { *; }

# ── Permission Handler ────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-keepclassmembers class com.baseflow.permissionhandler.** { *; }

# ── File Picker ───────────────────────────────────────────────────────────────
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keepclassmembers class com.mr.flutter.plugin.filepicker.** { *; }

# ── Path Provider ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ── Shared Preferences ────────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ── Core library desugaring ───────────────────────────────────────────────────
-keep class j$.** { *; }
-dontwarn j$.**

# ── Suppress warnings for optional Google Play Core classes ───────────────────
# These are only needed for Play Store deferred components (not used here)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-dontwarn kotlin.**
