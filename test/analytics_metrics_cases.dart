import 'package:isdalink/analytics/analytics_metrics.dart';
import 'package:isdalink/analytics/forecast_comparison.dart';
import 'analytics_common_target_cases.dart' show require, close;

final analyticsMetricsCases = <String, void Function()>{
  'empty and single-period CV are unavailable': () {
    require(analyticsCoefficientOfVariation([]) == null, 'Empty');
    require(analyticsCoefficientOfVariation([10]) == null, 'Single period');
  },
  'constant positive quantities have valid zero CV': () {
    close(analyticsCoefficientOfVariation([10, 10, 10])!, 0);
  },
  'CV preserves sample standard deviation': () {
    // Sample SD([10,20,30]) = 10; mean = 20; CV = 50%.
    close(analyticsCoefficientOfVariation([10, 20, 30])!, 50);
  },
  'zero mean CV is undefined, not zero variability': () {
    require(analyticsCoefficientOfVariation([0, 0]) == null, 'Undefined');
  },
  'invalid CV inputs are unavailable': () {
    for (final value in [double.nan, double.infinity, -1.0]) {
      require(analyticsCoefficientOfVariation([10, value]) == null, 'Invalid');
    }
  },
  'zero observations can contribute to valid positive-mean CV': () {
    close(analyticsCoefficientOfVariation([0, 10, 20])!, 100);
  },
  'evaluation explanation uses actual counts without accuracy categories': () {
    for (final forecast in [0.0, 1000.0]) {
      final evaluation = evaluateObservations([
        ForecastObservation(
          target: DateTime.utc(2026, 1),
          actual: 10,
          forecast: forecast,
        ),
        ForecastObservation(
          target: DateTime.utc(2026, 2),
          actual: 0,
          forecast: forecast,
        ),
      ]);
      final text = analyticsEvaluationHistory(evaluation);
      require(
        text.contains('1 nonzero-actual') && text.contains('2 target periods'),
        'Counts',
      );
      require(
        !text.contains('High') &&
            !text.contains('Low') &&
            !text.contains('caution'),
        'Neutral',
      );
    }
  },
  'CV description separates unavailable from observed zero': () {
    require(
      analyticsVariabilityDescription(null).contains('positive mean'),
      'Unavailable reason',
    );
    require(
      analyticsVariabilityDescription(0).contains('quantities are equal'),
      'Valid zero',
    );
  },
};
