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

# ── Timezone & Flutter Timezone ───────────────────────────────────────────────
# CRITICAL: Without these, R8 strips timezone classes in release builds,
# causing silent failures where alarms fire at wrong times or not at all.
-keep class com.pinkfish.flutter_timezone.** { *; }
-keepclassmembers class com.pinkfish.flutter_timezone.** { *; }
-keep class org.threeten.** { *; }
-keepclassmembers class org.threeten.** { *; }

# ── Flutter Timezone plugin (new package name) ────────────────────────────────
-keep class dev.fluttercommunity.plus.timezone.** { *; }
-keepclassmembers class dev.fluttercommunity.plus.timezone.** { *; }
-keep class vn.hunghd.flutter.plugins.** { *; }

# ── Core library desugaring ───────────────────────────────────────────────────
-keep class j$.** { *; }
-dontwarn j$.**

# ── General Flutter plugin safety ────────────────────────────────────────────
-keep class io.flutter.plugin.** { *; }
-keepclassmembers class io.flutter.plugin.** { *; }

# ── Suppress warnings for optional Google Play Core classes ───────────────────
# These are only needed for Play Store deferred components (not used here)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-dontwarn kotlin.**
