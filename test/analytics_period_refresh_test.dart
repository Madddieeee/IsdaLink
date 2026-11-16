import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

AnalyticsData seriesData(Map<String, List<PeriodPoint>> productSeries) {
  final empty = AnalyticsData.empty();
  return AnalyticsData(
    completedOrders: 1,
    liveCompletedOrders: 0,
    historicalTransactions: 1,
    totalAmount: 0,
    products: const [],
    productSeries: productSeries,
    selectedProduct: null,
    selectedPoints: const [],
    rankingBasis: '',
    simpleForecast: empty.simpleForecast,
    seasonalForecast: empty.seasonalForecast,
    simpleEvaluation: empty.simpleEvaluation,
    seasonalEvaluation: empty.seasonalEvaluation,
    selectedMethod: empty.selectedMethod,
    variability: null,
    suggestions: const [],
    stockAlerts: const [],
  );
}

void main() {
  for (final mode in AnalyticsMode.values) {
    test('$mode reselecting Monthly clears history on the first tap', () {
      final dynamic state = AnalyticsScreen(mode: mode).createState();
      state.selectedPeriod = AnalyticsPeriod.monthly;
      state.selectedSupplierPeriodStart = DateTime.utc(2026, 8);
      state.selectedSupplierChartBarIndex = 2;
      state.selectedSeriesKey = 'pirit|icebox';

      state.selectAnalyticsPeriod(AnalyticsPeriod.monthly);

      expect(state.selectedPeriod, AnalyticsPeriod.monthly);
      expect(state.selectedSupplierPeriodStart, isNull);
      expect(state.selectedSupplierChartBarIndex, isNull);
      expect(state.selectedSeriesKey, 'pirit|icebox');
    });

    test('$mode changing to Weekly refreshes on the first tap', () {
      final dynamic state = AnalyticsScreen(mode: mode).createState();
      state.selectedPeriod = AnalyticsPeriod.monthly;
      state.selectedSupplierPeriodStart = DateTime.utc(2026, 8);
      state.selectedSupplierChartBarIndex = 1;
      state.selectedSeriesKey = 'panit|icebox';

      state.selectAnalyticsPeriod(AnalyticsPeriod.weekly);

      expect(state.selectedPeriod, AnalyticsPeriod.weekly);
      expect(state.selectedSupplierPeriodStart, isNull);
      expect(state.selectedSupplierChartBarIndex, isNull);
      expect(state.selectedSeriesKey, 'panit|icebox');
    });

    test('$mode changing fish preserves the selected historical period', () {
      final dynamic state = AnalyticsScreen(mode: mode).createState();
      final selectedWeek = DateTime.utc(2026, 10, 19);
      state.selectedPeriod = AnalyticsPeriod.weekly;
      state.selectedSupplierPeriodStart = selectedWeek;
      state.selectAnalyticsSeries(
        seriesData({
          'tamban|icebox': [
            PeriodPoint(date: selectedWeek, quantity: 5, amount: 100),
          ],
        }),
        'tamban|icebox',
      );

      expect(state.selectedSeriesKey, 'tamban|icebox');
      expect(state.selectedSupplierPeriodStart, selectedWeek);
    });

    test('$mode fish without that period falls back to its latest history', () {
      final dynamic state = AnalyticsScreen(mode: mode).createState();
      final requestedWeek = DateTime.utc(2026, 10, 19);
      final latestWeek = DateTime.utc(2026, 10, 26);
      state.selectedPeriod = AnalyticsPeriod.weekly;
      state.selectedSupplierPeriodStart = requestedWeek;
      state.selectAnalyticsSeries(
        seriesData({
          'tamban|icebox': [
            PeriodPoint(date: latestWeek, quantity: 6, amount: 120),
          ],
        }),
        'tamban|icebox',
      );

      expect(state.selectedSupplierPeriodStart, latestWeek);
    });
  }
}
