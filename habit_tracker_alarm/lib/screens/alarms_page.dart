import 'package:flutter/material.dart';

import '../data/alarm_repository.dart';
import '../data/habit_repository.dart';
import '../models/alarm.dart';
import '../models/habit.dart';
import '../services/alarm_service.dart';
import '../widgets/add_alarm_sheet.dart';
import '../widgets/glass_card.dart';

// =============================================================================
// AlarmsPage — list of saved alarms with enable/disable toggle
// =============================================================================

class AlarmsPage extends StatefulWidget {
  const AlarmsPage({super.key});

  @override
  State<AlarmsPage> createState() => _AlarmsPageState();
}

class _AlarmsPageState extends State<AlarmsPage> {
  List<Alarm> _alarms = [];
  List<Habit> _habits = [];
  bool _isLoading = true;
  bool _exactAlarmOk = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alarms = await AlarmRepository().getAlarms();
    final habits = await HabitRepository().getHabits();
    // Check permissions in parallel with loading data
    final exact = await AlarmService().canScheduleExactAlarms();
    if (mounted) {
      setState(() {
        _alarms = alarms;
        _habits = habits;
        _isLoading = false;
        _exactAlarmOk = exact;
      });
    }
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await AlarmRepository().updateAlarm(updated);
    if (updated.isEnabled) {
      await AlarmService().scheduleAlarm(updated);
    } else {
      await AlarmService().cancelAlarm(updated.id);
    }
    _load();
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    await AlarmService().cancelAlarm(alarm.id);
    await AlarmRepository().deleteAlarm(alarm.id);
    _load();
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatWeekdays(List<int> weekdays) {
    if (weekdays.isEmpty) return 'Every day';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays.map((d) => names[d - 1]).join(', ');
  }

  String _missionLabel(DismissMissionType t) {
    switch (t) {
      case DismissMissionType.habitCheck:
        return '🔗 Habit check';
      case DismissMissionType.mathProblem:
        return '🔢 Math problem';
      case DismissMissionType.typingChallenge:
        return '⌨️ Typing challenge';
      case DismissMissionType.shakePhone:
        return '📳 Shake to dismiss';
      case DismissMissionType.photoCapture:
        return '📷 Photo capture';
      case DismissMissionType.barcodeScan:
        return '📦 Barcode scan';
      case DismissMissionType.none:
        return '';
    }
  }

  String _soundLabel(String sound) {
    if (sound.startsWith('/') || sound.contains('/') || sound.contains('\\')) {
      final name = sound.split(RegExp(r'[/\\]')).last;
      return name;
    }
    if (sound == 'default') return 'Default sound';
    return sound.replaceAll('_', ' ');
  }

  Future<void> _showAddSheet([Alarm? existing]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAlarmSheet(
        habits: _habits, 
        onSaved: _load,
        existingAlarm: existing,
        onDelete: existing != null ? () => _deleteAlarm(existing) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Permission banners ──────────────────────────────────
                if (!_exactAlarmOk)
                  _PermissionBanner(
                    icon: Icons.alarm,
                    message:
                        'Exact alarms not granted — your alarm may fire late.',
                    actionLabel: 'Fix',
                    onTap: () async {
                      await AlarmService().requestExactAlarmPermission();
                      _load();
                    },
                  ),
                // ── Alarm list ──────────────────────────────────────────
                Expanded(
                  child: _alarms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm_off,
                                  size: 72, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('No alarms set',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text('Tap + to set your first morning alarm',
                                  style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  itemCount: _alarms.length,
                  itemBuilder: (_, i) {
                    final alarm = _alarms[i];
                    final linked = alarm.associatedHabitId != null
                        ? _habits
                            .where((h) => h.id == alarm.associatedHabitId)
                            .firstOrNull
                        : null;

                    return Dismissible(
                      key: Key(alarm.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteAlarm(alarm),
                      child: GlassCard(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        opacity: alarm.isEnabled ? 0.08 : 0.03,
                        onTap: () => _showAddSheet(alarm),
                        child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTime(alarm.time),
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: alarm.isEnabled
                                            ? cs.onSurface
                                            : cs.onSurface.withOpacity(0.35),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(alarm.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface.withOpacity(0.7),
                                        )),
                                    Text(
                                      _formatWeekdays(alarm.weekdays),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              cs.onSurface.withOpacity(0.45)),
                                    ),
                                    if (linked != null) ...[
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        Icon(Icons.link,
                                            size: 13, color: cs.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${linked.icon} ${linked.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ]),
                                    ],
                                    if (alarm.dismissMissionType !=
                                        DismissMissionType.none) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _missionLabel(
                                            alarm.dismissMissionType),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[700]),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.music_note,
                                            size: 13,
                                            color: cs.onSurface.withValues(alpha: 0.5)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _soundLabel(alarm.sound),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurface.withValues(alpha: 0.5),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Explicit Edit button
                                  IconButton(
                                    onPressed: () => _showAddSheet(alarm),
                                    icon: Icon(Icons.edit_outlined,
                                        color: cs.primary.withValues(alpha: 0.8)),
                                    tooltip: 'Edit',
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  ),
                                  // Explicit Delete button
                                  IconButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E2B0F),
                                          title: const Text('Delete Alarm', style: TextStyle(color: Colors.white)),
                                          content: Text('Delete "${alarm.label}"?', style: const TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) _deleteAlarm(alarm);
                                    },
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Delete',
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  ),
                                  // Toggle
                                  Switch(
                                    value: alarm.isEnabled,
                                    onChanged: (_) => _toggleAlarm(alarm),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ),
                    );
                  },
                  ),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: _showAddSheet,
          icon: const Icon(Icons.alarm_add),
          label: const Text('Add Alarm'),
        ),
      ),
    );
  }
}

// =============================================================================
// Permission banner — shown at the top of the Alarms page when a critical
// permission is missing. Tapping "Fix" opens the relevant system settings.
// =============================================================================

class _PermissionBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  const _PermissionBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.6)),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

