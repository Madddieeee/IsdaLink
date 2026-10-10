abstract interface class AnalyticsRankingSeries {
  String get seriesKey;
  String get productName;
  String get quantityUnit;
  double get quantity;
  double get amount;
  bool get hasCompleteAmounts;
}

enum AnalyticsRankingBasis { quantity, amount, unavailable }

AnalyticsRankingBasis analyticsRankingBasis(
  Iterable<AnalyticsRankingSeries> products,
) {
  if (products.isEmpty) return AnalyticsRankingBasis.unavailable;
  if (products.map((p) => p.quantityUnit).toSet().length <= 1) {
    return AnalyticsRankingBasis.quantity;
  }
  return products.every((p) => p.hasCompleteAmounts)
      ? AnalyticsRankingBasis.amount
      : AnalyticsRankingBasis.unavailable;
}

int compareAnalyticsRankingSeries(
  AnalyticsRankingSeries a,
  AnalyticsRankingSeries b,
  AnalyticsRankingBasis basis,
) => switch (basis) {
  AnalyticsRankingBasis.quantity => b.quantity.compareTo(a.quantity),
  AnalyticsRankingBasis.amount => b.amount.compareTo(a.amount),
  AnalyticsRankingBasis.unavailable => a.productName.compareTo(b.productName),
};

String analyticsRankingDescription(AnalyticsRankingBasis basis, String unit) {
  const scope =
      'All included closed-period history. Each fish and unit is separate.';
  return switch (basis) {
    AnalyticsRankingBasis.quantity =>
      '$scope Ranked by fulfilled quantity in $unit.',
    AnalyticsRankingBasis.amount =>
      '$scope Ranked by transaction amount across different units.',
    AnalyticsRankingBasis.unavailable =>
      '$scope Amounts are incomplete; listed by name, not ranked.',
  };
}

String analyticsRankingTitle(
  AnalyticsRankingBasis basis, {
  required bool supplier,
}) {
  if (basis == AnalyticsRankingBasis.unavailable) {
    return supplier ? 'Fish Sales by Unit' : 'Fish Purchases by Unit';
  }
  return supplier ? 'Top Fish Sales by Unit' : 'Top Fish Purchases by Unit';
}
