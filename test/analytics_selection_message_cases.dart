import 'package:isdalink/analytics/forecast_comparison.dart';

void require(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

ForecastResult missingForecast() =>
    ForecastResult.unavailable(reason: 'Missing consecutive history');

ForecastEvaluation evaluation(double actual) => evaluateObservations([
  ForecastObservation(target: DateTime(2026, 8), actual: actual, forecast: 20),
]);

final analyticsSelectionMessageCases = <String, void Function()>{
  'missing target history preserves existing historical accuracy': () {
    final accuracy = evaluation(16);
    final selected = selectForecastMethod(
      simpleForecast: missingForecast(),
      seasonalForecast: missingForecast(),
      simpleEvaluation: accuracy,
      seasonalEvaluation: ForecastEvaluation.unavailable(reason: 'No targets'),
      commonComparison: false,
    );
    require(!selected.hasSelection, 'Must not invent a forecast');
    require(
      selected.reason.contains('consecutive closed-period history'),
      'Explain missing target history',
    );
    require(
      accuracy.hasMape && accuracy.mape == 25 && accuracy.mae == 4,
      'Retain historical metrics',
    );
  },
  'missing forecast and evaluation explain history rather than MAPE alone': () {
    final selected = selectForecastMethod(
      simpleForecast: missingForecast(),
      seasonalForecast: missingForecast(),
      simpleEvaluation: ForecastEvaluation.unavailable(reason: 'No targets'),
      seasonalEvaluation: ForecastEvaluation.unavailable(reason: 'No targets'),
      commonComparison: false,
    );
    require(
      !selected.hasSelection &&
          selected.reason.contains('selected forecast target'),
      'Missing history explanation applies without evaluation',
    );
  },
  'available forecast with zero actuals explains missing accuracy evidence':
      () {
        final accuracy = evaluation(0);
        final selected = selectForecastMethod(
          simpleForecast: ForecastResult.available(20),
          seasonalForecast: missingForecast(),
          simpleEvaluation: accuracy,
          seasonalEvaluation: ForecastEvaluation.unavailable(
            reason: 'No targets',
          ),
          commonComparison: false,
        );
        require(
          !selected.hasSelection,
          'Zero-actual MAPE cannot select a method',
        );
        require(
          selected.reason.contains('valid MAPE and MAE'),
          'Explain accuracy requirements',
        );
        require(
          accuracy.hasMae && !accuracy.hasMape && accuracy.mae == 20,
          'MAE remains valid when MAPE is unavailable',
        );
      },
  'eligible forecast selection and raw precision stay unchanged': () {
    final selected = selectForecastMethod(
      simpleForecast: ForecastResult.available(20.123456789),
      seasonalForecast: missingForecast(),
      simpleEvaluation: evaluation(16),
      seasonalEvaluation: ForecastEvaluation.unavailable(reason: 'No targets'),
      commonComparison: false,
    );
    require(
      selected.method == ForecastingMethod.simpleMovingAverage &&
          selected.forecast == 20.123456789,
      'Preserve selection and precision',
    );
  },
};
