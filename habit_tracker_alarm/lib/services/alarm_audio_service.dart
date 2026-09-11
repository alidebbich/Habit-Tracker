import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

/// Plays alarm sounds via the Android ALARM audio stream so they bypass
/// silent / vibrate mode and keep the speaker on while the screen is locked.
class AlarmAudioService {
  AlarmAudioService._internal();
  static final AlarmAudioService _instance = AlarmAudioService._internal();
  factory AlarmAudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Built-in sounds that live in android/app/src/main/res/raw/
  static const _builtIn = {'cinematic_rise', 'gentle_bells', 'digital_beep'};

  /// The Android package name — must match AndroidManifest.xml
  static const _pkg = 'com.example.habit_tracker_alarm';

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Plays an alarm sound continuously on the ALARM stream.
  /// Bypasses silent / vibrate modes on Android.
  Future<void> playAlarmSound(String sound) async {
    try {
      await _player.stop();

      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );

      await _player.setReleaseMode(ReleaseMode.loop);

      // ── 1. Custom file picked from the phone ─────────────────────────────
      if (_isFilePath(sound)) {
        final file = File(sound);
        if (await file.exists()) {
          await _player.play(DeviceFileSource(sound));
          _isPlaying = true;
          return;
        }
      }

      // ── 2. Built-in raw Android resource ─────────────────────────────────
      if (_builtIn.contains(sound)) {
        await _player.play(
          UrlSource('android.resource://$_pkg/raw/$sound'),
        );
        _isPlaying = true;
        return;
      }

      // ── 3. Ultimate fallback ─────────────────────────────────────────────
      await _player.play(
        UrlSource('android.resource://$_pkg/raw/digital_beep'),
      );
      _isPlaying = true;
    } catch (_) {
      // Fail silently — the notification sound will still ring
    }
  }

  /// Preview a sound once (no loop) — used in the alarm editor sheet.
  Future<void> previewSound(String sound) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);

      if (_isFilePath(sound)) {
        final file = File(sound);
        if (await file.exists()) {
          await _player.play(DeviceFileSource(sound));
          _isPlaying = true;
          return;
        }
      }

      if (_builtIn.contains(sound)) {
        await _player.play(
          UrlSource('android.resource://$_pkg/raw/$sound'),
        );
        _isPlaying = true;
        return;
      }
    } catch (_) {}
  }

  /// Stops any currently playing sound.
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isFilePath(String s) =>
      s.startsWith('/') ||
      (Platform.isAndroid && s.contains(Platform.pathSeparator));
}
