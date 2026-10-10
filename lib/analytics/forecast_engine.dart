import 'analytics_calendar.dart';
import 'forecast_comparison.dart';
import 'forecast_parameters.dart';

class PeriodPoint {
  const PeriodPoint({
    this.hasCompleteAmounts = true,
    required this.date,
    required this.quantity,
    required this.amount,
    this.transactionCount = 0,
  });

  final DateTime date;
  final double quantity;
  final bool hasCompleteAmounts;
  final double amount;
  final int transactionCount;
}

/// Calculations shared by the UI and regression tests. Inputs are one
/// account/product/unit series of closed, chronological calendar periods.
/// Missing periods stay absent; raw decimal quantities remain unchanged.
mixin AnalyticsForecastEngine {
  bool get forecastMonthly;
  DateTime periodStart(DateTime date) =>
      analyticsPeriodStart(date, monthly: forecastMonthly);
  AnalyticsForecastParameters get forecastParameters => !forecastMonthly
      ? AnalyticsForecastParameters.weekly
      : AnalyticsForecastParameters.monthly;

  int get smaWindow => forecastParameters.smaWindow;

  int get seasonalInterval => forecastParameters.seasonalInterval;

  int get seasonalComparablePeriods =>
      forecastParameters.seasonalComparablePeriods;

  int get seasonalMinimumPrecedingPeriods =>
      forecastParameters.seasonalMinimumPrecedingPeriods;

  String get periodName {
    return !forecastMonthly ? 'weekly' : 'monthly';
  }

  DateTime shiftAnalyticsPeriod(DateTime date, int offset) {
    final start = periodStart(date);

    if (forecastMonthly) {
      return DateTime.utc(start.year, start.month + offset);
    }

    return start.add(Duration(days: 7 * offset));
  }

  bool sameAnalyticsPeriod(DateTime left, DateTime right) {
    final leftStart = periodStart(left);
    final rightStart = periodStart(right);

    return leftStart.year == rightStart.year &&
        leftStart.month == rightStart.month &&
        leftStart.day == rightStart.day;
  }

  PeriodPoint? pointForAnalyticsPeriod(
    List<PeriodPoint> points,
    DateTime targetDate,
  ) {
    for (final point in points) {
      if (sameAnalyticsPeriod(point.date, targetDate)) {
        return point;
      }
    }

    return null;
  }

  double meanOf(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    return values.fold<double>(0, (total, value) => total + value) /
        values.length;
  }

  ForecastResult simpleMovingAverageForTarget({
    required List<PeriodPoint> precedingPoints,
    required DateTime targetDate,
  }) {
    final values = <double>[];

    for (var offset = smaWindow; offset >= 1; offset--) {
      final expectedDate = shiftAnalyticsPeriod(targetDate, -offset);
      final point = pointForAnalyticsPeriod(precedingPoints, expectedDate);

      if (point == null) {
        return ForecastResult.unavailable(
          reason:
              'Requires $smaWindow consecutive preceding $periodName periods.',
        );
      }

      values.add(point.quantity);
    }

    return ForecastResult.available(meanOf(values));
  }

  ForecastResult simpleMovingAverageForecast(List<PeriodPoint> points) {
    if (points.isEmpty) {
      return ForecastResult.unavailable(
        reason: 'No completed periods are available.',
      );
    }

    final targetDate = shiftAnalyticsPeriod(points.last.date, 1);

    return simpleMovingAverageForTarget(
      precedingPoints: points,
      targetDate: targetDate,
    );
  }

  ForecastResult seasonalMovingAverageForTarget({
    required List<PeriodPoint> precedingPoints,
    required DateTime targetDate,
  }) {
    // The final configuration requires not only the comparable lags but the
    // full preceding-history coverage: 12 weekly periods or 24 monthly
    // periods before the target.
    for (var offset = 1; offset <= seasonalMinimumPrecedingPeriods; offset++) {
      final expectedDate = shiftAnalyticsPeriod(targetDate, -offset);

      if (pointForAnalyticsPeriod(precedingPoints, expectedDate) == null) {
        return ForecastResult.unavailable(
          reason: !forecastMonthly
              ? 'Requires 12 consecutive preceding weekly observations before the three 4-week seasonal comparisons can be evaluated.'
              : 'Requires 24 consecutive preceding monthly observations before the two 12-month seasonal comparisons can be evaluated.',
        );
      }
    }

    final comparableValues = <double>[];

    for (
      var comparableIndex = 1;
      comparableIndex <= seasonalComparablePeriods;
      comparableIndex++
    ) {
      final expectedDate = shiftAnalyticsPeriod(
        targetDate,
        -(seasonalInterval * comparableIndex),
      );

      final point = pointForAnalyticsPeriod(precedingPoints, expectedDate);

      if (point == null) {
        return ForecastResult.unavailable(
          reason: !forecastMonthly
              ? 'Requires 3 comparable weekly observations spaced 4 weeks apart, with at least 12 preceding weeks.'
              : 'Requires 2 comparable monthly observations spaced 12 months apart, with at least 24 preceding months.',
        );
      }

      comparableValues.add(point.quantity);
    }

    return ForecastResult.available(meanOf(comparableValues));
  }

  ForecastResult seasonalMovingAverageForecast(List<PeriodPoint> points) {
    if (points.isEmpty) {
      return ForecastResult.unavailable(
        reason: 'No completed periods are available.',
      );
    }

    final targetDate = shiftAnalyticsPeriod(points.last.date, 1);

    return seasonalMovingAverageForTarget(
      precedingPoints: points,
      targetDate: targetDate,
    );
  }

  ForecastComparison evaluateMethods(
    List<PeriodPoint> points, {
    required ForecastResult simpleForecast,
    required ForecastResult seasonalForecast,
  }) {
    List<ForecastObservation> observations(ForecastingMethod method) {
      final result = <ForecastObservation>[];
      for (var index = 0; index < points.length; index++) {
        final target = points[index];
        final preceding = points.sublist(0, index);
        final forecast = method == ForecastingMethod.simpleMovingAverage
            ? simpleMovingAverageForTarget(
                precedingPoints: preceding,
                targetDate: target.date,
              )
            : seasonalMovingAverageForTarget(
                precedingPoints: preceding,
                targetDate: target.date,
              );
        if (forecast.hasValue) {
          result.add(
            ForecastObservation(
              target: target.date,
              actual: target.quantity,
              forecast: forecast.value,
            ),
          );
        }
      }
      return result;
    }

    return compareForecastMethods(
      simple: observations(ForecastingMethod.simpleMovingAverage),
      seasonal: observations(ForecastingMethod.seasonalMovingAverage),
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
    );
  }
}

class AnalyticsForecastCalculator with AnalyticsForecastEngine {
  AnalyticsForecastCalculator({required this.forecastMonthly});
  @override
  final bool forecastMonthly;
}
