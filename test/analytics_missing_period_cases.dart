import 'analytics_common_target_cases.dart' show require, close;

// Synthetic zero observations test mathematics only; they do not certify
// zero activity in transaction sources or authorize inserting zero periods.
Map<String, void Function()> analyticsMissingPeriodCases({
  required dynamic engine,
  required DateTime target,
  required dynamic Function(int count, double quantity) history,
  required bool monthly,
}) {
  final window = monthly ? 3 : 4;
  final coverage = monthly ? 24 : 12;
  return {
    'empty history remains unavailable for both methods': () {
      require(
        !engine
            .simpleMovingAverageForTarget(
              precedingPoints: history(0, 10),
              targetDate: target,
            )
            .hasValue,
        'Empty SMA history',
      );
      require(
        !engine
            .seasonalMovingAverageForTarget(
              precedingPoints: history(0, 10),
              targetDate: target,
            )
            .hasValue,
        'Empty Seasonal history',
      );
    },
    'SMA distinguishes a missing period from explicit zero': () {
      final points = history(window, 0);
      final zero = engine.simpleMovingAverageForTarget(
        precedingPoints: points,
        targetDate: target,
      );
      require(zero.hasValue, 'Explicit zero is observed');
      close(zero.value as double, 0);
      points.removeLast();
      require(
        !engine
            .simpleMovingAverageForTarget(
              precedingPoints: points,
              targetDate: target,
            )
            .hasValue,
        'Removing observation must not create zero',
      );
    },
    'Seasonal distinguishes a missing non-lag period from explicit zero': () {
      final points = history(coverage, 0);
      final zero = engine.seasonalMovingAverageForTarget(
        precedingPoints: points,
        targetDate: target,
      );
      require(zero.hasValue, 'Explicit zero coverage is valid');
      close(zero.value as double, 0);
      points.removeWhere(
        (dynamic p) => p.date == engine.shiftAnalyticsPeriod(target, -2),
      );
      require(
        !engine
            .seasonalMovingAverageForTarget(
              precedingPoints: points,
              targetDate: target,
            )
            .hasValue,
        'Missing intervening period is not zero',
      );
    },
    'zero actual is retained in MAE and excluded from MAPE': () {
      final points = history(window + 1, 10);
      points[points.length - 1] = history(1, 0).last;
      final comparison = engine.evaluateMethods(
        points,
        simpleForecast: engine.simpleMovingAverageForecast(points),
        seasonalForecast: engine.seasonalMovingAverageForecast(points),
      );
      final evaluation = comparison.simpleEvaluation;
      require(
        evaluation.hasMae && !evaluation.hasMape,
        'Zero-only actual has MAE without MAPE',
      );
      require(
        evaluation.maePairCount == 1 &&
            evaluation.mapePairCount == 0 &&
            evaluation.zeroActualMapeExclusions == 1,
        'Zero pair counts',
      );
      close(evaluation.mae as double, 10);
      require(!comparison.selection.hasSelection, 'No zero-only MAPE winner');
    },
    'absent evaluation target creates no pair': () {
      final points = history(window, 10);
      final comparison = engine.evaluateMethods(
        points,
        simpleForecast: engine.simpleMovingAverageForecast(points),
        seasonalForecast: engine.seasonalMovingAverageForecast(points),
      );
      require(
        !comparison.simpleEvaluation.hasMae &&
            comparison.simpleEvaluation.maePairCount == 0,
        'No fabricated evaluation target',
      );
    },
    'gap prevents evaluation until consecutive history recovers': () {
      final points = history(window + 2, 10);
      points.removeAt(points.length - 2);
      final comparison = engine.evaluateMethods(
        points,
        simpleForecast: engine.simpleMovingAverageForecast(points),
        seasonalForecast: engine.seasonalMovingAverageForecast(points),
      );
      require(
        comparison.simpleEvaluation.maePairCount == 0,
        'Older observation cannot bridge a calendar gap',
      );
    },
  };
}
