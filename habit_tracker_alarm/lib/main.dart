import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'data/alarm_repository.dart';
import 'services/alarm_service.dart';
import 'screens/alarm_dismiss_screen.dart';
import 'screens/splash_screen.dart';

/// Global navigator key so AlarmService can push screens without a BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data — required by flutter_local_notifications.
  // Fall back to UTC if device timezone cannot be detected.
  tz.initializeTimeZones();
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
  } catch (e) {
    debugPrint('Timezone detection failed, falling back to UTC: $e');
    tz.setLocalLocation(tz.UTC);
  }

  final alarmService = AlarmService();
  await alarmService.init();

  // When a notification is tapped, look up the alarm and show dismiss screen
  alarmService.onAlarmFired = (String alarmId) async {
    final alarms = await AlarmRepository().getAlarms();
    final matches = alarms.where((a) => a.id == alarmId).toList();
    if (matches.isEmpty) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AlarmDismissScreen(alarm: matches.first),
        fullscreenDialog: true,
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: HabitAlarmApp(),
    ),
  );
}

class HabitAlarmApp extends StatelessWidget {
  const HabitAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color voidColor = Color(0xFF0A0F06);
    const Color creamColor = Color(0xFFEDE5C8);
    const Color glowColor = Color(0xFFB5D96B);

    final TextTheme baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: creamColor,
      displayColor: creamColor,
    );

    final TextTheme textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.fraunces(
        textStyle: baseTextTheme.displayLarge,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.fraunces(
        textStyle: baseTextTheme.displayMedium,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.fraunces(
        textStyle: baseTextTheme.displaySmall,
        fontWeight: FontWeight.w800,
      ),
    );

    return MaterialApp(
      title: 'Momentum',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: voidColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: glowColor,
          brightness: Brightness.dark,
          surface: voidColor,
          onSurface: creamColor,
          primary: glowColor,
        ),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}