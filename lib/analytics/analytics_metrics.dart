import 'dart:math' as math;

import 'forecast_comparison.dart';

/// Sample CV. Unavailable is distinct from a valid constant series (0%).
double? analyticsCoefficientOfVariation(List<double> values) {
  if (values.length < 2 ||
      values.any((value) => !value.isFinite || value < 0)) {
    return null;
  }
  final mean =
      values.fold<double>(0, (total, value) => total + value) / values.length;
  if (mean == 0 || !mean.isFinite) return null;
  final variance =
      values
          .map((value) => math.pow(value - mean, 2).toDouble())
          .fold<double>(0, (total, value) => total + value) /
      (values.length - 1);
  final result = math.sqrt(variance) / mean * 100;
  return result.isFinite ? result : null;
}

String analyticsEvaluationHistory(ForecastEvaluation evaluation) =>
    'Evaluation history: ${evaluation.mapePairCount} nonzero-actual '
    'target periods for MAPE; ${evaluation.maePairCount} target periods for MAE. '
    'These results describe the available history, not guaranteed future accuracy.';

String analyticsVariabilityDescription(double? value) => value == null
    ? 'CV requires at least two observed completed periods and a positive mean quantity.'
    : 'Sample standard deviation as a percentage of mean quantity. '
          '0% means the observed quantities are equal.';
