import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/schedule_repository.dart';
import '../models/schedule_task.dart';
import '../providers/schedule_provider.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage>
    with TickerProviderStateMixin {
  bool _isToday = true;
  late AnimationController _glowController;

  static const _kBrand = Color(0xFF8DB843);
  static const _kVoid = Color(0xFF0A0F06);
  static const _kCard = Color(0xFF1E2B0F);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  DateTime get _targetDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _isToday ? today : today.add(const Duration(days: 1));
  }

  void _switchDay(bool isToday) {
    setState(() => _isToday = isToday);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDateProvider.notifier).setDate(_targetDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cur = ref.read(selectedDateProvider);
      if (cur != _targetDate) {
        ref.read(selectedDateProvider.notifier).setDate(_targetDate);
      }
    });

    final tasks = ref.watch(scheduleProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: _kVoid,
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -100,
            left: -60,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Opacity(
                opacity: 0.08 + _glowController.value * 0.06,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBrand,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(now),
                const SizedBox(height: 20),
                _buildDayToggle(),
                const SizedBox(height: 24),
                Expanded(
                  child: tasks.when(
                    data: (list) => _buildTimeline(list, now),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
                const SizedBox(height: 100), // nav bar clearance
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTaskSheet(context),
          backgroundColor: _kBrand,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: Text('Add Block', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime now) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final displayDate = _isToday ? now : now.add(const Duration(days: 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isToday ? 'Today' : 'Tomorrow',
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
          const SizedBox(height: 4),
          Text(
            '${weekdays[displayDate.weekday - 1]}, ${months[displayDate.month - 1]} ${displayDate.day}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _kBrand,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildDayToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                _ToggleChip(label: 'Today', isSelected: _isToday, onTap: () => _switchDay(true)),
                _ToggleChip(label: 'Tomorrow', isSelected: !_isToday, onTap: () => _switchDay(false)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.1);
  }

  Widget _buildTimeline(List<ScheduleTask> tasks, DateTime now) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        final isActive = _isToday &&
            now.isAfter(task.startTime) &&
            now.isBefore(task.endTime);
        final isDone = task.isCompleted;
        final isPast = _isToday && now.isAfter(task.endTime) && !isDone;

        return _TimelineItem(
          task: task,
          index: i,
          isFirst: i == 0,
          isLast: i == tasks.length - 1,
          isActive: isActive,
          isDone: isDone,
          isPast: isPast,
          glowAnimation: _glowController,
          onToggle: () => _toggleTask(task),
          onEdit: () => _showAddTaskSheet(context, existing: task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowController,                                                 
            builder: (_, child) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCard,
                boxShadow: [
                  BoxShadow(
                    color: _kBrand.withValues(alpha: 0.1 + _glowController.value * 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: _kBrand.withValues(alpha: 0.2 + _glowController.value * 0.2),
                ),
              ),
              child: const Icon(Icons.event_note_outlined, color: Color(0xFF5E7A34), size: 36),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No time blocks yet',
            style: GoogleFonts.fraunces(fontSize: 22, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Plan your ${_isToday ? "day" : "tomorrow"}\nby adding time blocks below.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38, height: 1.6),
          ),
        ],
      ).animate().fade(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Future<void> _toggleTask(ScheduleTask task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await ref.read(scheduleRepositoryProvider).updateTask(updated);
    ref.invalidate(scheduleProvider);
  }

  Future<void> _deleteTask(ScheduleTask task) async {
    await ref.read(scheduleRepositoryProvider).deleteTask(task.id);
    ref.invalidate(scheduleProvider);
  }

  Future<void> _showAddTaskSheet(BuildContext context, {ScheduleTask? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTaskSheet(
        existing: existing,
        targetDate: _targetDate,
        onSaved: (task) async {
          if (existing != null) {
            await ref.read(scheduleRepositoryProvider).updateTask(task);
          } else {
            await ref.read(scheduleRepositoryProvider).insertTask(task);
          }
          ref.invalidate(scheduleProvider);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline Item
// ─────────────────────────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.task,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.isActive,
    required this.isDone,
    required this.isPast,
    required this.glowAnimation,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleTask task;
  final int index;
  final bool isFirst, isLast, isActive, isDone, isPast;
  final AnimationController glowAnimation;
  final VoidCallback onToggle, onEdit, onDelete;

  static const _kBrand = Color(0xFF8DB843);

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone
        ? _kBrand
        : isActive
            ? _kBrand
            : isPast
                ? Colors.white12
                : const Color(0xFF3D5220);

    final lineColor = isDone || isPast ? Colors.white12 : const Color(0xFF253315);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline line + dot ──
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Top line
                if (!isFirst)
                  Positioned(
                    top: 0,
                    left: 15,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: lineColor,
                    ),
                  ),
                // Bottom line
                if (!isLast)
                  Positioned(
                    top: 20,
                    left: 15,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
                // Glow dot
                Positioned(
                  top: 12,
                  child: AnimatedBuilder(
                    animation: glowAnimation,
                    builder: (_, __) => Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: isActive || isDone
                            ? [
                                BoxShadow(
                                  color: _kBrand.withValues(alpha: isActive ? 0.3 + glowAnimation.value * 0.4 : 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                        border: Border.all(
                          color: isDone ? _kBrand : Colors.white.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 8, color: Colors.black)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Card ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCard(context),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (80 * index).ms).slideX(begin: 0.15);
  }

  Widget _buildCard(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1E2B0F).withValues(alpha: 0.95)
              : isDone
                  ? Colors.white.withValues(alpha: 0.02)
                  : const Color(0xFF111706),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? _kBrand.withValues(alpha: 0.4)
                : isDone
                    ? _kBrand.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _kBrand.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _kBrand.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_fmt(task.startTime)} – ${_fmt(task.endTime)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? _kBrand : Colors.white38,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kBrand.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '● NOW',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _kBrand,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Edit / delete
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.3), size: 20),
                  color: const Color(0xFF1E2B0F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: Colors.white70), SizedBox(width: 10), Text('Edit', style: TextStyle(color: Colors.white70))])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.redAccent), SizedBox(width: 10), Text('Delete', style: TextStyle(color: Colors.redAccent))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDone ? Colors.white30 : Colors.white,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white30,
              ),
            ),
            if (task.note != null && task.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.note!,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white38, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? "PM" : "AM"}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final ScheduleTask? existing;
  final DateTime targetDate;
  final Future<void> Function(ScheduleTask task) onSaved;

  const _AddTaskSheet({
    required this.targetDate,
    required this.onSaved,
    this.existing,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late TimeOfDay _start;
  late TimeOfDay _end;

  static const _kBrand = Color(0xFF8DB843);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _start = e != null ? TimeOfDay(hour: e.startTime.hour, minute: e.startTime.minute) : TimeOfDay.now();
    _end = e != null
        ? TimeOfDay(hour: e.endTime.hour, minute: e.endTime.minute)
        : TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final d = widget.targetDate;
    final task = ScheduleTask(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      startTime: DateTime(d.year, d.month, d.day, _start.hour, _start.minute),
      endTime: DateTime(d.year, d.month, d.day, _end.hour, _end.minute),
      date: d,
      isCompleted: widget.existing?.isCompleted ?? false,
    );
    await widget.onSaved(task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF111706).withValues(alpha: 0.95),
              border: Border(top: BorderSide(color: _kBrand.withValues(alpha: 0.15))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  widget.existing != null ? 'Edit Time Block' : 'New Time Block',
                  style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                _field(controller: _titleCtrl, hint: 'What will you do?', icon: Icons.edit_note),
                const SizedBox(height: 12),
                _field(controller: _noteCtrl, hint: 'Notes (optional)', icon: Icons.notes),
                const SizedBox(height: 20),
                // Time row
                Row(children: [
                  Expanded(
                    child: _timePicker(
                      label: 'Start',
                      time: _start,
                      onTap: () async {
                        final p = await showTimePicker(context: context, initialTime: _start);
                        if (p != null) setState(() => _start = p);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timePicker(
                      label: 'End',
                      time: _end,
                      onTap: () async {
                        final p = await showTimePicker(context: context, initialTime: _end);
                        if (p != null) setState(() => _end = p);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kBrand,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      widget.existing != null ? 'Save Changes' : 'Add Block',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String hint, required IconData icon}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF5E7A34), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBrand, width: 1.5),
        ),
      ),
    );
  }

  Widget _timePicker({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _kBrand),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle Chip
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _kBrand = Color(0xFF8DB843);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _kBrand : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
