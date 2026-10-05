import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/auth/login_screen.dart';

void main() {
  testWidgets(
    'Primary signed-out screen renders the IsdaLink login flow',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(showBackButton: false),
        ),
      );

      await tester.pump();

      expect(find.text('Sign in to IsdaLink'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    },
  );
}
