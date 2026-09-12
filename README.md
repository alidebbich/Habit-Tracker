<div align="center">

# ⏰ Momentum

### Wake up. Build habits. Own your morning.

**The Android alarm app that won't let you snooze your way out of a good morning.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-5.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/license-MIT-B5D96B?style=flat-square)](#license)

</div>

---

## 📖 What is Momentum?

Most people use two apps — one for alarms, one for habits. **Momentum** merges them.

Set an alarm. Link it to a habit. The alarm **won't stop** until you complete a morning mission (solve a math problem, type a phrase, or check off your habit). Wake up forced into your routine, streak growing automatically.

One app. One streak. No excuses.

---

## ✨ Features

### ⏰ Mission-Based Alarm
The alarm fires, your screen wakes up, and you **cannot dismiss it** without completing a task:

| Mission Type | Description |
|---|---|
| 🧮 **Math Problem** | Solve a randomly generated addition problem |
| ⌨️ **Typing Challenge** | Type an exact phrase: *"I am awake and ready for the day"* |
| 🔗 **Habit Check** | Tap "Done" to log your linked morning habit |
| 👆 **Tap to Dismiss** | Simple dismiss — no mission required |

### 📱 Wakes Your Locked Phone
- Turns the screen on even when the phone is locked and in silent mode
- Full-screen alarm UI appears over the lock screen
- Alarm sound plays on the **ALARM audio stream** — bypasses Do Not Disturb
- Vibration support

### 🎵 Choose Any Sound
- Built-in tones: Cinematic Rise, Gentle Bells, Digital Beep
- **Pick any song from your phone's music library** — MP3, WAV, M4A, and more
- Preview sounds before saving
- Sound persists across app restarts

### 🗓️ Flexible Scheduling
- Every day or specific weekdays (Mon, Tue, Wed…)
- Multiple alarms for different routines
- Alarm persists through phone restarts (rescheduled on boot)
- Exact alarm mode for Android 12+ (with permission)

### 📊 Habit Tracking & Streaks
- Add unlimited habits with custom name, icon, and colour
- 30-day heatmap calendar showing completion history
- Current streak, best streak, and completion percentage
- Completing an alarm mission **auto-checks** the linked habit

### 📈 Stats Screen
- Per-habit completion heatmap
- Overall streak stats
- Weekly and monthly completion breakdowns

### 🎨 Beautiful Dark UI
- Void dark theme (`#0A0F06`) with glow green (`#B5D96B`) accent
- Fraunces serif display font + Inter UI font
- Glassmorphism cards, smooth animations via `flutter_animate`
- Animated splash screen on launch

---

## 📸 Screenshots

> *Add screenshots here once the app is on the Play Store.*

| Splash | Today | Alarms | Alarm Firing |
|---|---|---|---|
| *(coming soon)* | *(coming soon)* | *(coming soon)* | *(coming soon)* |

---

## 🏗️ Project Structure

```text
lib/
├── main.dart                  # App entry point, AlarmService init, routing
│
├── models/
│   ├── alarm.dart             # Alarm model + DismissMissionType enum
│   ├── habit.dart             # Habit model with streak/completion logic
│   └── schedule_task.dart     # Scheduled task model
│
├── data/
│   ├── database_helper.dart   # SQLite schema & migrations
│   ├── alarm_repository.dart  # CRUD for alarms
│   └── habit_repository.dart  # CRUD for habits
│
├── services/
│   ├── alarm_service.dart     # flutter_local_notifications scheduling,
│   │                          # permission requests, exact alarm handling
│   └── alarm_audio_service.dart # audioplayers wrapper for alarm sounds
│
├── providers/
│   └── alarm_provider.dart    # Riverpod state for alarm list
│
├── screens/
│   ├── splash_screen.dart     # Animated launch screen (routing handler)
│   ├── onboarding_screen.dart # 3-page first-launch walkthrough
│   ├── home_screen.dart       # Bottom-nav shell
│   ├── today_page.dart        # Today's habits checklist
│   ├── alarms_page.dart       # Alarm list + permission banners
│   ├── schedule_page.dart     # Habit schedule view
│   ├── stats_screen.dart      # Streaks, heatmap, stats
│   └── alarm_dismiss_screen.dart # Full-screen alarm with missions
│
├── widgets/
│   ├── add_alarm_sheet.dart   # Bottom sheet: create/edit alarm
│   ├── add_habit_dialog.dart  # Dialog: create/edit habit
│   └── glass_card.dart        # Reusable glassmorphism card
│
└── Utils/
    └── ...                    # Utility helpers

android/
└── app/src/main/
    ├── AndroidManifest.xml    # Permissions + activity flags
    ├── kotlin/.../MainActivity.kt  # Lock screen / wake-up flags
    └── res/raw/               # Built-in alarm sounds (WAV)
        ├── cinematic_rise.wav
        ├── gentle_bells.wav
        └── digital_beep.wav
```

