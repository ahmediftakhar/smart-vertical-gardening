import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_vertical_gardening/main.dart'; // Adjust path if needed

void main() {
  testWidgets('Smart Vertical Gardening app shows splash screen correctly',
      (WidgetTester tester) async {
    // 🧪 Render the main app which should load the splash screen by default
    await tester.pumpWidget(const SmartVerticalGardeningApp());

    // ⏱ Allow time for splash animations/layouts to build
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // ✅ App structure check
    expect(find.byType(MaterialApp, skipOffstage: false), findsOneWidget);

    // ✅ Splash screen elements
    expect(find.text('Smart Vertical Gardening'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
