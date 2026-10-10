// Pure forecast evaluation and common-target comparison.

class ForecastObservation {
  const ForecastObservation({
    required this.target,
    required this.actual,
    required this.forecast,
  });
  final DateTime target;
  final double actual;
  final double forecast;
}

class ForecastComparison {
  const ForecastComparison({
    required this.simpleEvaluation,
    required this.seasonalEvaluation,
    required this.selection,
  });
  final ForecastEvaluation simpleEvaluation;
  final ForecastEvaluation seasonalEvaluation;
  final ForecastMethodSelection selection;
}

ForecastEvaluation evaluateObservations(
  List<ForecastObservation> observations, {
  bool commonTargets = false,
}) {
  if (observations.isEmpty) {
    return ForecastEvaluation.unavailable(
      reason: 'No valid one-period-ahead evaluation targets are available.',
    );
  }
  var error = 0.0;
  var percentageError = 0.0;
  var nonzeroCount = 0;
  for (final pair in observations) {
    final absoluteError = (pair.actual - pair.forecast).abs();
    error += absoluteError;
    if (pair.actual != 0) {
      percentageError += absoluteError / pair.actual.abs() * 100;
      nonzeroCount++;
    }
  }
  return ForecastEvaluation.available(
    commonTargets: commonTargets,
    mae: error / observations.length,
    mape: nonzeroCount == 0 ? 0 : percentageError / nonzeroCount,
    hasMape: nonzeroCount > 0,
    maePairCount: observations.length,
    mapePairCount: nonzeroCount,
    zeroActualMapeExclusions: observations.length - nonzeroCount,
    reason: nonzeroCount == 0
        ? 'MAPE is unavailable because every valid target has zero actual quantity. MAE remains valid.'
        : '',
  );
}

Map<DateTime, ForecastObservation> _validTargets(
  List<ForecastObservation> observations,
) {
  final result = <DateTime, ForecastObservation>{};
  for (final pair in observations) {
    if (!pair.actual.isFinite || pair.actual < 0 || !pair.forecast.isFinite) {
      continue;
    }
    if (result.containsKey(pair.target)) {
      throw ArgumentError('Duplicate evaluation target: ${pair.target}');
    }
    result[pair.target] = pair;
  }
  return result;
}

ForecastComparison compareForecastMethods({
  required List<ForecastObservation> simple,
  required List<ForecastObservation> seasonal,
  required ForecastResult simpleForecast,
  required ForecastResult seasonalForecast,
}) {
  final simpleByDate = _validTargets(simple);
  final seasonalByDate = _validTargets(seasonal);
  var simpleEvaluation = evaluateObservations(simpleByDate.values.toList());
  var seasonalEvaluation = evaluateObservations(seasonalByDate.values.toList());
  final bothEligible =
      simpleForecast.hasValue &&
      seasonalForecast.hasValue &&
      simpleEvaluation.hasMape &&
      seasonalEvaluation.hasMape;
  var commonComparison = false;
  if (bothEligible) {
    final targets = simpleByDate.keys.where(seasonalByDate.containsKey).toList()
      ..sort();
    for (final date in targets) {
      if (simpleByDate[date]!.actual != seasonalByDate[date]!.actual) {
        throw ArgumentError('Methods disagree on actual quantity for $date');
      }
    }
    if (targets.isNotEmpty) {
      simpleEvaluation = evaluateObservations(
        targets.map((date) => simpleByDate[date]!).toList(),
        commonTargets: true,
      );
      seasonalEvaluation = evaluateObservations(
        targets.map((date) => seasonalByDate[date]!).toList(),
        commonTargets: true,
      );
      commonComparison = simpleEvaluation.hasMape && seasonalEvaluation.hasMape;
    }
    // A missing/zero-only common MAPE set never allows independent metrics
    // to create a winner, including when MAE alone is available.
    if (!commonComparison) {
      return ForecastComparison(
        simpleEvaluation: simpleEvaluation,
        seasonalEvaluation: seasonalEvaluation,
        selection: ForecastMethodSelection.unavailable(
          reason: 'No common nonzero-actual target periods are available for direct comparison. No method is ranked.',
        ),
      );
    }
  }
  return ForecastComparison(
    simpleEvaluation: simpleEvaluation,
    seasonalEvaluation: seasonalEvaluation,
    selection: selectForecastMethod(
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
      simpleEvaluation: simpleEvaluation,
      seasonalEvaluation: seasonalEvaluation,
      commonComparison: commonComparison,
    ),
  );
}

class ForecastResult {
  const ForecastResult._({
    required this.value,
    required this.hasValue,
    required this.reason,
  });

  final double value;
  final bool hasValue;
  final String reason;

  factory ForecastResult.available(double value) {
    return ForecastResult._(value: value, hasValue: true, reason: '');
  }

  factory ForecastResult.unavailable({required String reason}) {
    return ForecastResult._(value: 0, hasValue: false, reason: reason);
  }
}

enum ForecastingMethod { simpleMovingAverage, seasonalMovingAverage }

class ForecastEvaluation {
  const ForecastEvaluation._({
    required this.mape,
    required this.mae,
    required this.hasMape,
    required this.hasMae,
    required this.maePairCount,
    required this.mapePairCount,
    required this.zeroActualMapeExclusions,
    required this.reason,
    required this.commonTargets,
  });

  final double mape;
  final double mae;
  final bool hasMape;
  final bool hasMae;
  final int maePairCount;
  final int mapePairCount;
  final int zeroActualMapeExclusions;
  final String reason;
  final bool commonTargets;

