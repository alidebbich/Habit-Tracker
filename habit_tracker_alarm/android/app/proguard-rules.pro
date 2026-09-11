# Flutter Local Notifications rules
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Keep AudioPlayers
-keep class xyz.luan.audioplayers.** { *; }

# Core library desugaring
-keep class j$.** { *; }
