import 'package:flutter/material.dart';

import 'today_page.dart';
import 'alarms_page.dart';
import 'schedule_page.dart';
import 'stats_screen.dart';
import '../widgets/glass_card.dart';

/// Shell that owns the bottom navigation bar and switches between the
/// three main pages via an [IndexedStack] (keeps page state alive).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    TodayPage(),
    SchedulePage(),
    AlarmsPage(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(100),
              opacity: 0.15,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.today,
                    label: 'Habits',
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _NavItem(
                    icon: Icons.view_timeline_outlined,
                    label: 'Schedule',
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  _NavItem(
                    icon: Icons.alarm,
                    label: 'Alarms',
                    isSelected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  _NavItem(
                    icon: Icons.bar_chart,
                    label: 'Stats',
                    isSelected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? cs.primary : Colors.white54,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