  factory ForecastEvaluation.available({
    bool commonTargets = false,
    required double mape,
    required double mae,
    required bool hasMape,
    required int maePairCount,
    required int mapePairCount,
    required int zeroActualMapeExclusions,
    required String reason,
  }) {
    return ForecastEvaluation._(
      commonTargets: commonTargets,
      mape: mape,
      mae: mae,
      hasMape: hasMape,
      hasMae: true,
      maePairCount: maePairCount,
      mapePairCount: mapePairCount,
      zeroActualMapeExclusions: zeroActualMapeExclusions,
      reason: reason,
    );
  }

  factory ForecastEvaluation.unavailable({required String reason}) {
    return ForecastEvaluation._(
      commonTargets: false,
      mape: 0,
      mae: 0,
      hasMape: false,
      hasMae: false,
      maePairCount: 0,
      mapePairCount: 0,
      zeroActualMapeExclusions: 0,
      reason: reason,
    );
  }
}

class ForecastMethodSelection {
  const ForecastMethodSelection._({
    required this.method,
    required this.forecast,
    required this.reason,
  });

  final ForecastingMethod? method;
  final double forecast;
  final String reason;

  bool get hasSelection => method != null;

  factory ForecastMethodSelection.selected({
    required ForecastingMethod method,
    required double forecast,
    required String reason,
  }) {
    return ForecastMethodSelection._(
      method: method,
      forecast: forecast,
      reason: reason,
    );
  }

  factory ForecastMethodSelection.unavailable({required String reason}) {
    return ForecastMethodSelection._(method: null, forecast: 0, reason: reason);
  }
}

ForecastMethodSelection selectForecastMethod({
  required ForecastResult simpleForecast,
  required ForecastResult seasonalForecast,
  required ForecastEvaluation simpleEvaluation,
  required ForecastEvaluation seasonalEvaluation,
  required bool commonComparison,
}) {
  final simpleEligible =
      simpleForecast.hasValue &&
      simpleEvaluation.hasMae &&
      simpleEvaluation.hasMape;

  final seasonalEligible =
      seasonalForecast.hasValue &&
      seasonalEvaluation.hasMae &&
      seasonalEvaluation.hasMape;

  if (simpleEligible && !seasonalEligible) {
    return ForecastMethodSelection.selected(
      method: ForecastingMethod.simpleMovingAverage,
      forecast: simpleForecast.value,
      reason: 'Simple Moving Average is the only method currently eligible for accuracy-based selection.',
    );
  }

  if (!simpleEligible && seasonalEligible) {
    return ForecastMethodSelection.selected(
      method: ForecastingMethod.seasonalMovingAverage,
      forecast: seasonalForecast.value,
      reason: 'Seasonal Moving Average is the only method currently eligible for accuracy-based selection.',
    );
  }

  if (!simpleEligible && !seasonalEligible) {
    return ForecastMethodSelection.unavailable(
      reason: !simpleForecast.hasValue && !seasonalForecast.hasValue
          ? 'Neither method has the consecutive closed-period history required for the selected forecast target. Historical accuracy results may still be available.'
          : 'Accuracy-based selection requires an available target forecast with valid MAPE and MAE evaluation. No method currently meets both requirements.',
    );
  }

  if (!commonComparison) {
    return ForecastMethodSelection.unavailable(
      reason: 'No common nonzero-actual target periods are available for direct comparison. The methods are reported separately.',
    );
  }

  final basis =
      'Compared on ${simpleEvaluation.mapePairCount} common nonzero-actual target periods for MAPE and ${simpleEvaluation.maePairCount} common target periods for MAE.';
  const tolerance = 0.0000001;
  final mapeDifference = (simpleEvaluation.mape - seasonalEvaluation.mape)
      .abs();

  if (mapeDifference > tolerance) {
    if (simpleEvaluation.mape < seasonalEvaluation.mape) {
      return ForecastMethodSelection.selected(
        method: ForecastingMethod.simpleMovingAverage,
        forecast: simpleForecast.value,
        reason: 'Selected because it has the lower common-period MAPE. $basis',
      );
    }

    return ForecastMethodSelection.selected(
      method: ForecastingMethod.seasonalMovingAverage,
      forecast: seasonalForecast.value,
      reason: 'Selected because it has the lower common-period MAPE. $basis',
    );
  }

  final maeDifference = (simpleEvaluation.mae - seasonalEvaluation.mae).abs();

  if (maeDifference > tolerance) {
    if (simpleEvaluation.mae < seasonalEvaluation.mae) {
      return ForecastMethodSelection.selected(
        method: ForecastingMethod.simpleMovingAverage,
        forecast: simpleForecast.value,
        reason:
            'Common-period MAPE is tied, so Simple Moving Average is selected by the lower common-period MAE. $basis',
      );
    }

    return ForecastMethodSelection.selected(
      method: ForecastingMethod.seasonalMovingAverage,
      forecast: seasonalForecast.value,
      reason:
          'Common-period MAPE is tied, so Seasonal Moving Average is selected by the lower common-period MAE. $basis',
    );
  }

  // The controlling analytics configuration defines lower MAE as the
  // tie-break after MAPE, but it does not define a third tie-break when
  // both measures are exactly equal. Do not invent one.
  return ForecastMethodSelection.unavailable(
    reason:
        'Common-period MAPE and MAE are tied, so no method is automatically preferred. $basis',
  );
}
