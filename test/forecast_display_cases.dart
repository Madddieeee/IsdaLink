import 'package:isdalink/analytics/forecast_display.dart';
import 'package:isdalink/analytics/forecast_comparison.dart';
import 'analytics_common_target_cases.dart' show require, close;

final forecastDisplayCases = <String, void Function()>{
  'whole estimates omit decimal padding': () {
    require(formatForecastEstimate(12) == '12', 'Whole estimate');
  },
  'estimates consistently show at most two decimals': () {
    require(formatForecastEstimate(12.3456) == '12.35', 'Two decimals');
    require(formatForecastEstimate(12.3) == '12.3', 'Trim padding');
  },
  'small positive estimates are distinct from true zero': () {
    require(formatForecastEstimate(0.000001) == '<0.01', 'Positive estimate');
    require(formatForecastEstimate(0) == '0', 'True zero');
    require(formatForecastEstimate(0.01) == '0.01', 'Boundary');
  },
  'fractional packaging quantities remain decimal estimates': () {
    require(formatForecastEstimate(1.25) == '1.25', 'No packaging rounding');
  },
  'invalid forecast display is unavailable': () {
    for (final value in [-1.0, double.nan, double.infinity]) {
      require(formatForecastEstimate(value) == 'Unavailable', 'Invalid');
    }
  },
  'formatting never rounds the evaluated observation': () {
    const raw = 1.23456789;
    final observation = ForecastObservation(
      target: DateTime.utc(2026, 1),
      actual: 2,
      forecast: raw,
    );
    final before = evaluateObservations([observation]);
    require(formatForecastEstimate(raw) == '1.23', 'Presentation');
    final after = evaluateObservations([observation]);
    require(observation.forecast == raw, 'Raw value preserved');
    close(after.mae, 2 - raw);
    close(after.mape, (2 - raw) / 2 * 100);
    require(
      before.mae == after.mae && before.mape == after.mape,
      'Unchanged errors',
    );
  },
};
