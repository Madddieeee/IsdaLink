import 'package:isdalink/analytics/forecast_engine.dart';
import 'package:isdalink/analytics/forecast_comparison.dart';
import 'analytics_common_target_cases.dart' show require, close;

Map<String, void Function()> analyticsEngineRegressionCases(bool monthly) {
  final engine = AnalyticsForecastCalculator(forecastMonthly: monthly);
  final target = DateTime.utc(2026, 10, 5);
  List<PeriodPoint> history(int count, double Function(int) quantity) =>
      List.generate(
        count,
        (i) => PeriodPoint(
          date: engine.shiftAnalyticsPeriod(target, i - count),
          quantity: quantity(i),
          amount: 0,
        ),
      );
  return {
    'chronological one-ahead comparison matches a hand-calculated trend': () {
      final minimum = monthly ? 24 : 12;
      final points = history(minimum + 3, (i) => (i + 1).toDouble());
      final result = engine.evaluateMethods(
        points,
        simpleForecast: engine.simpleMovingAverageForTarget(
          precedingPoints: points,
          targetDate: target,
        ),
        seasonalForecast: engine.seasonalMovingAverageForTarget(
          precedingPoints: points,
          targetDate: target,
        ),
      );
      // Linear quantities 1,2,... give constant one-ahead errors. The first
      // shared actual is minimum+1, with exactly three shared targets.
      final smaError = monthly ? 2.0 : 2.5;
      final seasonalError = monthly ? 18.0 : 8.0;
      final inverseActualMean =
          (1 / (minimum + 1) + 1 / (minimum + 2) + 1 / (minimum + 3)) / 3;
      require(
        result.simpleEvaluation.commonTargets &&
            result.seasonalEvaluation.commonTargets,
        'Shared targets',
      );
      require(
        result.simpleEvaluation.maePairCount == 3 &&
            result.seasonalEvaluation.maePairCount == 3,
        'Three one-ahead targets',
      );
      close(result.simpleEvaluation.mae, smaError);
      close(result.seasonalEvaluation.mae, seasonalError);
      close(result.simpleEvaluation.mape, smaError * inverseActualMean * 100);
      close(
        result.seasonalEvaluation.mape,
        seasonalError * inverseActualMean * 100,
      );
      require(
        result.selection.method == ForecastingMethod.simpleMovingAverage,
        'Expected SMA',
      );
    },
    'target actual and future observations cannot enter its forecast': () {
      final points = history(30, (_) => 1.23456789);
      final contaminated = [
        ...points,
        PeriodPoint(date: target, quantity: 999999, amount: 0),
        PeriodPoint(
          date: engine.shiftAnalyticsPeriod(target, 1),
          quantity: 888888,
          amount: 0,
        ),
      ];
      close(
        engine
            .simpleMovingAverageForTarget(
              precedingPoints: contaminated,
              targetDate: target,
            )
            .value,
        1.23456789,
      );
      close(
        engine
            .seasonalMovingAverageForTarget(
              precedingPoints: contaminated,
              targetDate: target,
            )
            .value,
        1.23456789,
      );
    },
    'later observations do not alter earlier chronological evaluation pairs':
        () {
          final count = monthly ? 25 : 13;
          final points = history(count, (i) => (i + 1).toDouble());
          final firstTarget = points.last.date;
          final preceding = points.sublist(0, points.length - 1);
          final before = engine.simpleMovingAverageForTarget(
            precedingPoints: preceding,
            targetDate: firstTarget,
          );
          final after = engine.simpleMovingAverageForTarget(
            precedingPoints: [
              ...preceding,
              PeriodPoint(
                date: engine.shiftAnalyticsPeriod(firstTarget, 1),
                quantity: 999999,
                amount: 0,
              ),
            ],
            targetDate: firstTarget,
          );
          close(before.value, after.value);
          close(before.value, monthly ? 23 : 10.5);
        },
    'raw small decimal forecasts retain precision through method selection':
        () {
          const raw = 0.00123456789;
          final points = history(monthly ? 8 : 9, (_) => raw);
          final sma = engine.simpleMovingAverageForTarget(
            precedingPoints: points,
            targetDate: target,
          );
          final seasonal = engine.seasonalMovingAverageForTarget(
            precedingPoints: points,
            targetDate: target,
          );
          final result = engine.evaluateMethods(
            points,
            simpleForecast: sma,
            seasonalForecast: seasonal,
          );
          require(
            result.selection.hasSelection && !seasonal.hasValue,
            'Only SMA eligible',
          );
          close(result.selection.forecast, raw);
          close(result.simpleEvaluation.mae, 0);
        },
  };
}
