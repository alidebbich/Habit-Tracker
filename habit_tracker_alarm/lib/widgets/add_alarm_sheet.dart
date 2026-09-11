import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/alarm_repository.dart';
import '../models/alarm.dart';
import '../models/habit.dart';
import '../services/alarm_service.dart';
import '../services/alarm_audio_service.dart';

class AddAlarmSheet extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback onSaved;
  final Alarm? existingAlarm;
  final VoidCallback? onDelete;

  const AddAlarmSheet({
    super.key,
    required this.habits,
    required this.onSaved,
    this.existingAlarm,
    this.onDelete,
  });

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  late TimeOfDay _time;
  late TextEditingController _labelController;
  late bool _everyday;
  late List<bool> _weekdays;
  late DismissMissionType _missionType;
  String? _linkedHabitId;
  String _sound = 'default';
  bool _isSaving = false;
  bool _isPlayingPreview = false;

  final List<String> _sounds = ['default', 'cinematic_rise', 'gentle_bells', 'digital_beep'];

  @override
  void initState() {
    super.initState();
    final alarm = widget.existingAlarm;
    if (alarm != null) {
      _time = TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute);
      _labelController = TextEditingController(text: alarm.label);
      _everyday = alarm.weekdays.isEmpty;
      _weekdays = List.filled(7, false);
      for (var d in alarm.weekdays) {
        if (d >= 1 && d <= 7) _weekdays[d - 1] = true;
      }
      _missionType = alarm.dismissMissionType;
      _linkedHabitId = alarm.associatedHabitId;
      _sound = alarm.sound;
    } else {
      _time = TimeOfDay.now();
      _labelController = TextEditingController(text: 'Wake Up');
      _everyday = true;
      _weekdays = List.filled(7, false);
      _missionType = DismissMissionType.none;
    }
  }

  @override
  void dispose() {
    AlarmAudioService().stop();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _togglePreview() async {
    if (_isPlayingPreview) {
      await AlarmAudioService().stop();
      if (mounted) setState(() => _isPlayingPreview = false);
    } else {
      setState(() => _isPlayingPreview = true);
      await AlarmAudioService().previewSound(_sound);
    }
  }

  Future<void> _pickCustomSound() async {
    try {
      // FileType.audio opens the native Android music/audio picker,
      // letting the user choose from their full music library, downloads, etc.
      // Use pickFile (single selection) — the recommended v12+ API.
      final picked = await FilePicker.pickFile(type: FileType.audio);

      if (picked != null) {
        if (picked.path == null) return;

        final originalFile = File(picked.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final soundsDir = Directory(p.join(appDir.path, 'alarm_sounds'));
        if (!soundsDir.existsSync()) {
          soundsDir.createSync(recursive: true);
        }

        final fileName = picked.name;
        final targetPath = p.join(soundsDir.path, fileName);

        // Only copy if not already there (avoid re-copying the same file)
        if (!File(targetPath).existsSync()) {
          await originalFile.copy(targetPath);
        }

        await AlarmAudioService().stop();
        if (mounted) {
          setState(() {
            _sound = targetPath;
            _isPlayingPreview = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select audio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await AlarmAudioService().stop();

    try {
      final weekdays = _everyday
          ? <int>[]
          : [
              for (int i = 0; i < 7; i++)
                if (_weekdays[i]) i + 1
            ];

      final now = DateTime.now();
      final alarmTime =
          DateTime(now.year, now.month, now.day, _time.hour, _time.minute);

      final alarm = Alarm(
        id: widget.existingAlarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        time: alarmTime,
        weekdays: weekdays,
        label: _labelController.text.trim().isEmpty ? 'Wake Up' : _labelController.text.trim(),
        dismissMissionType: _missionType,
        associatedHabitId:
            _missionType == DismissMissionType.habitCheck ? _linkedHabitId : null,
        sound: _sound,
      );

      // Step 1: Always save to database first
      if (widget.existingAlarm != null) {
        await AlarmRepository().updateAlarm(alarm);
      } else {
        await AlarmRepository().insertAlarm(alarm);
      }

      // Step 2: Try to schedule — if it fails, the alarm is still saved
      // and will be rescheduled on next app launch
      try {
        await AlarmService().scheduleAlarm(alarm);
      } catch (scheduleError) {
        // Alarm is saved but notification scheduling failed
        // (e.g. permission not yet granted). Show a warning.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '⚠️ Alarm saved, but scheduling failed. Please grant "Alarms & reminders" permission in Settings.',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save alarm: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.existingAlarm != null ? 'Edit Alarm' : 'New Alarm',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Time picker
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: cs.primary),
                    const SizedBox(width: 12),
                    Text(
                      _time.format(context),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Label
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),

            // Sound
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alarm Sound',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (_sound.startsWith('/') || _sound.contains(Platform.pathSeparator))
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      AlarmAudioService().stop();
                      setState(() {
                        _sound = 'default';
                        _isPlayingPreview = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 14, color: Colors.grey),
                    label: const Text('Reset to Default',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_sound.startsWith('/') || _sound.contains(Platform.pathSeparator)) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.music_note, color: cs.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.basename(_sound),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Custom audio from your phone',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isPlayingPreview ? Icons.stop_circle : Icons.play_circle_fill),
                      color: cs.primary,
                      iconSize: 36,
                      tooltip: _isPlayingPreview ? 'Stop preview' : 'Listen to preview',
                      onPressed: _togglePreview,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickCustomSound,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Choose a Different Audio File'),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _sounds.contains(_sound) ? _sound : 'default',
                decoration: InputDecoration(
                  labelText: 'Sound',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                items: _sounds.map((s) {
                  final display = s.replaceAll('_', ' ').capitalize();
                  return DropdownMenuItem(value: s, child: Text(display));
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    AlarmAudioService().stop();
                    setState(() {
                      _sound = v;
                      _isPlayingPreview = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickCustomSound,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 46),
                ),
                icon: Icon(Icons.library_music_outlined, size: 18, color: cs.primary),
                label: const Text('🎵  Pick Song from Music Library'),
              ),
            ],
            const SizedBox(height: 16),

            // Repeat
            const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _SelectChip(
                    label: 'Every day',
                    selected: _everyday,
                    onTap: () => setState(() => _everyday = true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SelectChip(
                    label: 'Specific days',
                    selected: !_everyday,
                    onTap: () => setState(() => _everyday = false)),
              ),
            ]),
            if (!_everyday) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return GestureDetector(
                    onTap: () => setState(() => _weekdays[i] = !_weekdays[i]),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _weekdays[i] ? cs.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _weekdays[i] ? cs.primary : Colors.grey),
                      ),
                      child: Text(days[i],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _weekdays[i] ? cs.onPrimary : Colors.grey,
                          )),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 24),

            // Mission
            const Text('Dismiss Mission',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            DropdownButtonFormField<DismissMissionType>(
              value: _missionType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: const [
                DropdownMenuItem(
                    value: DismissMissionType.none, child: Text('None (Tap)')),
                DropdownMenuItem(
                    value: DismissMissionType.habitCheck,
                    child: Text('Check off a Habit')),
                DropdownMenuItem(
                    value: DismissMissionType.mathProblem,
                    child: Text('Solve Math')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _missionType = v);
              },
            ),
            if (_missionType == DismissMissionType.habitCheck) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _linkedHabitId,
                hint: const Text('Select Habit'),
                decoration: InputDecoration(
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.habits
                    .map((h) => DropdownMenuItem(
                        value: h.id, child: Text('${h.icon} ${h.name}')))
                    .toList(),
                onChanged: (v) => setState(() => _linkedHabitId = v),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Save Alarm',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (widget.existingAlarm != null && widget.onDelete != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: () {
                    widget.onDelete!();
                    Navigator.pop(context);
                  },
                  child: const Text('Delete Alarm',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          border: Border.all(
              color: selected ? cs.primary : Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? cs.onPrimaryContainer : Colors.grey),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