---

## 🛠️ Tech Stack

| Library | Purpose |
|---|---|
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | Scheduling exact alarms, full-screen intent, notification channels |
| [sqflite](https://pub.dev/packages/sqflite) | Local SQLite database for habits and alarms |
| [audioplayers](https://pub.dev/packages/audioplayers) | Playing alarm sounds on the ALARM audio stream |
| [file_picker](https://pub.dev/packages/file_picker) | Native music library picker (FileType.audio) |
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | State management |
| [flutter_animate](https://pub.dev/packages/flutter_animate) | Micro-animations and transitions |
| [fl_chart](https://pub.dev/packages/fl_chart) | Habit streak heatmap |
| [google_fonts](https://pub.dev/packages/google_fonts) | Fraunces + Inter typography |
| [permission_handler](https://pub.dev/packages/permission_handler) | Runtime permission requests |
| [timezone / flutter_timezone](https://pub.dev/packages/timezone) | Correct timezone-aware alarm scheduling |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Onboarding state, simple settings |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) **3.x+**
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API 21+)

### Clone & Run

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/morning-routine.git
cd morning-routine/habit_tracker_alarm

# Install dependencies
flutter pub get

# Run on a connected Android device
flutter run
```

### Build a Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📋 Android Permissions

The app requests the following permissions at runtime:

| Permission | Why |
|---|---|
| `POST_NOTIFICATIONS` | Show alarm notifications (Android 13+) |
| `SCHEDULE_EXACT_ALARM` | Deliver alarms at the exact time (Android 12+) |
| `USE_FULL_SCREEN_INTENT` | Show alarm over lock screen |
| `WAKE_LOCK` | Keep CPU running when alarm fires |
| `RECEIVE_BOOT_COMPLETED` | Reschedule alarms after phone restart |
| `READ_MEDIA_AUDIO` | Access music library for custom alarm sounds (Android 13+) |
| `VIBRATE` | Alarm vibration |

> **Android 14+ Note:** You may need to manually grant **"Display over other apps"** in  
> *Settings → Apps → Momentum → Special app access → Display over other apps*  
> for the full-screen alarm to appear over the lock screen.

---

## 🔧 How Alarm Delivery Works

```text
┌─────────────────────────────────────────────────┐
│  User sets alarm at 7:00 AM                     │
│       ↓                                         │
│  flutter_local_notifications schedules via      │
│  Android AlarmManager (exactAllowWhileIdle)     │
│       ↓                                         │
│  At 7:00 AM — phone is locked:                  │
│  ┌─────────────────────────────────────────┐   │
│  │  Android fires full-screen intent        │   │
│  │  MainActivity.kt sets window flags:      │   │
│  │    • showWhenLocked                       │   │
│  │    • turnScreenOn                         │   │
│  │    • dismissKeyguard                      │   │
│  └─────────────────────────────────────────┘   │
│       ↓                                         │
│  Flutter initialises → onAlarmFired callback    │
│       ↓                                         │
│  AlarmDismissScreen pushed                      │
│  AlarmAudioService plays sound on ALARM stream  │
│       ↓                                         │
│  User completes mission → alarm dismissed       │
│  Linked habit auto-checked ✓                    │
└─────────────────────────────────────────────────┘
```

---

## 🤝 Contributing

Pull requests are welcome! For major changes please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create your branch (`git checkout -b feature/cool-mission-type`)
3. Commit your changes (`git commit -m 'feat: add barcode scan mission'`)
4. Push to the branch (`git push origin feature/cool-mission-type`)
5. Open a Pull Request

### Commit convention
This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat:     A new feature
fix:      A bug fix
refactor: Code change that neither fixes a bug nor adds a feature
style:    Formatting, missing semicolons, etc.
docs:     Documentation changes
```

---

## 📄 License

```text
MIT License

Copyright (c) 2026 Momentum

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

See [LICENSE](LICENSE) for the full text.

---

<div align="center">

**Built with ❤️ and Flutter**

*Wake up. Build habits. Own your morning.*

</div>
