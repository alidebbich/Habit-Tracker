import 'package:flutter/material.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';

/// Stats page — per-habit streak stats + 35-day calendar heatmap
/// + all-habits overview list.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Habit> _habits = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await HabitRepository().getHabits();
    if (mounted) {
      setState(() {
        _habits = habits;
        _isLoading = false;
        // Guard index in case habits list shrank
        if (_selectedIndex >= habits.length) _selectedIndex = 0;
      });
    }
  }

  Habit? get _selected =>
      _habits.isEmpty ? null : _habits[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? _buildEmpty()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHabitSelector(),
                      const SizedBox(height: 20),
                      _buildStreakCards(),
                      const SizedBox(height: 24),
                      _buildCalendarSection(),
                      const SizedBox(height: 28),
                      _buildAllHabitsOverview(),
                    ],
                  ),
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // Habit chip selector
  // ---------------------------------------------------------------------------

  Widget _buildHabitSelector() {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _habits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final h = _habits[i];
          final selected = i == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${h.icon} ${h.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stat cards row
  // ---------------------------------------------------------------------------

  Widget _buildStreakCards() {
    final h = _selected;
    if (h == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            color: Colors.orange,
            value: '${h.getCurrentStreak()}',
            unit: 'days',
            label: 'Current Streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            color: Colors.amber,
            value: '${h.getBestStreak()}',
            unit: 'days',
            label: 'Best Streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.pie_chart_outline,
            color: Colors.green,
            value: h.getCompletionPercentage().toStringAsFixed(0),
            unit: '%',
            label: '30-Day Rate',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 35-day heatmap
  // ---------------------------------------------------------------------------

  Widget _buildCalendarSection() {
    final h = _selected;
    if (h == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('35-Day Calendar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _CalendarHeatmap(habit: h),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // All habits summary
  // ---------------------------------------------------------------------------

  Widget _buildAllHabitsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('All Habits',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._habits.map((h) => _HabitOverviewRow(habit: h)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No habits yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Add habits on the Today tab to see stats here',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 11, color: color.withOpacity(0.75))),
              ),
            ],
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 35-cell heatmap built with a plain GridView — no fl_chart dependency needed
// ---------------------------------------------------------------------------

class _CalendarHeatmap extends StatelessWidget {
  final Habit habit;

  const _CalendarHeatmap({required this.habit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // Build 35 days ending today
    final cells = List.generate(35, (i) {
      final date = now.subtract(Duration(days: 34 - i));
      final key = DateTime(date.year, date.month, date.day);
      final done = habit.completedDates.contains(key);
      final isToday = key == DateTime(now.year, now.month, now.day);
      return (done: done, isToday: isToday);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day-of-week header
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.4))),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: cells.length,
          itemBuilder: (_, i) {
            final cell = cells[i];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: cell.done ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: cell.isToday
                    ? Border.all(color: cs.primary, width: 2)
                    : null,
              ),
              child: cell.done
                  ? Icon(Icons.check, size: 11, color: cs.onPrimary)
                  : null,
            );
          },
        ),
        const SizedBox(height: 10),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _LegendDot(color: cs.surfaceContainerHighest, label: 'Missed'),
            const SizedBox(width: 12),
            _LegendDot(color: cs.primary, label: 'Done'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Per-habit row in the overview
// ---------------------------------------------------------------------------

class _HabitOverviewRow extends StatelessWidget {
  final Habit habit;

  const _HabitOverviewRow({required this.habit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = habit.getCompletionPercentage() / 100;
    final streak = habit.getCurrentStreak();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(habit.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('🔥 $streak',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
