import 'package:isdalink/analytics/analytics_ranking.dart';
import 'analytics_common_target_cases.dart' show require;

class RankingFixture implements AnalyticsRankingSeries {
  RankingFixture(
    this.productName,
    this.quantityUnit,
    this.quantity,
    this.amount, {
    this.hasCompleteAmounts = true,
  });
  @override
  final String productName;
  @override
  final String quantityUnit;
  @override
  final double quantity;
  @override
  final double amount;
  @override
  final bool hasCompleteAmounts;
  @override
  String get seriesKey => '$productName|$quantityUnit';
}

List<RankingFixture> ranked(List<RankingFixture> rows) {
  final basis = analyticsRankingBasis(rows);
  return rows..sort((a, b) => compareAnalyticsRankingSeries(a, b, basis));
}

final analyticsRankingCases = <String, void Function()>{
  'single unit ranks fulfilled quantity, not amount': () {
    final rows = ranked([
      RankingFixture('A', 'kg', 10, 100),
      RankingFixture('B', 'kg', 5, 1000),
    ]);
    require(
      analyticsRankingBasis(rows) == AnalyticsRankingBasis.quantity &&
          rows.first.productName == 'A',
      'Quantity basis',
    );
  },
  'mixed units rank amount, not incompatible quantities': () {
    final rows = ranked([
      RankingFixture('A', 'kg', 100, 100),
      RankingFixture('B', 'tab', 1, 1000),
    ]);
    require(
      analyticsRankingBasis(rows) == AnalyticsRankingBasis.amount &&
          rows.first.productName == 'B',
      'Amount basis',
    );
  },
  'same fish in different units remains separate': () {
    final rows = ranked([
      RankingFixture('Tamban', 'kg', 10, 100),
      RankingFixture('Tamban', 'icebox', 1, 1000),
    ]);
    require(
      rows.length == 2 && rows.map((p) => p.seriesKey).toSet().length == 2,
      'Separate unit series',
    );
  },
  'incomplete mixed-unit amounts disable ranking': () {
    final rows = ranked([
      RankingFixture('Z', 'kg', 100, 10000),
      RankingFixture('A', 'tab', 1, 0, hasCompleteAmounts: false),
    ]);
    require(
      analyticsRankingBasis(rows) == AnalyticsRankingBasis.unavailable &&
          rows.first.productName == 'A',
      'Name list, no ranking',
    );
    require(
      !analyticsRankingTitle(
        analyticsRankingBasis(rows),
        supplier: true,
      ).contains('Top'),
      'No Top title',
    );
  },
  'incomplete amounts do not disable valid same-unit quantity ranking': () {
    final rows = ranked([
      RankingFixture('A', 'kg', 10, 0, hasCompleteAmounts: false),
      RankingFixture('B', 'kg', 5, 1000),
    ]);
    require(
      analyticsRankingBasis(rows) == AnalyticsRankingBasis.quantity &&
          rows.first.productName == 'A',
      'Quantity independent of amount',
    );
  },
  'known zero amount is distinct from unknown amount': () {
    require(
      analyticsRankingBasis([
            RankingFixture('A', 'kg', 10, 0),
            RankingFixture('B', 'tab', 1, 100),
          ]) ==
          AnalyticsRankingBasis.amount,
      'Known zero still ranks',
    );
  },
  'labels explicitly describe role, unit separation, basis and scope': () {
    for (final basis in AnalyticsRankingBasis.values) {
      final text = analyticsRankingDescription(basis, 'kg');
      require(
        text.contains('All included closed-period history') &&
            text.contains('Each fish and unit is separate'),
        'Scope',
      );
      require(
        analyticsRankingTitle(basis, supplier: true).contains('Sales by Unit'),
        'Supplier sales',
      );
      require(
        analyticsRankingTitle(
          basis,
          supplier: false,
        ).contains('Purchases by Unit'),
        'Vendor purchases',
      );
    }
  },
  'equal ranking values remain tied without an added metric': () {
    final a = RankingFixture('A', 'kg', 10, 1);
    final b = RankingFixture('B', 'kg', 10, 100);
    require(
      compareAnalyticsRankingSeries(a, b, AnalyticsRankingBasis.quantity) == 0,
      'Quantity tie',
    );
    require(
      compareAnalyticsRankingSeries(
            a,
            RankingFixture('B', 'tab', 100, 1),
            AnalyticsRankingBasis.amount,
          ) ==
          0,
      'Amount tie',
    );
  },
};
