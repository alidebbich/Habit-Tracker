import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the 3 Xiaomi/MIUI-specific settings that kill background alarms:
///   1. AutoStart  — lets the app restart itself after being swiped away
///   2. Battery optimization exempt — stops MIUI from freezing the app's timers
///   3. Background pop-up windows — allows full-screen alarm UI over lockscreen
class MiuiPermissionService {
  static const _prefKey = 'miui_prompt_shown';
  static const _channel =
      MethodChannel('com.habittracker.alarm/device_info');

  // ── Detection ──────────────────────────────────────────────────────────────

  /// Returns true if the device is a Xiaomi / Redmi / POCO device.
  static Future<bool> get isMiui async {
    if (!Platform.isAndroid) return false;
    try {
      final String? manufacturer =
          await _channel.invokeMethod<String>('getManufacturer');
      final m = manufacturer?.toLowerCase() ?? '';
      return m == 'xiaomi' || m == 'redmi' || m == 'poco';
    } catch (_) {
      return false;
    }
  }

  // ── Prompt logic ───────────────────────────────────────────────────────────

  /// Shows the MIUI setup dialog if this is a Xiaomi device.
  /// Pass [forceShow] = true to always show (e.g. from a settings button).
  static Future<void> showIfNeeded(BuildContext context,
      {bool forceShow = false}) async {
    if (!await isMiui) return;
    if (!forceShow) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefKey) == true) return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MiuiSetupDialog(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  // ── Deep-link openers ──────────────────────────────────────────────────────

  static Future<void> openAutoStart() async {
    try {
      await _channel.invokeMethod('openAutoStart');
    } catch (_) {}
  }

  static Future<void> openBatteryOptimization() async {
    try {
      await _channel.invokeMethod('openBatteryOptimization');
    } catch (_) {}
  }

  static Future<void> openBackgroundPopup() async {
    try {
      await _channel.invokeMethod('openBackgroundPopup');
    } catch (_) {}
  }
}

// =============================================================================
// Dialog UI — exported so it can be opened from a settings button too
// =============================================================================

class MiuiSetupDialog extends StatefulWidget {
  const MiuiSetupDialog({super.key});

  @override
  State<MiuiSetupDialog> createState() => _MiuiSetupDialogState();
}

class _MiuiSetupDialogState extends State<MiuiSetupDialog> {
  final Set<int> _done = {};

  static const _steps = [
    _MiuiStep(
      index: 0,
      icon: Icons.play_circle_outline_rounded,
      label: 'Enable AutoStart',
      detail:
          'Allows Momentum to restart after you swipe it away or reboot your phone.',
    ),
    _MiuiStep(
      index: 1,
      icon: Icons.battery_charging_full_rounded,
      label: 'Remove Battery Restrictions',
      detail:
          'Set to "No restrictions". MIUI freezes alarm timers when it thinks your battery needs saving.',
    ),
    _MiuiStep(
      index: 2,
      icon: Icons.picture_in_picture_alt_rounded,
      label: 'Allow Background Pop-ups',
      detail:
          'Required for the alarm screen to appear over your lock screen when the app is in the background.',
    ),
  ];

  Future<void> _tap(int index) async {
    switch (index) {
      case 0:
        await MiuiPermissionService.openAutoStart();
        break;
      case 1:
        await MiuiPermissionService.openBatteryOptimization();
        break;
      case 2:
        await MiuiPermissionService.openBackgroundPopup();
        break;
    }
    if (mounted) setState(() => _done.add(index));
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFEDE5C8);
    const glow = Color(0xFFB5D96B);
    const bg = Color(0xFF111806);
    const void_ = Color(0xFF0A0F06);

    final allDone = _done.length == _steps.length;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header icon ──────────────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glow.withOpacity(0.15),
                border: Border.all(color: glow.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: glow, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xiaomi / Redmi Setup',
              style: TextStyle(
                  color: cream, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your device blocks background alarms by default. Enable these 3 settings to make alarms reliable — takes about 30 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cream.withOpacity(0.6), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Steps ────────────────────────────────────────────────────────
            ..._steps.map((step) => _StepTile(
                  step: step,
                  isDone: _done.contains(step.index),
                  onTap: () => _tap(step.index),
                )),

            const SizedBox(height: 20),

            // ── CTA button ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      allDone ? glow : glow.withOpacity(0.35),
                  foregroundColor: void_,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  allDone ? 'All done — alarms will work! ✓' : 'Done',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Skip (alarms may not work)',
                style: TextStyle(
                    color: cream.withOpacity(0.35), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiuiStep {
  final int index;
  final IconData icon;
  final String label;
  final String detail;

  const _MiuiStep({
    required this.index,
    required this.icon,
    required this.label,
    required this.detail,
  });
}

class _StepTile extends StatelessWidget {
  final _MiuiStep step;
  final bool isDone;
  final VoidCallback onTap;

  const _StepTile(
      {required this.step, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFEDE5C8);
    const glow = Color(0xFFB5D96B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? glow.withOpacity(0.08) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? glow.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? glow.withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : step.icon,
              color: isDone ? glow : cream.withOpacity(0.6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    color: isDone ? glow : cream,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.detail,
                  style: TextStyle(
                    color: cream.withOpacity(0.45),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isDone)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: glow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: glow.withOpacity(0.35), width: 0.8),
                ),
                child: const Text(
                  'Open →',
                  style: TextStyle(
                    color: glow,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 56),
        ],
      ),
    );
  }
}
