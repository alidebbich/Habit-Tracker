import 'dart:math';

import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/alarm_audio_service.dart';

/// Full-screen alarm dismiss screen.
///
/// Shown when the user taps the alarm notification.
/// The alarm cannot be dismissed until the required mission is completed.
/// Supports: none (simple tap), math problem, typing challenge, habit check.
class AlarmDismissScreen extends StatefulWidget {
  final Alarm alarm;

  const AlarmDismissScreen({super.key, required this.alarm});

  @override
  State<AlarmDismissScreen> createState() => _AlarmDismissScreenState();
}

class _AlarmDismissScreenState extends State<AlarmDismissScreen>
    with SingleTickerProviderStateMixin {
  // ---- Pulse animation ----
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  // ---- Math mission state ----
  late final int _mathA;
  late final int _mathB;
  late final int _mathAnswer;
  final TextEditingController _mathCtrl = TextEditingController();
  String _mathError = '';

  // ---- Typing mission state ----
  static const _typingPhrase = 'I am awake and ready for the day';
  final TextEditingController _typeCtrl = TextEditingController();
  String _typeError = '';

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the alarm icon
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    // Generate math problem once
    final rng = Random();
    _mathA = rng.nextInt(20) + 5;
    _mathB = rng.nextInt(20) + 5;
    _mathAnswer = _mathA + _mathB;

    // Start playing alarm audio (including custom downloaded MP3/WAV files)
    AlarmAudioService().playAlarmSound(widget.alarm.sound);
  }

  @override
  void dispose() {
    AlarmAudioService().stop();
    _pulse.dispose();
    _mathCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Dismiss logic
  // ---------------------------------------------------------------------------

  Future<void> _dismiss() async {
    if (_dismissed) return;
    setState(() => _dismissed = true);
    await AlarmAudioService().stop();
    // Auto-check linked habit and cancel the scheduled notification
    await AlarmService().completeHabitMission(widget.alarm);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submitMath() async {
    final answer = int.tryParse(_mathCtrl.text.trim());
    if (answer == _mathAnswer) {
      await _dismiss();
    } else {
      setState(() {
        _mathError = 'Wrong — try again!';
        _mathCtrl.clear();
      });
    }
  }

  Future<void> _submitTyping() async {
    if (_typeCtrl.text.trim() == _typingPhrase) {
      await _dismiss();
    } else {
      setState(() => _typeError = 'Not quite — type it exactly!');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back button dismissing the alarm without completing the mission
      canPop: widget.alarm.dismissMissionType == DismissMissionType.none,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1240), // deep indigo
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              children: [
                const Spacer(),

                // ---- Pulsing alarm icon ----
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 2),
                    ),
                    child: const Icon(Icons.alarm,
                        size: 68, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),

                // ---- Alarm label ----
                Text(
                  widget.alarm.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  _missionInstruction(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // ---- Mission widget ----
                _buildMission(),

                const Spacer(),

                // Simple dismiss when no mission
                if (widget.alarm.dismissMissionType ==
                    DismissMissionType.none)
                  _bigButton(
                    label: 'Dismiss Alarm',
                    onPressed: _dismiss,
                    color: Colors.white,
                    textColor: const Color(0xFF1A1240),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _missionInstruction() {
    switch (widget.alarm.dismissMissionType) {
      case DismissMissionType.habitCheck:
        return 'Tap Done below to log your morning habit\nand dismiss the alarm.';
      case DismissMissionType.mathProblem:
        return 'Solve the math problem to stop the alarm.';
      case DismissMissionType.typingChallenge:
        return 'Type the exact phrase below to dismiss.';
      default:
        return 'Tap the button below to dismiss your alarm.';
    }
  }

  Widget _buildMission() {
    switch (widget.alarm.dismissMissionType) {
      case DismissMissionType.mathProblem:
        return _mathMission();
      case DismissMissionType.typingChallenge:
        return _typingMission();
      case DismissMissionType.habitCheck:
        return _habitCheckMission();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- Math ----
  Widget _mathMission() {
    return Column(
      children: [
        Text(
          '$_mathA + $_mathB = ?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _styledTextField(
          controller: _mathCtrl,
          hint: 'Your answer',
          keyboardType: TextInputType.number,
          errorText: _mathError.isEmpty ? null : _mathError,
        ),
        const SizedBox(height: 16),
        _bigButton(
          label: 'Submit',
          onPressed: _submitMath,
          color: Colors.white,
          textColor: const Color(0xFF1A1240),
        ),
      ],
    );
  }

  // ---- Typing ----
  Widget _typingMission() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '"$_typingPhrase"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _styledTextField(
          controller: _typeCtrl,
          hint: 'Type the phrase above',
          errorText: _typeError.isEmpty ? null : _typeError,
        ),
        const SizedBox(height: 16),
        _bigButton(
          label: 'Submit',
          onPressed: _submitTyping,
          color: Colors.white,
          textColor: const Color(0xFF1A1240),
        ),
      ],
    );
  }

  // ---- Habit check ----
  Widget _habitCheckMission() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 52),
              SizedBox(height: 12),
              Text(
                'Complete your morning habit to dismiss the alarm',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _bigButton(
          label: '✓  Done — Dismiss Alarm',
          onPressed: _dismiss,
          color: Colors.green,
          textColor: Colors.white,
        ),
      ],
    );
  }

  // ---- Shared styled text field ----
  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 22),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.orangeAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orangeAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orangeAccent),
        ),
      ),
    );
  }

  // ---- Shared big button ----
  Widget _bigButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _dismissed ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}