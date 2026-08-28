import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/welcome_screen.dart';

void main() {
  testWidgets(
    'Welcome screen renders without Firebase services',
    (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      await tester.pump();

      expect(
        find.text('IsdaLink'),
        findsOneWidget,
      );
      expect(
        find.text('Tap anywhere to continue'),
        findsOneWidget,
      );
    },
  );
}
