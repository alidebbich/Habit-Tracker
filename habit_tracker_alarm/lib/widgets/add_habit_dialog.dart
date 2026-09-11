import 'package:flutter/material.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';

/// Bottom sheet for creating a new habit.
class AddHabitDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const AddHabitDialog({super.key, required this.onSaved});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = '⭐';
  bool _isDaily = true;
  bool _isMorningAnchor = false;
  // index 0=Mon … 6=Sun; stored as Dart weekday 1–7 on save
  final List<bool> _weekdays = List.filled(7, false);

  static const _icons = [
    '⭐', '💧', '🏃', '📖', '🧘', '🍎', '😴', '✍️',
    '🎯', '💪', '🌱', '🎵', '🧠', '💊', '🦷', '☕',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Build weekday list (Dart: 1=Mon … 7=Sun)
    final weekdays = _isDaily
        ? <int>[]
        : [
            for (int i = 0; i < 7; i++)
              if (_weekdays[i]) i + 1
          ];

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: _selectedIcon,
      isDaily: _isDaily,
      weekdays: weekdays,
      isMorningAnchor: _isMorningAnchor,
    );

    await HabitRepository().insertHabit(habit);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
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
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('New Habit',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ---- Name ----
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Drink 8 glasses of water',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            // ---- Icon picker ----
            const Text('Pick an icon',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons
                  .map((icon) => _IconTile(
                        icon: icon,
                        selected: icon == _selectedIcon,
                        onTap: () =>
                            setState(() => _selectedIcon = icon),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // ---- Frequency ----
            const Text('Frequency',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SelectChip(
                    label: 'Every day',
                    selected: _isDaily,
                    onTap: () => setState(() => _isDaily = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SelectChip(
                    label: 'Specific days',
                    selected: !_isDaily,
                    onTap: () => setState(() => _isDaily = false),
                  ),
                ),
              ],
            ),
            if (!_isDaily) ...[
              const SizedBox(height: 12),
              _WeekdayPicker(
                weekdays: _weekdays,
                onChanged: (i, v) => setState(() => _weekdays[i] = v),
              ),
            ],
            const SizedBox(height: 16),

            // ---- Morning anchor toggle ----
            SwitchListTile(
              value: _isMorningAnchor,
              onChanged: (v) => setState(() => _isMorningAnchor = v),
              title: Row(
                children: [
                  Icon(Icons.alarm, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  const Text('Morning anchor',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle:
                  const Text('This habit gates your wake-up alarm'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: cs.surfaceContainerHighest,
              activeThumbColor: cs.primary,
            ),
            const SizedBox(height: 24),

            // ---- Save ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Habit',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _IconTile extends StatelessWidget {
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconTile(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 22))),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  final List<bool> weekdays;
  final void Function(int index, bool value) onChanged;

  const _WeekdayPicker({required this.weekdays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        return GestureDetector(
          onTap: () => onChanged(i, !weekdays[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: weekdays[i] ? cs.primary : cs.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      weekdays[i] ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
