import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'analytics_parameter_cases.dart';

void main() {
  for (final entry in analyticsParameterCases.entries) {
    test(entry.key, entry.value);
  }
  for (final period in AnalyticsPeriod.values) {
    // Invoke actual screen calculation methods without mounting Firestore UI.
    final dynamic engine = const AnalyticsScreen().createState();
    engine.selectedPeriod = period;
    final monthly = period == AnalyticsPeriod.monthly;
    final target = DateTime.utc(2026, 10, 5);
    List<PeriodPoint> history(int count) => List.generate(count, (index) {
      final offset = count - index;
      return PeriodPoint(
        date: engine.shiftAnalyticsPeriod(target, -offset) as DateTime,
        quantity: offset.toDouble(),
        amount: 0,
      );
    });
    test('$period SMA uses exactly the preceding window', () {
      final result =
          engine.simpleMovingAverageForTarget(
                precedingPoints: history(30),
                targetDate: target,
              )
              as ForecastResult;
      expect(result.hasValue, isTrue);
      expect(result.value, monthly ? 2.0 : 2.5);
    });
    test('$period Seasonal averages configured offsets only', () {
      final result =
          engine.seasonalMovingAverageForTarget(
                precedingPoints: history(30),
                targetDate: target,
              )
              as ForecastResult;
      expect(result.hasValue, isTrue);
      expect(result.value, monthly ? 18.0 : 8.0);
    });
    test('$period Seasonal rejects one period below minimum coverage', () {
      final result =
          engine.seasonalMovingAverageForTarget(
                precedingPoints: history(monthly ? 23 : 11),
                targetDate: target,
              )
              as ForecastResult;
      expect(result.hasValue, isFalse);
    });
    test('$period Seasonal requires intervening non-lag periods too', () {
      final points = history(monthly ? 24 : 12)
        ..removeWhere((p) => p.date == engine.shiftAnalyticsPeriod(target, -2));
      final result =
          engine.seasonalMovingAverageForTarget(
                precedingPoints: points,
                targetDate: target,
              )
              as ForecastResult;
      expect(result.hasValue, isFalse);
    });
    test('$period SMA rejects missing immediate preceding period', () {
      final points = history(30)..removeLast();
      final result =
          engine.simpleMovingAverageForTarget(
                precedingPoints: points,
                targetDate: target,
              )
              as ForecastResult;
      expect(result.hasValue, isFalse);
    });
  }
}
