import 'package:isdalink/analytics/forecast_comparison.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void close(double actual, double expected) {
  require((actual - expected).abs() < 1e-9, '$actual != $expected');
}

ForecastObservation pair(int week, double actual, double forecast) =>
    ForecastObservation(
      target: DateTime(2026, 3, 2).add(Duration(days: week * 7)),
      actual: actual,
      forecast: forecast,
    );

ForecastComparison compare(
  List<ForecastObservation> simple,
  List<ForecastObservation> seasonal, {
  bool seasonalAvailable = true,
}) => compareForecastMethods(
  simple: simple,
  seasonal: seasonal,
  simpleForecast: ForecastResult.available(10.123456789),
  seasonalForecast: seasonalAvailable
      ? ForecastResult.available(20)
      : ForecastResult.unavailable(reason: 'Insufficient history'),
);

final analyticsCommonTargetCases = <String, void Function()>{
  'common targets reverse an unfair independent-history winner': () {
    final simple = [pair(0, 100, 300), pair(1, 100, 90)];
    final seasonal = [pair(1, 100, 80)];
    require(
      evaluateObservations(simple).mape > evaluateObservations(seasonal).mape,
      'Fixture must favor seasonal independently',
    );
    final result = compare(simple, seasonal);
    close(result.simpleEvaluation.mape, 10);
    close(result.seasonalEvaluation.mape, 20);
    require(result.simpleEvaluation.mapePairCount == 1, 'Shared pair count');
    require(
      result.selection.method == ForecastingMethod.simpleMovingAverage,
      'Common-target selection must favor SMA',
    );
    require(
      result.selection.reason.contains('common'),
      'Disclose comparison basis',
    );
  },
  'zero actual excluded only from MAPE and retained for common MAE': () {
    final result = compare(
      [pair(0, 0, 4), pair(1, 10, 8)],
      [pair(0, 0, 8), pair(1, 10, 12)],
    );
    close(result.simpleEvaluation.mape, 20);
    close(result.seasonalEvaluation.mape, 20);
    close(result.simpleEvaluation.mae, 3);
    close(result.seasonalEvaluation.mae, 5);
    require(
      result.simpleEvaluation.mapePairCount == 1 &&
          result.simpleEvaluation.maePairCount == 2 &&
          result.simpleEvaluation.zeroActualMapeExclusions == 1,
      'Zero counts',
    );
    require(
      result.selection.method == ForecastingMethod.simpleMovingAverage,
      'Common MAE breaks the MAPE tie',
    );
  },
  'both metrics tied means no third winner': () {
    final result = compare([pair(0, 10, 8)], [pair(0, 10, 12)]);
    require(!result.selection.hasSelection, 'Do not invent winner');
    require(result.selection.reason.contains('tied'), 'Explain tie');
  },
  'disjoint valid histories cannot select an independent winner': () {
    final result = compare([pair(0, 10, 9)], [pair(1, 10, 5)]);
    require(!result.selection.hasSelection, 'No common targets');
    require(!result.simpleEvaluation.commonTargets, 'Separate history label');
    close(result.simpleEvaluation.mape, 10);
  },
  'zero-only common targets cannot rank from positive independent targets': () {
    final result = compare(
      [pair(0, 10, 9), pair(1, 0, 2)],
      [pair(1, 0, 4), pair(2, 10, 8)],
    );
    require(!result.selection.hasSelection, 'No common MAPE');
    require(
      result.simpleEvaluation.hasMae && !result.simpleEvaluation.hasMape,
      'MAE remains available on common zero targets',
    );
  },
  'only eligible forecast uses its own history and is labeled': () {
    final result = compare([pair(0, 10, 9)], [], seasonalAvailable: false);
    require(
      result.selection.method == ForecastingMethod.simpleMovingAverage,
      'Only eligible method may guide',
    );
    require(
      result.selection.reason.contains('only method'),
      'Only-eligible label',
    );
    require(!result.simpleEvaluation.commonTargets, 'Not direct comparison');
  },
  'raw forecast precision preserved': () {
    final result = compare([pair(0, 10, 9)], [], seasonalAvailable: false);
    close(result.selection.forecast, 10.123456789);
    close(evaluateObservations([pair(0, 3, 1.23456789)]).mae, 1.76543211);
  },
  'monthly common targets are date identities rather than list positions': () {
    ForecastObservation month(int m, double forecast) => ForecastObservation(
      target: DateTime(2026, m),
      actual: 10,
      forecast: forecast,
    );
    final result = compare(
      [month(1, 99), month(3, 9), month(2, 8)],
      [month(2, 7), month(3, 6)],
    );
    require(
      result.simpleEvaluation.maePairCount == 2,
      'Two common calendar targets',
    );
    close(result.simpleEvaluation.mae, 1.5);
    close(result.seasonalEvaluation.mae, 3.5);
  },
  'invalid numerical pair cannot enter common comparison': () {
    final result = compare(
      [pair(0, 10, double.nan), pair(1, 10, 9)],
      [pair(0, 10, 8), pair(1, 10, 8)],
    );
    require(
      result.simpleEvaluation.mapePairCount == 1,
      'Nonfinite pair excluded',
    );
  },
  'duplicate targets and inconsistent actuals are rejected': () {
    var duplicateRejected = false;
    try {
      compare([pair(0, 10, 9), pair(0, 10, 9)], [pair(0, 10, 8)]);
    } on ArgumentError {
      duplicateRejected = true;
    }
    require(duplicateRejected, 'Duplicate targets rejected');
    var actualRejected = false;
    try {
      compare([pair(0, 10, 9)], [pair(0, 11, 8)]);
    } on ArgumentError {
      actualRejected = true;
    }
    require(actualRejected, 'Same target must share actual');
  },
  'numeric tolerance uses MAE after a near MAPE tie': () {
    final result = compare(
      [pair(0, 0, 1), pair(1, 100, 90)],
      [pair(0, 0, 4), pair(1, 100, 90.00000005)],
    );
    require(
      result.selection.method == ForecastingMethod.simpleMovingAverage,
      'MAPE within 1e-7 is tied; lower MAE selects SMA',
    );
    require(result.selection.reason.contains('MAE'), 'Tie-break disclosed');
  },
};
