import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/analytics/analytics_ranking.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'analytics_ranking_cases.dart';

void main() {
  for (final entry in analyticsRankingCases.entries) {
    test(entry.key, entry.value);
  }
  test('actual screen product summaries use the ranking contract', () {
    const products = [
      ProductSummary(
        seriesKey: 'Tamban|kg',
        productName: 'Tamban',
        quantityUnit: 'kg',
        emoji: '',
        quantity: 100,
        amount: 10,
        transactionCount: 1,
      ),
      ProductSummary(
        seriesKey: 'Tamban|tab',
        productName: 'Tamban',
        quantityUnit: 'tab',
        emoji: '',
        quantity: 1,
        amount: 100,
        transactionCount: 1,
      ),
    ];
    expect(analyticsRankingBasis(products), AnalyticsRankingBasis.amount);
    expect(
      compareAnalyticsRankingSeries(
        products.first,
        products.last,
        AnalyticsRankingBasis.amount,
      ),
      greaterThan(0),
    );
    expect(products.map((p) => p.seriesKey).toSet().length, 2);
  });
}
