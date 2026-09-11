import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

/// Shows a 3-page swipeable intro the first time the app launches.
/// On subsequent launches it skips straight to [HomeScreen].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  static const _pages = [
    _PageData(
      icon: Icons.self_improvement,
      color: Colors.indigo,
      title: 'One streak,\nnot two apps.',
      body:
          'Stop juggling Alarmy and your habit tracker. Morning Routine combines your wake-up alarm with daily habits in one seamless flow.',
    ),
    _PageData(
      icon: Icons.alarm,
      color: Colors.deepPurple,
      title: 'Your alarm is your\nmorning mission.',
      body:
          'The alarm won\'t stop until you\'ve done something real — drink water, stretch, journal a line. Waking up becomes Habit #1.',
    ),
    _PageData(
      icon: Icons.local_fire_department,
      color: Colors.orange,
      title: 'Build streaks that\nactually stick.',
      body:
          'Start with 2–3 habits. Complete your morning mission to auto-check them. Watch your streak grow — one morning at a time.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == i ? Colors.indigo : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Next / Get started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLast
                      ? _finish
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data class & page widget
// ---------------------------------------------------------------------------

class _PageData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _PageData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 64, color: data.color),
          ),
          const SizedBox(height: 48),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            data.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}