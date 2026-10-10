/// Fixed Method Contract settings, shared by calculations and UI readiness.
/// These are configured recurring-cycle lags, not detected seasonality.
class AnalyticsForecastParameters {
  const AnalyticsForecastParameters._({
    required this.smaWindow,
    required this.seasonalInterval,
    required this.seasonalComparablePeriods,
  });

  static const weekly = AnalyticsForecastParameters._(
    smaWindow: 4,
    seasonalInterval: 4,
    seasonalComparablePeriods: 3,
  );
  static const monthly = AnalyticsForecastParameters._(
    smaWindow: 3,
    seasonalInterval: 12,
    seasonalComparablePeriods: 2,
  );

  final int smaWindow;
  final int seasonalInterval;
  final int seasonalComparablePeriods;

  int get seasonalMinimumPrecedingPeriods =>
      seasonalInterval * seasonalComparablePeriods;
}
