import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/glass_card.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await HabitRepository().getHabits();
    if (mounted) {
      setState(() {
        _habits = habits;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHabit(Habit habit) async {
    final updated = habit.toggleCompletion(DateTime.now());
    await HabitRepository().updateHabit(updated);
    _loadHabits();
  }

  Future<void> _deleteHabit(Habit habit) async {
    await HabitRepository().deleteHabit(habit.id);
    _loadHabits();
  }

  Future<void> _showAddHabitSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddHabitDialog(onSaved: _loadHabits),
    );
  }

  // ---------------------------------------------------------------------------
  // Computed helpers
  // ---------------------------------------------------------------------------

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }

  String _formattedDate() {
    final d = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  List<Habit> get _todayHabits {
    final today = DateTime.now().weekday; // 1=Mon … 7=Sun
    return _habits.where((h) {
      if (h.isDaily || h.weekdays.isEmpty) return true;
      return h.weekdays.contains(today);
    }).toList();
  }

  int get _completedCount =>
      _todayHabits.where((h) => h.isCompletedOn(DateTime.now())).length;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ---- Hero header ----
                SliverAppBar(
                  expandedHeight: 170,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cs.primary, cs.tertiary],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _greeting(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formattedDate(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (_todayHabits.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '$_completedCount / ${_todayHabits.length} habits done',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ---- Progress bar ----
                if (_todayHabits.isNotEmpty)
                  SliverToBoxAdapter(child: _buildProgressBar(cs)),

                // ---- Habit list or empty state ----
                if (_todayHabits.isNotEmpty)
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final habit = _todayHabits[i];
                          return _HabitCard(
                            key: ValueKey(habit.id),
                            habit: habit,
                            onToggle: () => _toggleHabit(habit),
                            onDelete: () => _deleteHabit(habit),
                          ).animate().fadeIn(delay: (50 * i).ms).slideX(begin: 0.1);
                        },
                        childCount: _todayHabits.length,
                      ),
                    ),
                  )
                else
                  SliverFillRemaining(child: _buildEmptyState()),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: _showAddHabitSheet,
          icon: const Icon(Icons.add),
          label: const Text('Add Habit'),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme cs) {
    final total = _todayHabits.length;
    final done = _completedCount;
    final progress = total == 0 ? 0.0 : done / total;
    final allDone = done == total && total > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? Colors.green : cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text('No habits yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Start with 2–3 small habits.\nConsistency beats perfection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: Colors.grey[500], height: 1.6),
            ),
          ],
        ).animate().fade(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit card widget
// ---------------------------------------------------------------------------

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = habit.isCompletedOn(DateTime.now());
    final streak = habit.getCurrentStreak();

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Habit'),
          content:
              Text('Delete "${habit.name}"? Your streak will be lost.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete')),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GlassCard(
        margin: const EdgeInsets.symmetric(vertical: 6),
        opacity: isDone ? 0.08 : 0.03,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? cs.primary : Colors.transparent,
                border: Border.all(
                  color: isDone ? cs.primary : Colors.white30,
                  width: 2,
                ),
              ),
              child: isDone
                  ? Icon(Icons.check, color: cs.onPrimary, size: 22)
                  : Center(
                      child: Text(habit.icon,
                          style: const TextStyle(fontSize: 20))),
            ),
          ),
          title: Text(
            habit.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration:
                  isDone ? TextDecoration.lineThrough : null,
              color:
                  isDone ? cs.onSurface.withOpacity(0.45) : Colors.white,
            ),
          ),
          subtitle: Row(
            children: [
              if (habit.isMorningAnchor) ...[
                Icon(Icons.alarm, size: 12, color: cs.primary),
                const SizedBox(width: 3),
                Text('Alarm anchor  ',
                    style: TextStyle(fontSize: 11, color: cs.primary)),
              ],
              if (streak > 0) ...[
                const Text('🔥', style: TextStyle(fontSize: 11)),
                Text(' $streak day streak',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange[700])),
              ],
            ],
          ),
          trailing: isDone
              ? Icon(Icons.check_circle, color: cs.primary)
              : null,
        ),
      ),
    );
  }
}
