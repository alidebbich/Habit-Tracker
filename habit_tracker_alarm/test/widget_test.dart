import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker_alarm/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Just verify the app builds without crashing
    await tester.pumpWidget(const HabitAlarmApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
