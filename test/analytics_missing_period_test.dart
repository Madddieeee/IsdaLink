import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'analytics_missing_period_cases.dart';
import 'analytics_record_cases.dart' show history, live, validate;

void main() {
  for (final period in AnalyticsPeriod.values) {
    final dynamic engine = const AnalyticsScreen().createState();
    engine.selectedPeriod = period;
    final target = DateTime.utc(2026, 10, 5);
    final cases = analyticsMissingPeriodCases(
      engine: engine,
      target: target,
      monthly: period == AnalyticsPeriod.monthly,
      history: (count, quantity) => List<PeriodPoint>.generate(
        count,
        (index) => PeriodPoint(
          date: engine.shiftAnalyticsPeriod(target, index - count) as DateTime,
          quantity: quantity,
          amount: 0,
        ),
      ),
    );
    for (final entry in cases.entries) {
      test('$period ${entry.key}', entry.value);
    }
  }
  test(
    'zero-fulfilled transactions do not certify zero activity for either role',
    () {
      for (final supplier in [false, true]) {
        expect(
          validate(history()..['quantityFulfilled'] = 0, supplier: supplier),
          isNull,
        );
        expect(
          validate(
            live()..['fulfilledQuantity'] = 0,
            historical: false,
            supplier: supplier,
          ),
          isNull,
        );
      }
    },
  );
}
