import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

void main() {
  test('historical guidance uses only periods before its target', () {
    final dynamic state = const AnalyticsScreen(
      mode: AnalyticsMode.supplier,
    ).createState();
    state.selectedPeriod = AnalyticsPeriod.weekly;

    final start = DateTime.utc(2026, 8, 3);
    final points = <PeriodPoint>[
      for (var index = 0; index < 8; index++)
        PeriodPoint(
          date: start.add(Duration(days: index * 7)),
          quantity: (index + 1).toDouble(),
          amount: 100,
        ),
    ];
    const product = ProductSummary(
      seriesKey: 'bodloy|icebox',
      productName: 'Bodloy',
      quantityUnit: 'icebox',
      emoji: 'fish',
      quantity: 36,
      amount: 800,
      transactionCount: 8,
    );

    final suggestions = state.buildSuggestions(
      products: const [product],
      productSeries: {'bodloy|icebox': points},
      now: DateTime.utc(2026, 11, 16),
      historicalPeriod: points[4].date,
    ) as List<RestockingSuggestion>;

    expect(suggestions, hasLength(1));
    expect(suggestions.single.targetDate, points[5].date);
    expect(suggestions.single.suggestedQuantity, 3.5);
  });
}
