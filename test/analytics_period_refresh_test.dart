import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

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
  }
}
