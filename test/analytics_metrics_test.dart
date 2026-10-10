import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'analytics_metrics_cases.dart';

void main() {
  for (final entry in analyticsMetricsCases.entries) {
    test(entry.key, entry.value);
  }
  testWidgets('valid zero CV displays 0.0%, not unavailable', (tester) async {
    final dynamic engine = const AnalyticsScreen().createState();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              engine.variabilityPanel(engine.variability(<double>[10, 10]))
                  as Widget,
        ),
      ),
    );
    expect(find.text('0.0%'), findsOneWidget);
    expect(find.text('CV unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('undefined CV displays unavailable', (tester) async {
    final dynamic engine = const AnalyticsScreen().createState();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              engine.variabilityPanel(engine.variability(<double>[0, 0]))
                  as Widget,
        ),
      ),
    );
    expect(find.text('--'), findsOneWidget);
    expect(find.text('CV unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large CV has neutral wording', (tester) async {
    final dynamic engine = const AnalyticsScreen().createState();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: engine.variabilityPanel(100.0) as Widget),
      ),
    );
    expect(find.text('100.0%'), findsOneWidget);
    expect(find.text('Coefficient of variation'), findsOneWidget);
    expect(find.textContaining('High variability'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large MAPE and one pair retain neutral evaluation note', (
    tester,
  ) async {
    final dynamic engine = const AnalyticsScreen().createState();
    final evaluation = evaluateObservations([
      ForecastObservation(
        target: DateTime.utc(2026, 1),
        actual: 10,
        forecast: 1000,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              engine.forecastReliabilityNote(evaluation: evaluation) as Widget,
        ),
      ),
    );
    expect(find.text('Historical evaluation'), findsOneWidget);
    expect(find.textContaining('1 nonzero-actual'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.textContaining('Low forecast accuracy'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
