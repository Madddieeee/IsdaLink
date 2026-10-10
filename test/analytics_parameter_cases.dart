import 'package:isdalink/analytics/forecast_parameters.dart';

void check(bool condition) {
  if (!condition) throw StateError('Method Contract parameters changed');
}

final analyticsParameterCases = <String, void Function()>{
  'Weekly fixed SMA4 and seasonal4x3 requiring12': () {
    const p = AnalyticsForecastParameters.weekly;
    check(
      p.smaWindow == 4 &&
          p.seasonalInterval == 4 &&
          p.seasonalComparablePeriods == 3 &&
          p.seasonalMinimumPrecedingPeriods == 12,
    );
  },
  'Monthly fixed SMA3 and seasonal12x2 requiring24': () {
    const p = AnalyticsForecastParameters.monthly;
    check(
      p.smaWindow == 3 &&
          p.seasonalInterval == 12 &&
          p.seasonalComparablePeriods == 2 &&
          p.seasonalMinimumPrecedingPeriods == 24,
    );
  },
};
