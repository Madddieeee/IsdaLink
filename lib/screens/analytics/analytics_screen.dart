import 'dart:math' as math;

import '../../analytics/forecast_comparison.dart';
import '../../analytics/forecast_display.dart';
import '../../analytics/forecast_target.dart';
import '../../analytics/forecast_engine.dart';
export '../../analytics/forecast_engine.dart' show PeriodPoint;
import '../../analytics/analytics_metrics.dart';
import '../../analytics/analytics_ranking.dart';
import '../../analytics/analytics_record.dart';
import '../../analytics/analytics_identity.dart';
import '../../analytics/analytics_record_set.dart';
export '../../analytics/forecast_comparison.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AnalyticsMode { vendor, supplier }

enum AnalyticsPeriod { weekly, monthly }

enum SupplierAnalyticsTab { summary, accuracy, guidance, products }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    this.mode = AnalyticsMode.vendor,
    this.onBack,
  });

  final AnalyticsMode mode;
  final VoidCallback? onBack;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with AnalyticsForecastEngine {
  @override
  bool get forecastMonthly => selectedPeriod == AnalyticsPeriod.monthly;
  AnalyticsPeriod selectedPeriod = AnalyticsPeriod.weekly;
  SupplierAnalyticsTab selectedSupplierTab = SupplierAnalyticsTab.summary;
  String? selectedSeriesKey;
  DateTime? selectedSupplierPeriodStart;
  int? selectedSupplierChartBarIndex;
  final ScrollController _supplierScrollController = ScrollController();

  void _scrollSupplierToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_supplierScrollController.hasClients) {
        return;
      }

      _supplierScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Applies the requested period immediately. Tapping the already-active
  /// period resets any historical date so the view returns to current
  /// planning on the first tap while keeping the selected fish/unit series.
  void selectAnalyticsPeriod(AnalyticsPeriod period) {
    void updateSelection() {
      selectedPeriod = period;
      selectedSupplierPeriodStart = null;
      selectedSupplierChartBarIndex = null;
    }

    if (mounted) {
      setState(updateSelection);
    } else {
      updateSelection();
    }
  }

  @override
  void dispose() {
    _supplierScrollController.dispose();
    super.dispose();
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get isSupplier => widget.mode == AnalyticsMode.supplier;

  String get title => isSupplier ? 'Supplier Analytics' : 'Vendor Analytics';

  String get roleLabel => isSupplier ? 'SUPPLIER SIDE' : 'VENDOR SIDE';

  String get subtitle => isSupplier
      ? 'Sales insights from eligible transactions in closed periods. Inventory supports current stock alerts.'
      : 'Purchase insights from eligible transactions in closed periods.';

  String get amountLabel => isSupplier ? 'Sales' : 'Amount';

  String get trendTitle => isSupplier ? 'Sales Trend' : 'Purchase Trend';

  String get trendDescription => isSupplier
      ? 'Completed sales quantity for the selected fish and unit series.'
      : 'Completed purchase quantity for the selected fish and unit series.';

  String get emptyTitle => isSupplier
      ? 'No completed sales history yet'
      : 'No completed purchase history yet';

  String get emptyDescription => isSupplier
      ? 'Link validated historical transactions or complete COD orders to generate sales trends, forecasts, accuracy evaluation, and product insights.'
      : 'Link validated historical transactions or complete COD orders to generate purchase trends, forecasts, accuracy evaluation, and restocking insights.';

  String get emptyActionLabel =>
      isSupplier ? 'Review COD Orders' : 'Browse Suppliers';

  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream(String uid) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where(isSupplier ? 'supplierId' : 'vendorId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> historicalTransactionsStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('historicalTransactions')
        .where(isSupplier ? 'supplierUid' : 'vendorUid', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> supplierStocksStream(String uid) {
    return FirebaseFirestore.instance
        .collection('fishStocks')
        .where('supplierId', isEqualTo: uid)
        .snapshots();
  }

  String stringValue(Map<String, dynamic> data, String key, String fallback) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  String firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  double doubleValue(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }

  double firstPositiveDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = doubleValue(data, key);

      if (value > 0) {
        return value;
      }
    }

    return 0;
  }

  String normalizeAnalyticsUnit(String rawUnit) {
    final normalized = rawUnit
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (normalized == 'kg' ||
        normalized == 'kgs' ||
        normalized == 'kilo' ||
        normalized == 'kilos' ||
        normalized == 'kilogram' ||
        normalized == 'kilograms') {
      return 'kilogram';
    }

    if (normalized == 'tab' || normalized == 'tabs') {
      return 'tab';
    }

    if (normalized == 'ice box' ||
        normalized == 'ice boxes' ||
        normalized == 'icebox' ||
        normalized == 'iceboxes') {
      return 'icebox';
    }

    return normalized.isEmpty ? 'kilogram' : normalized;
  }

  String analyticsProductKey(String productName) {
    return productName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String periodKey(DateTime date) {
    final start = periodStart(date);

    return '${start.year}-${start.month}-${start.day}';
  }

  String periodLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (selectedPeriod == AnalyticsPeriod.monthly) {
      return '${months[date.month - 1]} ${date.year}';
    }

    final end = date.add(const Duration(days: 6));

    if (date.month == end.month) {
      return '${months[date.month - 1]} ${date.day}-${end.day}';
    }

    return '${months[date.month - 1]} ${date.day}';
  }

  EligibleAnalyticsRecord? validatedRecord(
    Map<String, dynamic> data,
    AnalyticsSource source,
  ) {
    // Convert Firestore instants only; date-only strings keep their meaning.
    final input = data.map(
      (key, value) =>
          MapEntry(key, value is Timestamp ? value.toDate() : value),
    );
    return eligibleAnalyticsRecord(
      input,
      source: source,
      supplier: isSupplier,
      accountUid: currentUser?.uid ?? '',
    );
  }

  AnalyticsData buildAnalyticsData({
    DateTime? now,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
    historicalTransactions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  }) {
    final analyticsNow = now ?? DateTime.now();

    final productMap = <String, ProductSummary>{};
    final productPeriodMap = <String, Map<String, PeriodPoint>>{};
    final quantityUnits = <String>{};

    void addLine({required _OrderLine line, required DateTime date}) {
      final normalizedUnit = normalizeAnalyticsUnit(line.quantityUnit);
      final normalizedProductName = analyticsProductKey(line.productName);
      final productKey = '$normalizedProductName|$normalizedUnit';

      quantityUnits.add(normalizedUnit);

      final lineAmount = line.amount;
      final existingProduct = productMap[productKey];

      productMap[productKey] = ProductSummary(
        seriesKey: productKey,
        productName: line.productName,
        quantityUnit: normalizedUnit,
        emoji: line.emoji,
        quantity: (existingProduct?.quantity ?? 0) + line.quantity,
        amount: (existingProduct?.amount ?? 0) + lineAmount,
        transactionCount: (existingProduct?.transactionCount ?? 0) + 1,
        hasCompleteAmounts:
            (existingProduct?.hasCompleteAmounts ?? true) &&
            line.hasKnownAmount,
      );

      final dateKey = periodKey(date);
      final series = productPeriodMap.putIfAbsent(
        productKey,
        () => <String, PeriodPoint>{},
      );
      final existingPoint = series[dateKey];

      series[dateKey] = PeriodPoint(
        date: date,
        quantity: (existingPoint?.quantity ?? 0) + line.quantity,
        amount: (existingPoint?.amount ?? 0) + lineAmount,
        transactionCount: (existingPoint?.transactionCount ?? 0) + 1,
        hasCompleteAmounts:
            (existingPoint?.hasCompleteAmounts ?? true) && line.hasKnownAmount,
      );
    }

    void includeRecord(EligibleAnalyticsRecord record) {
      final date = periodStart(record.date);
      for (final line in record.lines) {
        addLine(
          date: date,
          line: _OrderLine(
            productId: analyticsProductKey(line.productName),
            productName: line.productName,
            quantityUnit: line.unit,
            emoji: line.emoji,
            quantity: line.quantity,
            amount: line.amount ?? 0,
            hasKnownAmount: line.amount != null,
          ),
        );
      }
    }

    final identityResult = closedAnalyticsRecordSet(
      [
        for (final document in orders)
          AnalyticsIdentityRecord(
            documentId: document.id,
            source: AnalyticsSource.live,
            data: document.data(),
            record: validatedRecord(document.data(), AnalyticsSource.live),
          ),
        for (final document in historicalTransactions)
          AnalyticsIdentityRecord(
            documentId: document.id,
            source: AnalyticsSource.historical,
            data: document.data(),
            record: validatedRecord(
              document.data(),
              AnalyticsSource.historical,
            ),
          ),
      ],
      now: analyticsNow,
      monthly: forecastMonthly,
    );
    final totals = AnalyticsRecordTotals(identityResult.records);
    for (final input in identityResult.records) {
      includeRecord(input.record!);
    }

    final products = productMap.values.toList();
    final ranking = analyticsRankingBasis(products);
    products.sort((a, b) => compareAnalyticsRankingSeries(a, b, ranking));

    final productSeries = <String, List<PeriodPoint>>{};

    for (final entry in productPeriodMap.entries) {
      final points = entry.value.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      productSeries[entry.key] = points;
    }

    ProductSummary? selectedProduct;

    if (products.isNotEmpty) {
      selectedProduct = products.first;

      final requestedSeriesKey = selectedSeriesKey;

      if (requestedSeriesKey != null) {
        for (final product in products) {
          if (product.seriesKey == requestedSeriesKey) {
            selectedProduct = product;
            break;
          }
        }
      }
    }

    final selectedPoints = selectedProduct == null
        ? <PeriodPoint>[]
        : productSeries[selectedProduct.seriesKey] ?? <PeriodPoint>[];

    final quantities = selectedPoints.map((point) => point.quantity).toList();

    final forecastTarget = targetForPoints(selectedPoints, now: analyticsNow);
    final modelPoints = selectedPoints
        .where((point) => point.date.isBefore(forecastTarget.date))
        .toList();
    final simpleForecast = simpleMovingAverageForTarget(
      precedingPoints: modelPoints,
      targetDate: forecastTarget.date,
    );
    final seasonalForecast = seasonalMovingAverageForTarget(
      precedingPoints: modelPoints,
      targetDate: forecastTarget.date,
    );
    final comparison = evaluateMethods(
      modelPoints,
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
    );
    final simpleEvaluation = comparison.simpleEvaluation;
    final seasonalEvaluation = comparison.seasonalEvaluation;
    final selectedMethod = comparison.selection;
    final variabilityValue = variability(quantities);

    final rankingUnit = quantityUnits.isEmpty
        ? 'the recorded unit'
        : isSupplier
        ? supplierUnitLabel(quantityUnits.first)
        : quantityUnits.first;
    final rankingBasis = analyticsRankingDescription(ranking, rankingUnit);

    return AnalyticsData(
      completedOrders: totals.count,
      liveCompletedOrders: totals.liveCount,
      historicalTransactions: totals.historicalCount,
      identityConflicts: identityResult.conflictingRecords,
      totalAmount: totals.knownAmount,
      hasCompleteAmounts: totals.hasCompleteAmounts,
      products: products,
      selectedProduct: selectedProduct,
      selectedPoints: selectedPoints,
      rankingBasis: rankingBasis,
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
      simpleEvaluation: simpleEvaluation,
      seasonalEvaluation: seasonalEvaluation,
      selectedMethod: selectedMethod,
      variability: variabilityValue,
      suggestions: buildSuggestions(
        products: products,
        productSeries: productSeries,
        now: analyticsNow,
      ),
      stockAlerts: buildStockAlerts(stocks),
    );
  }

  AnalyticsForecastTarget targetForPoints(
    List<PeriodPoint> points, {
    DateTime? now,
  }) => analyticsForecastTarget(
    now: now ?? DateTime.now(),
    monthly: selectedPeriod == AnalyticsPeriod.monthly,
    historicalPeriod:
        points.any(
          (point) =>
              selectedSupplierPeriodStart != null &&
              sameAnalyticsPeriod(point.date, selectedSupplierPeriodStart!),
        )
        ? selectedSupplierPeriodStart
        : null,
  );

  String targetDescription(List<PeriodPoint> points) {
    final target = targetForPoints(points);
    return '${target.historical ? 'Historical forecast' : 'Current $periodNoun forecast'} · ${supplierPeriodRange(target.date)}';
  }

  int availableForecastPeriods(List<PeriodPoint> points, int requiredPeriods) {
    final target = targetForPoints(points).date;
    var count = 0;
    for (var offset = 1; offset <= requiredPeriods; offset++) {
      if (pointForAnalyticsPeriod(
            points,
            shiftAnalyticsPeriod(target, -offset),
          ) ==
          null) {
        break;
      }
      count++;
    }
    return count;
  }

  double? variability(List<double> values) =>
      analyticsCoefficientOfVariation(values);

  List<StockAlert> buildStockAlerts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  ) {
    if (!isSupplier) {
      return const [];
    }

    final alerts = <StockAlert>[];

    for (final document in stocks) {
      final data = document.data();
      final status = firstString(data, const [
        'stockStatus',
        'status',
      ], fallback: 'available').toLowerCase();

      if (status == 'hidden' || status == 'unavailable') {
        continue;
      }

      final quantity = doubleValue(data, 'quantity');
      final lowStockLevel = doubleValue(data, 'lowStockLevel');

      if (quantity > lowStockLevel) {
        continue;
      }

      alerts.add(
        StockAlert(
          productName: firstString(data, const [
            'productName',
            'fishName',
          ], fallback: 'Fish Product'),
          emoji: firstString(data, const [
            'productEmoji',
            'emoji',
          ], fallback: '🐟'),
          quantity: quantity,
          quantityUnit: firstString(data, const [
            'quantityUnit',
            'unit',
          ], fallback: 'kilo'),
          lowStockLevel: lowStockLevel,
        ),
      );
    }

    alerts.sort((a, b) => a.quantity.compareTo(b.quantity));

    return alerts;
  }

  List<RestockingSuggestion> buildSuggestions({
    required List<ProductSummary> products,
    required Map<String, List<PeriodPoint>> productSeries,
    DateTime? now,
  }) {
    final suggestions = <RestockingSuggestion>[];

    for (final product in products) {
      final points = productSeries[product.seriesKey] ?? const <PeriodPoint>[];

      final target = analyticsForecastTarget(
        now: now ?? DateTime.now(),
        monthly: selectedPeriod == AnalyticsPeriod.monthly,
      );
      final simple = simpleMovingAverageForTarget(
        precedingPoints: points,
        targetDate: target.date,
      );
      final seasonal = seasonalMovingAverageForTarget(
        precedingPoints: points,
        targetDate: target.date,
      );
      final comparison = evaluateMethods(
        points,
        simpleForecast: simple,
        seasonalForecast: seasonal,
      );
      final simpleEvaluation = comparison.simpleEvaluation;
      final seasonalEvaluation = comparison.seasonalEvaluation;
      final selection = comparison.selection;

      if (!selection.hasSelection) {
        continue;
      }

      final suggestedQuantity = selection.forecast;

      if (!suggestedQuantity.isFinite || suggestedQuantity <= 0) {
        continue;
      }

      final selectedEvaluation =
          selection.method == ForecastingMethod.simpleMovingAverage
          ? simpleEvaluation
          : seasonalEvaluation;
      suggestions.add(
        RestockingSuggestion(
          productName: product.productName,
          emoji: product.emoji,
          quantityUnit: product.quantityUnit,
          suggestedQuantity: suggestedQuantity,
          selectedMethod: selection.method!,
          targetDate: target.date,
          evaluationNote: analyticsEvaluationHistory(selectedEvaluation),
        ),
      );
    }

    return suggestions;
  }

  String forecastingMethodLabel(ForecastingMethod method) {
    return switch (method) {
      ForecastingMethod.simpleMovingAverage => 'Simple Moving Average',
      ForecastingMethod.seasonalMovingAverage => 'Seasonal Moving Average',
    };
  }

  String formatNumber(double value, {int decimals = 1}) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(decimals);
  }

  String formatCurrency(double value) {
    if (value >= 1000000) {
      return '₱${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}K';
    }

    return '₱${value.toStringAsFixed(0)}';
  }

  int get simpleRequiredPeriods => smaWindow;

  int get seasonalRequiredPeriods => seasonalMinimumPrecedingPeriods;

  String get periodNoun =>
      selectedPeriod == AnalyticsPeriod.weekly ? 'week' : 'month';

  double averageQuantity(List<PeriodPoint> points) {
    if (points.isEmpty) {
      return 0;
    }

    final total = points.fold<double>(
      0,
      (totalValue, point) => totalValue + point.quantity,
    );

    return total / points.length;
  }

  Widget snapshotMetric({
    required IconData icon,
    required String label,
    required String value,
    Color accent = const Color(0xFF146BFF),
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F9FC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE7EEF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 8.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget analyticsHeader(AnalyticsData data) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 236,
      toolbarHeight: 60,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xFF075FAE),
      foregroundColor: Colors.white,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _HeaderButton(
          icon: Icons.arrow_back_rounded,
          onTap: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      leadingWidth: 56,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.5,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF063B66), Color(0xFF0769B7), Color(0xFF176BFF)],
              stops: [0.0, 0.58, 1.0],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _AnalyticsHeaderPainter()),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.paddingOf(context).top + 64,
                  18,
                  13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(24),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withAlpha(32),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSupplier
                                    ? Icons.storefront_rounded
                                    : Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.2,
                                  letterSpacing: 0.7,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BE3FF).withAlpha(28),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Color(0xFFBFEFFF),
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'COMPLETED DATA',
                                style: TextStyle(
                                  color: Color(0xFFEAF8FF),
                                  fontSize: 7.6,
                                  letterSpacing: 0.45,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDDEFFA),
                        fontSize: 10.3,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(22),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withAlpha(28)),
                      ),
                      child: Row(
                        children: [
                          _HeaderMetric(
                            icon: Icons.receipt_long_outlined,
                            value: '${data.completedOrders}',
                            label: 'Records',
                          ),
                          Container(
                            width: 1,
                            height: 34,
                            color: Colors.white.withAlpha(28),
                          ),
                          _HeaderMetric(
                            icon: Icons.category_outlined,
                            value: '${data.products.length}',
                            label: 'Series',
                          ),
                          Container(
                            width: 1,
                            height: 34,
                            color: Colors.white.withAlpha(28),
                          ),
                          _HeaderMetric(
                            icon: Icons.payments_outlined,
                            value: data.hasCompleteAmounts
                                ? formatCurrency(data.totalAmount)
                                : '—',
                            label: amountLabel,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Color iconColor = const Color(0xFF146BFF),
    bool compact = false,
  }) {
    final cardPadding = compact ? 14.0 : 15.0;
    final iconSize = compact ? 34.0 : 36.0;
    final contentGap = compact ? 11.0 : 13.0;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 10 : 12),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 20 : 22),
        border: Border.all(color: const Color(0xFFE3ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B00152A),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(16),
                  borderRadius: BorderRadius.circular(compact ? 11 : 12),
                ),
                child: Icon(icon, color: iconColor, size: compact ? 18 : 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF102C44),
                        fontSize: compact ? 13.8 : 14.4,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFF7890A1),
                          fontSize: compact ? 9.6 : 9.9,
                          height: 1.34,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: contentGap),
          child,
        ],
      ),
    );
  }

  Widget periodSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2ECF3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodButton(
              label: 'Weekly',
              selected: selectedPeriod == AnalyticsPeriod.weekly,
              onTap: () => selectAnalyticsPeriod(AnalyticsPeriod.weekly),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              label: 'Monthly',
              selected: selectedPeriod == AnalyticsPeriod.monthly,
              onTap: () => selectAnalyticsPeriod(AnalyticsPeriod.monthly),
            ),
          ),
        ],
      ),
    );
  }

  Widget seriesSelector(AnalyticsData data) {
    final selected = data.selectedProduct;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.products.isEmpty
            ? null
            : () {
                showSeriesPicker(data);
              },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9EAF6)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9F7FF), Color(0xFFE8F3FF)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  selected?.emoji ?? '🐟',
                  style: const TextStyle(fontSize: 21),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ANALYZED SERIES',
                      style: TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 7.9,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selected == null
                          ? 'No fish series available'
                          : '${selected.productName} · ${selected.quantityUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${selected.transactionCount} completed transaction${selected.transactionCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFF8093A3),
                          fontSize: 8.9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE1EBF2)),
                ),
                child: const Icon(
                  Icons.unfold_more_rounded,
                  color: Color(0xFF527187),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showSeriesPicker(AnalyticsData data) async {
    final searchController = TextEditingController();

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(165),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchController.text.trim().toLowerCase();

            final filtered = data.products.where((product) {
              if (query.isEmpty) {
                return true;
              }

              return product.productName.toLowerCase().contains(query) ||
                  product.quantityUnit.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBFD),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 30,
                      offset: Offset(0, -12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBED0DC),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5FD),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.category_outlined,
                              color: Color(0xFF146BFF),
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Fish and Unit Series',
                                  style: TextStyle(
                                    color: Color(0xFF102C44),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Each fish and unit combination is analyzed separately.',
                                  style: TextStyle(
                                    color: Color(0xFF7B8FA3),
                                    fontSize: 10.3,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF52677A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
                      child: TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) {
                          setSheetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Search fish or unit',
                          hintStyle: const TextStyle(
                            color: Color(0xFF8BA0B1),
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF146BFF),
                          ),
                          suffixIcon: searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2ECF3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF146BFF),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: Colors.black.withAlpha(15)),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(30),
                                child: Text(
                                  'No matching series found.',
                                  style: TextStyle(
                                    color: Color(0xFF7B8FA3),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 4);
                              },
                              itemBuilder: (context, index) {
                                final product = filtered[index];
                                final isSelected =
                                    data.selectedProduct?.seriesKey ==
                                    product.seriesKey;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(
                                        sheetContext,
                                        product.seriesKey,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 170,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        13,
                                        12,
                                        12,
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE6F5FF)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF32A9FF)
                                              : const Color(0xFFE5EDF3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF7FB),
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            child: Text(
                                              product.emoji,
                                              style: const TextStyle(
                                                fontSize: 22,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${product.productName} · ${isSupplier ? supplierUnitLabel(product.quantityUnit) : product.quantityUnit}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF102C44),
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${formatNumber(product.quantity)} ${isSupplier ? supplierUnitLabel(product.quantityUnit) : product.quantityUnit} · ${product.transactionCount} transaction${product.transactionCount == 1 ? '' : 's'}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF7B8FA3),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons.chevron_right_rounded,
                                            color: isSelected
                                                ? const Color(0xFF1DBB8A)
                                                : const Color(0xFF9DB0BE),
                                            size: 21,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      selectedSeriesKey = selected;
      selectedSupplierPeriodStart = null;
      selectedSupplierChartBarIndex = null;
    });
  }

  Widget analyticsFilters(AnalyticsData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00152A),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF146BFF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis View',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 13.7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose the time window and fish series.',
                      style: TextStyle(
                        color: Color(0xFF8093A3),
                        fontSize: 9.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          periodSelector(),
          const SizedBox(height: 9),
          seriesSelector(data),
        ],
      ),
    );
  }

  Widget trendChart(List<PeriodPoint> points, {required String unit}) {
    if (points.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.show_chart_rounded,
        title: 'No completed periods for this series',
        subtitle: 'Select another fish series or complete more COD orders.',
      );
    }

    if (points.length == 1) {
      final point = points.first;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F8FF), Color(0xFFF7FBFE)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCEAF4)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF146BFF).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timeline_rounded,
                color: Color(0xFF146BFF),
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatNumber(point.quantity)} $unit',
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    periodLabel(point.date),
                    style: const TextStyle(
                      color: Color(0xFF146BFF),
                      fontSize: 9.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'One completed period is available. A trend line will appear after another completed period is recorded.',
                    style: TextStyle(
                      color: Color(0xFF71889A),
                      fontSize: 9.4,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final visible = points.length > 8
        ? points.sublist(points.length - 8)
        : points;
    final values = visible.map((point) => point.quantity).toList();
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ChartStat(
                label: 'LOW',
                value: '${formatNumber(low)} $unit',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChartStat(
                label: 'HIGH',
                value: '${formatNumber(high)} $unit',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChartStat(label: 'PERIODS', value: '${visible.length}'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 174,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7EEF4)),
          ),
          child: CustomPaint(painter: _TrendChartPainter(values: values)),
        ),
        const SizedBox(height: 8),
        Row(
          children: visible.map((point) {
            return Expanded(
              child: Text(
                periodLabel(point.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF879BAB),
                  fontSize: 7.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget selectedSeriesSummary(AnalyticsData data) {
    final product = data.selectedProduct;

    if (product == null) {
      return const SizedBox.shrink();
    }

    final points = data.selectedPoints;
    final double latest = points.isEmpty ? 0.0 : points.last.quantity;
    final average = averageQuantity(points);
    final hasForecast = data.selectedMethod.hasSelection;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F9FF), Color(0xFFF2FBF8)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCBE8E6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A00152A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERIES SNAPSHOT',
                      style: TextStyle(
                        color: Color(0xFF147D64),
                        fontSize: 8,
                        letterSpacing: 0.55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.productName} · ${isSupplier ? supplierUnitLabel(product.quantityUnit) : product.quantityUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${points.length} completed ${selectedPeriod == AnalyticsPeriod.weekly ? 'weekly' : 'monthly'} period${points.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF607A8D),
                        fontSize: 9.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DBB8A).withAlpha(18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF159C74),
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'VALIDATED',
                      style: TextStyle(
                        color: Color(0xFF147D64),
                        fontSize: 7.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              snapshotMetric(
                icon: Icons.history_rounded,
                label: 'Latest $periodNoun',
                value: points.isEmpty
                    ? '--'
                    : '${formatNumber(latest)} ${product.quantityUnit}',
              ),
              const SizedBox(width: 7),
              snapshotMetric(
                icon: Icons.stacked_line_chart_rounded,
                label: 'Avg / $periodNoun',
                value: points.isEmpty
                    ? '--'
                    : '${formatNumber(average)} ${product.quantityUnit}',
                accent: const Color(0xFF087AC0),
              ),
              const SizedBox(width: 7),
              snapshotMetric(
                icon: Icons.auto_graph_rounded,
                label: targetDescription(data.selectedPoints),
                value: hasForecast
                    ? '${formatForecastEstimate(data.selectedMethod.forecast)} ${product.quantityUnit}'
                    : 'Pending',
                accent: const Color(0xFF159C74),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget forecastMethodCard({
    required String title,
    required String description,
    required ForecastResult result,
    required String unit,
    required IconData icon,
    required int availablePeriods,
    required int requiredPeriods,
    bool selected = false,
    String selectedLabel = 'SELECTED',
  }) {
    final available = result.hasValue;
    final readiness = requiredPeriods <= 0
        ? 0.0
        : (availablePeriods / requiredPeriods).clamp(0.0, 1.0).toDouble();
    final remaining = math.max(0, requiredPeriods - availablePeriods);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFF1FAF7)
            : available
            ? const Color(0xFFF4F9FD)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected
              ? const Color(0xFFBDE7D8)
              : available
              ? const Color(0xFFD6E8F5)
              : const Color(0xFFE5EBF0),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  gradient: available
                      ? const LinearGradient(
                          colors: [Color(0xFF0875D1), Color(0xFF176BFF)],
                        )
                      : null,
                  color: available ? null : const Color(0xFFE8EEF3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: available ? Colors.white : const Color(0xFF8195A5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 12.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (selected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F5EC),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              selectedLabel,
                              style: const TextStyle(
                                color: Color(0xFF147D64),
                                fontSize: 6.9,
                                letterSpacing: 0.35,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF71889A),
                        fontSize: 9.3,
                        height: 1.28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (available)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(185),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Text(
                    'TARGET ESTIMATE',
                    style: TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 7.7,
                      letterSpacing: 0.45,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formatForecastEstimate(result.value)} $unit',
                    style: const TextStyle(
                      color: Color(0xFF0875D1),
                      fontSize: 13.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Text(
                  '$availablePeriods / $requiredPeriods periods',
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 8.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  remaining == 0 ? 'Unavailable' : '$remaining more needed',
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: readiness,
                minHeight: 6,
                backgroundColor: const Color(0xFFE6EDF2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF146BFF),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.reason,
              style: const TextStyle(
                color: Color(0xFF8A9EAD),
                fontSize: 8.8,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget evaluationTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withAlpha(38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 7.5,
                letterSpacing: 0.45,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 7.8,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget forecastEvaluationMatrix({
    required AnalyticsData data,
    required String unit,
  }) {
    final bothMethodsEligible =
        data.simpleForecast.hasValue &&
        data.seasonalForecast.hasValue &&
        data.simpleEvaluation.hasMape &&
        data.seasonalEvaluation.hasMape &&
        data.simpleEvaluation.commonTargets;

    Widget cell(
      String text, {
      required int flex,
      bool header = false,
      Color? color,
      TextAlign alignment = TextAlign.left,
    }) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment,
          style: TextStyle(
            color:
                color ??
                (header ? const Color(0xFF5F778B) : const Color(0xFF102C44)),
            fontSize: header ? 7.1 : 8.1,
            height: 1.2,
            fontWeight: header ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      );
    }

    Widget row({
      required String method,
      required ForecastingMethod forecastingMethod,
      required ForecastEvaluation evaluation,
    }) {
      final selected = data.selectedMethod.method == forecastingMethod;
      final validPairs = evaluation.hasMape
          ? evaluation.mapePairCount
          : evaluation.maePairCount;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FAF6) : Colors.transparent,
          border: const Border(top: BorderSide(color: Color(0xFFE5EDF2))),
        ),
        child: Row(
          children: [
            cell(
              method,
              flex: 27,
              color: selected ? const Color(0xFF147D64) : null,
            ),
            cell(
              evaluation.hasMape
                  ? '${evaluation.mape.toStringAsFixed(2)}%'
                  : 'N/A',
              flex: 18,
              alignment: TextAlign.center,
            ),
            cell(
              evaluation.hasMae
                  ? '${formatNumber(evaluation.mae)} $unit'
                  : 'N/A',
              flex: 22,
              alignment: TextAlign.center,
            ),
            cell(
              evaluation.hasMae ? '$validPairs' : '—',
              flex: 12,
              alignment: TextAlign.center,
            ),
            cell(
              selected
                  ? bothMethodsEligible
                        ? 'Selected'
                        : 'Only eligible'
                  : evaluation.hasMae && evaluation.hasMape
                  ? 'Not selected'
                  : evaluation.hasMae
                  ? 'Not eligible'
                  : 'Pending',
              flex: 21,
              color: selected
                  ? const Color(0xFF147D64)
                  : const Color(0xFF6F8495),
              alignment: TextAlign.right,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1EAF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 7),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  color: Color(0xFF087AC0),
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'FORECAST EVALUATION MATRIX',
                  style: TextStyle(
                    color: Color(0xFF24445E),
                    fontSize: 7.8,
                    letterSpacing: 0.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Row(
              children: [
                cell('Method', flex: 27, header: true),
                cell(
                  'MAPE',
                  flex: 18,
                  header: true,
                  alignment: TextAlign.center,
                ),
                cell(
                  'MAE',
                  flex: 22,
                  header: true,
                  alignment: TextAlign.center,
                ),
                cell(
                  'Pairs',
                  flex: 12,
                  header: true,
                  alignment: TextAlign.center,
                ),
                cell(
                  'Decision',
                  flex: 21,
                  header: true,
                  alignment: TextAlign.right,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              bothMethodsEligible
                  ? 'Common targets: MAPE ${data.simpleEvaluation.mapePairCount}; MAE ${data.simpleEvaluation.maePairCount}.'
                  : 'Separate method histories; no direct comparison.',
              style: const TextStyle(fontSize: 8, color: Color(0xFF627B8E)),
            ),
          ),
          row(
            method: 'Simple\nMoving Average',
            forecastingMethod: ForecastingMethod.simpleMovingAverage,
            evaluation: data.simpleEvaluation,
          ),
          row(
            method: 'Seasonal\nMoving Average',
            forecastingMethod: ForecastingMethod.seasonalMovingAverage,
            evaluation: data.seasonalEvaluation,
          ),
          if (data.simpleEvaluation.zeroActualMapeExclusions > 0 ||
              data.seasonalEvaluation.zeroActualMapeExclusions > 0)
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Text(
                'Zero-actual pairs are excluded from MAPE and retained in MAE.',
                style: TextStyle(
                  color: Color(0xFF71879A),
                  fontSize: 7.8,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget forecastEvaluation(AnalyticsData data) {
    final product = data.selectedProduct;

    if (product == null) {
      return const SizedBox.shrink();
    }

    final displayUnit = isSupplier
        ? supplierUnitLabel(product.quantityUnit)
        : product.quantityUnit;
    final selection = data.selectedMethod;
    final selectedEvaluation =
        selection.method == ForecastingMethod.simpleMovingAverage
        ? data.simpleEvaluation
        : selection.method == ForecastingMethod.seasonalMovingAverage
        ? data.seasonalEvaluation
        : null;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: selection.hasSelection
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEAF8F3), Color(0xFFEEF8FC)],
                  )
                : null,
            color: selection.hasSelection ? null : const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selection.hasSelection
                  ? const Color(0xFFC4E7DD)
                  : const Color(0xFFE2E9EE),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selection.hasSelection
                      ? const Color(0xFF159C74).withAlpha(18)
                      : const Color(0xFFE8EDF1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  selection.hasSelection
                      ? Icons.workspace_premium_rounded
                      : Icons.hourglass_top_rounded,
                  color: selection.hasSelection
                      ? const Color(0xFF159C74)
                      : const Color(0xFF7B8FA3),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selection.hasSelection
                          ? forecastingMethodLabel(selection.method!)
                          : !data.simpleForecast.hasValue &&
                                !data.seasonalForecast.hasValue
                          ? 'Forecast unavailable'
                          : 'Method selection pending',
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selection.reason,
                      style: const TextStyle(
                        color: Color(0xFF6E8495),
                        fontSize: 8.8,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (selection.hasSelection)
                Text(
                  '${formatForecastEstimate(selection.forecast)}\n$displayUnit',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF087AC0),
                    fontSize: 11.2,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
        forecastEvaluationMatrix(data: data, unit: displayUnit),
        if (selectedEvaluation != null && selectedEvaluation.hasMape)
          forecastReliabilityNote(evaluation: selectedEvaluation),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FB),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF5D7890),
                size: 15,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Lower MAPE is preferred. MAE is used to break a MAPE tie.',
                  style: TextStyle(
                    color: Color(0xFF627B8E),
                    fontSize: 8.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget forecastReliabilityNote({required ForecastEvaluation evaluation}) {
    const label = 'Historical evaluation';
    final message = analyticsEvaluationHistory(evaluation);
    const color = Color(0xFF087AC0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withAlpha(42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF627B8E),
                    fontSize: 8.2,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget variabilityPanel(double? value) {
    final label = value == null ? 'CV unavailable' : 'Coefficient of variation';
    final message = analyticsVariabilityDescription(value);
    const color = Color(0xFF087AC0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              value == null ? '--' : '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9.8,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget suggestions(List<RestockingSuggestion> suggestions) {
    if (suggestions.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No restocking suggestion yet',
        subtitle: 'Current planning requires recent consecutive closed periods and an accuracy-eligible method. Missing periods are not zero. Review History for past forecasts.',
      );
    }

    return Column(
      children: suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F9FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDEBF3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7FC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  suggestion.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSupplier
                          ? 'Estimated sales for ${supplierPeriodRange(suggestion.targetDate)}: ${formatForecastEstimate(suggestion.suggestedQuantity)} ${supplierUnitLabel(suggestion.quantityUnit)}.'
                          : 'Estimated purchases for ${supplierPeriodRange(suggestion.targetDate)}: ${formatForecastEstimate(suggestion.suggestedQuantity)} ${suggestion.quantityUnit}.',
                      style: const TextStyle(
                        color: Color(0xFF657C8E),
                        fontSize: 10.1,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Based on ${forecastingMethodLabel(suggestion.selectedMethod)}.',
                      style: const TextStyle(
                        color: Color(0xFF087AC0),
                        fontSize: 8.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (suggestion.evaluationNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        suggestion.evaluationNote,
                        style: const TextStyle(
                          color: Color(0xFF627B8E),
                          fontSize: 8.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget stockAlerts(List<StockAlert> alerts) {
    if (alerts.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No stock alerts',
        subtitle: 'Current supplier inventory does not require attention.',
      );
    }

    return Column(
      children: alerts.take(5).map((alert) {
        final outOfStock = alert.quantity <= 0;
        final color = outOfStock
            ? const Color(0xFFD32F2F)
            : const Color(0xFFFF7A1A);

        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(alert.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatNumber(alert.quantity)} ${supplierUnitLabel(alert.quantityUnit)} remaining · Alert at ${formatNumber(alert.lowStockLevel)} ${supplierUnitLabel(alert.quantityUnit)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 9.8,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  outOfStock ? 'OUT' : 'LOW',
                  style: TextStyle(
                    color: color,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget topProducts(List<ProductSummary> products) {
    final ranked =
        analyticsRankingBasis(products) != AnalyticsRankingBasis.unavailable;
    return Column(
      children: products.take(5).toList().asMap().entries.map((entry) {
        final product = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9FC),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              if (ranked)
                Container(
                  width: 30,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF146BFF).withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: Color(0xFF146BFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (ranked) const SizedBox(width: 9),
              Text(product.emoji, style: const TextStyle(fontSize: 21)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.productName} · ${isSupplier ? supplierUnitLabel(product.quantityUnit) : product.quantityUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatNumber(product.quantity)} ${isSupplier ? supplierUnitLabel(product.quantityUnit) : product.quantityUnit} · ${product.transactionCount} transaction${product.transactionCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                product.hasCompleteAmounts
                    ? formatCurrency(product.amount)
                    : 'Amount unavailable',
                style: const TextStyle(
                  color: Color(0xFF0875D1),
                  fontSize: 11.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget roleDataNote(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF7FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD5EAF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: Color(0xFF146BFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATA USED',
                  style: TextStyle(
                    color: Color(0xFF146BFF),
                    fontSize: 7.6,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSupplier
                      ? 'Closed periods only: ${data.historicalTransactions} validated historical sale${data.historicalTransactions == 1 ? '' : 's'} + ${data.liveCompletedOrders} completed live COD sale${data.liveCompletedOrders == 1 ? '' : 's'}. Inventory is used only for stock alerts.'
                      : 'Closed periods only: ${data.historicalTransactions} validated historical purchase${data.historicalTransactions == 1 ? '' : 's'} + ${data.liveCompletedOrders} completed live COD purchase${data.liveCompletedOrders == 1 ? '' : 's'}. Supplier-side sales are excluded.',
                  style: const TextStyle(
                    color: Color(0xFF587286),
                    fontSize: 9.3,
                    height: 1.32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget noDataOverview(AnalyticsData data) {
    return CustomScrollView(
      slivers: [
        analyticsHeader(data),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE1EBF2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE8F6FF), Color(0xFFE9FBF5)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF9BD8F9)),
                      ),
                      child: Icon(
                        isSupplier
                            ? Icons.storefront_outlined
                            : Icons.shopping_bag_outlined,
                        color: const Color(0xFF146BFF),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      emptyDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6D8293),
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7FB),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF146BFF),
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Forecast values are hidden until sufficient completed periods exist. Zero is never used as a placeholder.',
                              style: TextStyle(
                                color: Color(0xFF52677A),
                                fontSize: 9.8,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            widget.onBack ?? () => Navigator.pop(context),
                        icon: Icon(
                          isSupplier
                              ? Icons.receipt_long_outlined
                              : Icons.storefront_outlined,
                          size: 20,
                        ),
                        label: Text(
                          emptyActionLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF146BFF),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0x55146BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSupplier && data.stockAlerts.isNotEmpty) ...[
                const SizedBox(height: 14),
                sectionCard(
                  title: 'Stock Alerts',
                  subtitle: 'Current low-stock and out-of-stock listings still require attention.',
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFFF7A1A),
                  child: stockAlerts(data.stockAlerts),
                ),
              ],
              roleDataNote(data),
            ]),
          ),
        ),
      ],
    );
  }

  String supplierUnitLabel(String unit) {
    return switch (normalizeAnalyticsUnit(unit)) {
      'kilogram' => 'kilo',
      'icebox' => 'icebox',
      'tab' => 'tab',
      final value => value,
    };
  }

  String supplierMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String supplierPeriodRange(DateTime date, {bool includeYear = true}) {
    final start = periodStart(date);

    if (selectedPeriod == AnalyticsPeriod.monthly) {
      return includeYear
          ? '${supplierMonthName(start.month)} ${start.year}'
          : supplierMonthName(start.month);
    }

    final end = start.add(const Duration(days: 6));
    if (includeYear && start.year != end.year) {
      return '${supplierMonthName(start.month)} ${start.day}, ${start.year}–${supplierMonthName(end.month)} ${end.day}, ${end.year}';
    }
    final yearSuffix = includeYear ? ', ${end.year}' : '';

    if (start.month == end.month) {
      return '${supplierMonthName(start.month)} ${start.day}–${end.day}$yearSuffix';
    }

    return '${supplierMonthName(start.month)} ${start.day}–${supplierMonthName(end.month)} ${end.day}$yearSuffix';
  }

  String supplierAxisLabel(DateTime date) {
    final start = periodStart(date);

    if (selectedPeriod == AnalyticsPeriod.monthly) {
      return supplierMonthName(start.month);
    }

    return '${supplierMonthName(start.month)} ${start.day}';
  }

  DateTime? supplierSelectedPeriodDate(AnalyticsData data) {
    final points = data.selectedPoints;

    if (points.isEmpty) {
      return null;
    }

    final requested = selectedSupplierPeriodStart;

    if (requested != null) {
      for (final point in points) {
        if (sameAnalyticsPeriod(point.date, requested)) {
          return point.date;
        }
      }
    }

    return points.last.date;
  }

  PeriodPoint? supplierSelectedPoint(AnalyticsData data) {
    final selectedDate = supplierSelectedPeriodDate(data);

    if (selectedDate == null) {
      return null;
    }

    return pointForAnalyticsPeriod(data.selectedPoints, selectedDate);
  }

  int supplierSelectedPointIndex(AnalyticsData data) {
    final selectedDate = supplierSelectedPeriodDate(data);

    if (selectedDate == null) {
      return -1;
    }

    return data.selectedPoints.indexWhere(
      (point) => sameAnalyticsPeriod(point.date, selectedDate),
    );
  }

  void moveSupplierPeriod(AnalyticsData data, int offset) {
    final index = supplierSelectedPointIndex(data);
    final targetIndex = index + offset;

    if (index < 0 ||
        targetIndex < 0 ||
        targetIndex >= data.selectedPoints.length) {
      return;
    }

    setState(() {
      selectedSupplierPeriodStart = data.selectedPoints[targetIndex].date;
      selectedSupplierChartBarIndex = null;
    });
  }

  List<PeriodPoint> supplierPointsThroughSelection(AnalyticsData data) {
    final selectedDate = supplierSelectedPeriodDate(data);

    if (selectedDate == null) {
      return const [];
    }

    final points = <PeriodPoint>[];

    for (final point in data.selectedPoints) {
      if (point.date.isAfter(selectedDate) &&
          !sameAnalyticsPeriod(point.date, selectedDate)) {
        break;
      }
      points.add(point);
    }

    return points;
  }

  _SupplierForecastSnapshot supplierForecastSnapshot(AnalyticsData data) =>
      _SupplierForecastSnapshot(selectedMethod: data.selectedMethod);

  String supplierFullCurrency(double value) {
    final rounded = value.round().abs().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < rounded.length; index++) {
      if (index > 0 && (rounded.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(rounded[index]);
    }

    return '${value < 0 ? '-' : ''}₱${buffer.toString()}';
  }

  Widget supplierAnalyticsHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    final delegate = _SupplierAnalyticsHeaderDelegate(
      topPadding: topPadding,
      onBack: () => Navigator.of(context).maybePop(),
      title: isSupplier ? 'Supplier Analytics' : 'Vendor Analytics',
      eyebrow: isSupplier ? 'SUPPLIER INSIGHTS' : 'VENDOR INSIGHTS',
      subtitle: isSupplier
          ? 'Sales, forecasts, and stock planning at a glance.'
          : 'Purchases, forecasts, and restocking at a glance.',
      backgroundAsset: 'assets/images/isdalink_main_header.png',
    );

    // Keep the Supplier Analytics hero as a normal scrollable header, just
    // like the other dashboard screens. It moves completely off-screen with
    // the page instead of collapsing into a pinned toolbar.
    return SliverToBoxAdapter(
      child: SizedBox(
        height: delegate.maxExtent,
        child: delegate.build(context, 0, false),
      ),
    );
  }

  Widget supplierSummaryFilters(AnalyticsData data, {bool includeFish = true}) {
    final selected = data.selectedProduct;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0EAF1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SupplierSegmentButton(
                    label: 'Weekly',
                    selected: selectedPeriod == AnalyticsPeriod.weekly,
                    onTap: () => selectAnalyticsPeriod(AnalyticsPeriod.weekly),
                  ),
                ),
                Expanded(
                  child: _SupplierSegmentButton(
                    label: 'Monthly',
                    selected: selectedPeriod == AnalyticsPeriod.monthly,
                    onTap: () => selectAnalyticsPeriod(AnalyticsPeriod.monthly),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (includeFish) const SizedBox(width: 9),
        if (includeFish)
          Expanded(
            flex: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: data.products.isEmpty
                    ? null
                    : () => showSeriesPicker(data),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0EAF1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selected?.emoji ?? '🐟',
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selected == null
                                ? 'Select fish'
                                : '${selected.productName} · ${supplierUnitLabel(selected.quantityUnit)}',
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFF0B2470),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF0B2470),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget supplierPeriodNavigation(AnalyticsData data) {
    final date = supplierSelectedPeriodDate(data);
    final index = supplierSelectedPointIndex(data);
    final canMoveBack = index > 0;
    final canMoveForward = index >= 0 && index < data.selectedPoints.length - 1;

    return Row(
      children: [
        _SupplierCircleButton(
          icon: Icons.chevron_left_rounded,
          enabled: canMoveBack,
          onTap: () => moveSupplierPeriod(data, -1),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFD),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFFE0EAF1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF0877D8),
                  size: 20,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      date == null
                          ? 'No completed period'
                          : supplierPeriodRange(date),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF0B2470),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 7),
        _SupplierCircleButton(
          icon: Icons.chevron_right_rounded,
          enabled: canMoveForward,
          onTap: () => moveSupplierPeriod(data, 1),
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: data.selectedPoints.isEmpty
              ? null
              : () => showSupplierHistory(data),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0877D8),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          ),
          child: const Text(
            'History',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Future<void> showSupplierHistory(AnalyticsData data) async {
    final product = data.selectedProduct;

    if (product == null || data.selectedPoints.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final points = data.selectedPoints.reversed.toList();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E2EA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSupplier ? 'Sales History' : 'Purchase History',
                            style: const TextStyle(
                              color: Color(0xFF0B2470),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${product.productName} · ${supplierUnitLabel(product.quantityUnit)}',
                            style: const TextStyle(
                              color: Color(0xFF7185A2),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE7EEF4)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: points.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFEEF3F7)),
                  itemBuilder: (context, index) {
                    final point = points[index];
                    final selectedDate = supplierSelectedPeriodDate(data);
                    final isSelected =
                        selectedDate != null &&
                        sameAnalyticsPeriod(selectedDate, point.date);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      onTap: () {
                        setState(() {
                          selectedSupplierPeriodStart = point.date;
                          selectedSupplierChartBarIndex = null;
                        });
                        Navigator.pop(sheetContext);
                      },
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE7F3FF)
                              : const Color(0xFFF4F8FB),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          color: isSelected
                              ? const Color(0xFF0877D8)
                              : const Color(0xFF7890A5),
                          size: 19,
                        ),
                      ),
                      title: Text(
                        supplierPeriodRange(point.date),
                        style: const TextStyle(
                          color: Color(0xFF17346F),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        '${formatNumber(point.quantity)} ${supplierUnitLabel(product.quantityUnit)} · ${point.hasCompleteAmounts ? supplierFullCurrency(point.amount) : 'Amount unavailable'}',
                        style: const TextStyle(
                          color: Color(0xFF73879C),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Text(
                        '${point.transactionCount} order${point.transactionCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFF0877D8),
                          fontSize: 10.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget supplierSummaryMetrics(AnalyticsData data) {
    final point = supplierSelectedPoint(data);
    final unit = supplierUnitLabel(
      data.selectedProduct?.quantityUnit ?? 'unit',
    );

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B00152A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FB),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SupplierSummaryMetric(
                icon: Icons.inventory_2_outlined,
                label: isSupplier ? 'Quantity Sold' : 'Quantity Purchased',
                value: point == null ? '—' : formatNumber(point.quantity),
                suffix: unit,
              ),
            ),
            const _SupplierMetricDivider(),
            Expanded(
              child: _SupplierSummaryMetric(
                icon: Icons.payments_outlined,
                label: isSupplier ? 'Sales' : 'Amount Spent',
                value: point == null || !point.hasCompleteAmounts
                    ? '—'
                    : supplierFullCurrency(point.amount),
                valueFontSize: 20.5,
              ),
            ),
            const _SupplierMetricDivider(),
            Expanded(
              child: _SupplierSummaryMetric(
                icon: Icons.groups_2_outlined,
                label: 'Orders',
                value: point == null ? '—' : '${point.transactionCount}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget supplierSalesChartCard(AnalyticsData data) {
    final selectedDate = supplierSelectedPeriodDate(data);
    final points = selectedDate == null
        ? const <PeriodPoint>[]
        : data.selectedPoints
              .where(
                (point) =>
                    point.date.isBefore(selectedDate) ||
                    sameAnalyticsPeriod(point.date, selectedDate),
              )
              .toList();
    final visible = points.length > 6
        ? points.sublist(points.length - 6)
        : points;
    final selectedBarIndex =
        selectedSupplierChartBarIndex != null &&
            selectedSupplierChartBarIndex! >= 0 &&
            selectedSupplierChartBarIndex! < visible.length
        ? selectedSupplierChartBarIndex
        : null;
    final unit = supplierUnitLabel(
      data.selectedProduct?.quantityUnit ?? 'unit',
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B00152A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedPeriod == AnalyticsPeriod.weekly
                ? (isSupplier ? 'Weekly Sales' : 'Weekly Purchases')
                : (isSupplier ? 'Monthly Sales' : 'Monthly Purchases'),
            style: const TextStyle(
              color: Color(0xFF0B2470),
              fontSize: 16.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const SizedBox(
              height: 190,
              child: Center(
                child: Text(
                  'No completed periods yet.',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 184,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      const left = 42.0;
                      const right = 6.0;
                      final chartWidth = math.max(
                        1.0,
                        constraints.maxWidth - left - right,
                      );
                      final x = details.localPosition.dx;

                      if (x < left || x > left + chartWidth) {
                        setState(() => selectedSupplierChartBarIndex = null);
                        return;
                      }

                      final slotWidth = chartWidth / visible.length;
                      final index = ((x - left) / slotWidth).floor();

                      if (index < 0 || index >= visible.length) {
                        return;
                      }

                      setState(() {
                        selectedSupplierChartBarIndex =
                            selectedSupplierChartBarIndex == index
                            ? null
                            : index;
                      });
                    },
                    child: CustomPaint(
                      painter: _SupplierBarChartPainter(
                        values: visible.map((point) => point.quantity).toList(),
                        labels: visible
                            .map((point) => supplierAxisLabel(point.date))
                            .toList(),
                        selectedIndex: selectedBarIndex,
                        unitLabel: unit,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget supplierForecastCard(AnalyticsData data) {
    final product = data.selectedProduct;
    final target = targetForPoints(data.selectedPoints);
    final snapshot = supplierForecastSnapshot(data);
    final selection = snapshot.selectedMethod;
    final unit = supplierUnitLabel(product?.quantityUnit ?? 'unit');
    final targetDate = target.date;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B00152A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF079447),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.historical
                          ? 'Historical forecast'
                          : 'Current $periodNoun forecast',
                      style: const TextStyle(
                        color: Color(0xFF0B2470),
                        fontSize: 15.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (selection.hasSelection)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 7,
                        children: [
                          Text(
                            formatForecastEstimate(selection.forecast),
                            style: const TextStyle(
                              color: Color(0xFF0B2470),
                              fontSize: 30,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              unit,
                              style: const TextStyle(
                                color: Color(0xFF5871A1),
                                fontSize: 13.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'No selected forecast',
                        style: TextStyle(
                          color: Color(0xFF0B2470),
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ...[
                      const SizedBox(height: 3),
                      Text(
                        supplierPeriodRange(targetDate),
                        style: const TextStyle(
                          color: Color(0xFF5871A1),
                          fontSize: 11.9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          const Divider(height: 1, color: Color(0xFFE6EDF3)),
          const SizedBox(height: 10),
          Text(
            selection.hasSelection && product != null
                ? target.historical
                      ? 'Estimate after the selected historical period; not current planning advice.'
                      : 'Estimated ${isSupplier ? 'sales' : 'purchases'} for ${supplierPeriodRange(targetDate)}. Use as planning guidance only.'
                : !data.simpleForecast.hasValue &&
                      !data.seasonalForecast.hasValue
                ? target.historical
                      ? 'Insufficient preceding completed-period history for this historical target.'
                      : 'Insufficient recent completed-period history for current planning. Review History for past forecasts.'
                : 'A method forecast is available in Accuracy; accuracy-based selection is pending. ${selection.reason}',
            style: const TextStyle(
              color: Color(0xFF5871A1),
              fontSize: 11.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget supplierCurrentPeriodNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: Color(0xFF0877D8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Current ${selectedPeriod == AnalyticsPeriod.weekly ? 'week' : 'month'} in progress · not included yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF17346F),
                fontSize: 10.6,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget supplierDateContext(
    AnalyticsData data, {
    bool currentPlanningOnly = false,
    DateTime? now,
  }) {
    final target = currentPlanningOnly
        ? analyticsForecastTarget(
            now: now ?? DateTime.now(),
            monthly: selectedPeriod == AnalyticsPeriod.monthly,
          )
        : targetForPoints(data.selectedPoints, now: now);
    final recordedDate = supplierSelectedPeriodDate(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          target.historical ? 'Historical view' : 'Current planning',
          style: const TextStyle(
            color: Color(0xFF0877D8),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        if (currentPlanningOnly)
          const Text(
            'All fish · each quantity unit kept separate',
            style: TextStyle(color: Color(0xFF5871A1), fontSize: 11.5),
          )
        else
          Text(
            recordedDate == null
                ? 'No recorded closed period for this fish'
                : '${target.historical ? 'Selected history' : 'Latest recorded period'}: ${supplierPeriodRange(recordedDate)}',
            style: const TextStyle(color: Color(0xFF5871A1), fontSize: 11.5),
          ),
        const SizedBox(height: 4),
        Text(
          '${target.historical ? 'Historical forecast target' : 'Planning target'}: ${supplierPeriodRange(target.date)}',
          style: const TextStyle(
            color: Color(0xFF17346F),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget supplierControlPanel(
    AnalyticsData data, {
    bool currentPlanningOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00152A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          supplierSummaryFilters(data, includeFish: !currentPlanningOnly),
          const SizedBox(height: 9),
          const Divider(height: 1, color: Color(0xFFEDF2F6)),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerLeft,
            child: supplierDateContext(
              data,
              currentPlanningOnly: currentPlanningOnly,
            ),
          ),
          if (!currentPlanningOnly) ...[
            const SizedBox(height: 9),
            const Divider(height: 1, color: Color(0xFFEDF2F6)),
            const SizedBox(height: 9),
            supplierPeriodNavigation(data),
            if (targetForPoints(data.selectedPoints).historical)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    selectedSupplierPeriodStart = null;
                    selectedSupplierChartBarIndex = null;
                  }),
                  child: const Text('Current planning'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget supplierSummaryTab(AnalyticsData data) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          supplierControlPanel(data),
          const SizedBox(height: 10),
          supplierSummaryMetrics(data),
          const SizedBox(height: 10),
          supplierSalesChartCard(data),
          const SizedBox(height: 10),
          supplierForecastCard(data),
          if (isSupplier) ...[
            const SizedBox(height: 9),
            supplierCurrentPeriodNotice(),
          ],
        ]),
      ),
    );
  }

  Widget supplierAccuracyTab(AnalyticsData data) {
    final selectedProduct = data.selectedProduct;
    final unit = supplierUnitLabel(selectedProduct?.quantityUnit ?? 'unit');
    final bothForecastMethodsEligible =
        data.simpleForecast.hasValue &&
        data.seasonalForecast.hasValue &&
        data.simpleEvaluation.hasMape &&
        data.seasonalEvaluation.hasMape &&
        data.simpleEvaluation.commonTargets;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          supplierControlPanel(data),
          const SizedBox(height: 10),
          sectionCard(
            title: 'Forecast Methods',
            subtitle: targetDescription(data.selectedPoints),
            icon: Icons.trending_up_rounded,
            compact: true,
            child: Column(
              children: [
                forecastMethodCard(
                  title: 'Simple Moving Average',
                  description: selectedPeriod == AnalyticsPeriod.weekly
                      ? 'Uses the 4 immediately preceding weekly observations.'
                      : 'Uses the 3 immediately preceding monthly observations.',
                  result: data.simpleForecast,
                  unit: unit,
                  icon: Icons.show_chart_rounded,
                  availablePeriods: availableForecastPeriods(
                    data.selectedPoints,
                    simpleRequiredPeriods,
                  ),
                  requiredPeriods: simpleRequiredPeriods,
                  selected:
                      data.selectedMethod.method ==
                      ForecastingMethod.simpleMovingAverage,
                  selectedLabel: bothForecastMethodsEligible
                      ? 'BEST FIT'
                      : 'ONLY ELIGIBLE',
                ),
                forecastMethodCard(
                  title: 'Seasonal Moving Average',
                  description: selectedPeriod == AnalyticsPeriod.weekly
                      ? 'Uses configured offsets of 4, 8 and 12 weeks; requires all 12 preceding closed weeks.'
                      : 'Uses configured offsets of 12 and 24 months; requires all 24 preceding closed months.',
                  result: data.seasonalForecast,
                  unit: unit,
                  icon: Icons.calendar_month_rounded,
                  availablePeriods: availableForecastPeriods(
                    data.selectedPoints,
                    seasonalRequiredPeriods,
                  ),
                  requiredPeriods: seasonalRequiredPeriods,
                  selected:
                      data.selectedMethod.method ==
                      ForecastingMethod.seasonalMovingAverage,
                  selectedLabel: bothForecastMethodsEligible
                      ? 'BEST FIT'
                      : 'ONLY ELIGIBLE',
                ),
              ],
            ),
          ),
          sectionCard(
            title: 'Forecast Accuracy',
            subtitle:
                'Forecast accuracy based on completed historical periods.',
            icon: Icons.track_changes_rounded,
            compact: true,
            child: forecastEvaluation(data),
          ),
          sectionCard(
            title: isSupplier ? 'Sales Variability' : 'Purchase Variability',
            subtitle: isSupplier
                ? 'How much completed sales change between periods.'
                : 'How much completed purchases change between periods.',
            icon: Icons.multiline_chart_rounded,
            compact: true,
            child: variabilityPanel(data.variability),
          ),
        ]),
      ),
    );
  }

  Widget supplierGuidanceTab(AnalyticsData data) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          supplierControlPanel(data, currentPlanningOnly: true),
          const SizedBox(height: 10),
          sectionCard(
            title: 'Restocking Guidance',
            subtitle: isSupplier
                ? 'Current $periodNoun sales estimates; decision support only.'
                : 'Current $periodNoun purchase estimates; decision support only.',
            icon: Icons.assignment_outlined,
            compact: true,
            child: suggestions(data.suggestions),
          ),
          if (isSupplier)
            sectionCard(
              title: 'Stock Alerts',
              subtitle:
                  'Low-stock and out-of-stock items that may need attention.',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFFFF7A1A),
              compact: true,
              child: stockAlerts(data.stockAlerts),
            ),
        ]),
      ),
    );
  }

  Widget supplierProductsTab(AnalyticsData data) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          sectionCard(
            title: analyticsRankingTitle(
              analyticsRankingBasis(data.products),
              supplier: isSupplier,
            ),
            subtitle: data.rankingBasis,
            icon: Icons.inventory_2_outlined,
            compact: true,
            child: topProducts(data.products),
          ),
        ]),
      ),
    );
  }

  Widget supplierAnalyticsContent(AnalyticsData data) {
    final bodySliver = switch (selectedSupplierTab) {
      SupplierAnalyticsTab.summary => supplierSummaryTab(data),
      SupplierAnalyticsTab.accuracy => supplierAccuracyTab(data),
      SupplierAnalyticsTab.guidance => supplierGuidanceTab(data),
      SupplierAnalyticsTab.products => supplierProductsTab(data),
    };

    return analyticsScrollArea(
      CustomScrollView(
        controller: _supplierScrollController,
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        slivers: [
          supplierAnalyticsHeader(),
          if (!isSupplier) vendorSectionNavigation(),
          bodySliver,
        ],
      ),
    );
  }

  Widget analyticsScrollArea(Widget child) {
    if (isSupplier) {
      return child;
    }
    // Match Order Center and Account Center: the hero extends behind the
    // status bar and includes the system inset in its own total height.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(color: const Color(0xFFF4F8FB), child: child),
    );
  }

  Widget vendorSectionNavigation() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _AnalyticsSectionHeader(
        child: AnalyticsSectionTabs(
          selectedTab: selectedSupplierTab,
          onSelected: (tab) {
            if (selectedSupplierTab != tab) {
              setState(() => selectedSupplierTab = tab);
            }
            _scrollSupplierToTop();
          },
        ),
      ),
    );
  }

  Widget supplierBottomNavigation() {
    const items = [
      (SupplierAnalyticsTab.summary, Icons.pie_chart_rounded, 'Summary'),
      (SupplierAnalyticsTab.accuracy, Icons.track_changes_rounded, 'Accuracy'),
      (SupplierAnalyticsTab.guidance, Icons.description_outlined, 'Guidance'),
      (SupplierAnalyticsTab.products, Icons.inventory_2_outlined, 'Products'),
    ];

    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x22001E3C),
      child: SafeArea(
        top: false,
        child: Container(
          height: 62,
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE1EAF1))),
          ),
          child: Row(
            children: items.map((item) {
              final selected = selectedSupplierTab == item.$1;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (selectedSupplierTab == item.$1) {
                      _scrollSupplierToTop();
                      return;
                    }

                    setState(() {
                      selectedSupplierTab = item.$1;
                    });
                    _scrollSupplierToTop();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$2,
                        color: selected
                            ? const Color(0xFF0877D8)
                            : const Color(0xFF63779B),
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF0877D8)
                              : const Color(0xFF63779B),
                          fontSize: 9.8,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget supplierNoDataOverview(AnalyticsData data) {
    return analyticsScrollArea(
      CustomScrollView(
        controller: _supplierScrollController,
        primary: false,
        physics: const ClampingScrollPhysics(),
        slivers: [
          supplierAnalyticsHeader(),
          if (!isSupplier) vendorSectionNavigation(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD9E7F1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF0877D8),
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isSupplier
                            ? 'No completed sales history yet'
                            : 'No completed purchase history yet',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0B2470),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        isSupplier
                            ? 'Validated historical sales and completed COD orders will appear here once enough data is available.'
                            : 'Validated historical purchases and completed COD orders will appear here once enough data is available.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6D8197),
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget supplierLoadingBody() {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        supplierAnalyticsHeader(),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF0877D8),
            ),
          ),
        ),
      ],
    );
  }

  Widget supplierErrorBody() {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        supplierAnalyticsHeader(),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Center(
              child: _CompactEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load analytics',
                subtitle: 'Analytics could not be loaded right now. Refresh and try again.',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget analyticsContent(AnalyticsData data) {
    final content =
        data.hasTransactions ||
            selectedSupplierTab == SupplierAnalyticsTab.guidance
        ? supplierAnalyticsContent(data)
        : supplierNoDataOverview(data);
    if (data.identityConflicts == 0) return content;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${data.identityConflicts} linked records excluded because account details conflict or are missing. Check the source records.',
              style: const TextStyle(color: Color(0xFF9A5200), fontSize: 12),
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget loadingBody() {
    return supplierLoadingBody();
  }

  Widget errorBody(Object error) {
    return supplierErrorBody();
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8FB),
        body: Center(
          child: Text(
            'Please log in first to view analytics.',
            style: TextStyle(
              color: Color(0xFFD32F2F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      bottomNavigationBar: isSupplier ? supplierBottomNavigation() : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ordersStream(user.uid),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.hasError) {
            return errorBody(orderSnapshot.error!);
          }

          if (!orderSnapshot.hasData) {
            return loadingBody();
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: historicalTransactionsStream(user.uid),
            builder: (context, historicalSnapshot) {
              if (historicalSnapshot.hasError) {
                return errorBody(historicalSnapshot.error!);
              }

              if (!historicalSnapshot.hasData) {
                return loadingBody();
              }

              if (!isSupplier) {
                final data = buildAnalyticsData(
                  orders: orderSnapshot.data!.docs,
                  historicalTransactions: historicalSnapshot.data!.docs,
                  stocks: const [],
                );

                return analyticsContent(data);
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: supplierStocksStream(user.uid),
                builder: (context, stockSnapshot) {
                  if (stockSnapshot.hasError) {
                    return errorBody(stockSnapshot.error!);
                  }

                  if (!stockSnapshot.hasData) {
                    return loadingBody();
                  }

                  final data = buildAnalyticsData(
                    orders: orderSnapshot.data!.docs,
                    historicalTransactions: historicalSnapshot.data!.docs,
                    stocks: stockSnapshot.data!.docs,
                  );

                  return analyticsContent(data);
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Local Analytics sections; Vendor's main app navigation stays at the bottom.
class AnalyticsSectionTabs extends StatelessWidget {
  const AnalyticsSectionTabs({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  final SupplierAnalyticsTab selectedTab;
  final ValueChanged<SupplierAnalyticsTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (SupplierAnalyticsTab.summary, 'Summary'),
      (SupplierAnalyticsTab.accuracy, 'Accuracy'),
      (SupplierAnalyticsTab.guidance, 'Guidance'),
      (SupplierAnalyticsTab.products, 'Products'),
    ];
    return ColoredBox(
      color: const Color(0xFFF4F8FB),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: items.map((item) {
              final selected = selectedTab == item.$1;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  child: InkWell(
                    key: ValueKey('analytics_section_${item.$1.name}'),
                    onTap: () => onSelected(item.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF0877D8)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.$2,
                          maxLines: 1,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF5871A1),
                            fontSize: 11.5,
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsSectionHeader extends SliverPersistentHeaderDelegate {
  const _AnalyticsSectionHeader({required this.child});

  final Widget child;

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _AnalyticsSectionHeader oldDelegate) =>
      oldDelegate.child != child;
}

class _SupplierForecastSnapshot {
  const _SupplierForecastSnapshot({required this.selectedMethod});

  final ForecastMethodSelection selectedMethod;
}

class _SupplierSegmentButton extends StatelessWidget {
  const _SupplierSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0877D8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x220877D8),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF0B2470),
              fontSize: 12.2,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SupplierCircleButton extends StatelessWidget {
  const _SupplierCircleButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFD),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE0EAF1)),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF0B2470) : const Color(0xFFB8C6D2),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SupplierAnalyticsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SupplierAnalyticsHeaderDelegate({
    required this.topPadding,
    required this.onBack,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.backgroundAsset,
  });

  final double topPadding;
  final VoidCallback onBack;
  final String title;
  final String eyebrow;
  final String subtitle;
  final String backgroundAsset;

  @override
  double get minExtent => topPadding + 56;

  @override
  double get maxExtent => topPadding + 178;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = math.max(1.0, maxExtent - minExtent);
    final progress = (shrinkOffset / range).clamp(0.0, 1.0);
    final expandedOpacity = (1.0 - progress * 1.35).clamp(0.0, 1.0);
    final titleFontSize = 29.0 - (11.5 * progress);
    final expandedTitleTop = topPadding + 90.0;
    final collapsedTitleTop = topPadding + 15.0;
    final titleTop =
        expandedTitleTop + (collapsedTitleTop - expandedTitleTop) * progress;
    final titleLeft = 18.0 + (52.0 * progress);
    const bottomRadius = 0.0;

    return Material(
      color: const Color(0xFF0A4E7D),
      elevation: overlapsContent ? 2 : 0,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B4777),
                      Color(0xFF0877B8),
                      Color(0xFF39A6D8),
                    ],
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x5C001E38), Color(0xC900294A)],
                ),
              ),
            ),
            // Match the Order Center and Account Center body overlap exactly.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F8FB),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1900213D),
                        blurRadius: 20,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: topPadding + 8,
              child: Tooltip(
                message: 'Back',
                child: Material(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(13),
                    splashColor: Colors.white.withAlpha(28),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: Colors.white.withAlpha(38)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: topPadding + 10,
              child: Opacity(
                opacity: 1.0 - progress * 0.15,
                child: SizedBox(
                  width: 92,
                  height: 40,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.dst,
                    ),
                    child: Image.asset(
                      'assets/images/isdalink_logo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: titleLeft,
              right: progress > 0.65 ? 120 : 18,
              top: titleTop,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFontSize,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 18,
              top: topPadding + 75,
              child: Opacity(
                opacity: expandedOpacity,
                child: Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Color(0xFFE5F4FF),
                    fontSize: 10.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 18,
              top: topPadding + 127,
              child: Opacity(
                opacity: expandedOpacity,
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8F3FA),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SupplierAnalyticsHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.onBack != onBack ||
        oldDelegate.title != title ||
        oldDelegate.eyebrow != eyebrow ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.backgroundAsset != backgroundAsset;
  }
}

class _SupplierSummaryMetric extends StatelessWidget {
  const _SupplierSummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.valueFontSize = 23.5,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F3FB),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF0877D8), size: 18),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 22,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF607494),
                  fontSize: 9.3,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          SizedBox(
            height: 29,
            width: double.infinity,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color(0xFF0B2470),
                      fontSize: valueFontSize,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 13,
            child: Center(
              child: Text(
                suffix ?? '',
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF607494),
                  fontSize: 9.3,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierMetricDivider extends StatelessWidget {
  const _SupplierMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(width: 1, height: 76, color: const Color(0xFFDCE7EE)),
    );
  }
}

class _SupplierBarChartPainter extends CustomPainter {
  const _SupplierBarChartPainter({
    required this.values,
    required this.labels,
    required this.unitLabel,
    this.selectedIndex,
  });

  final List<double> values;
  final List<String> labels;
  final String unitLabel;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    const left = 42.0;
    const right = 6.0;
    const top = 8.0;
    const bottom = 34.0;
    final chartWidth = math.max(1.0, size.width - left - right).toDouble();
    final chartHeight = math.max(1.0, size.height - top - bottom).toDouble();
    final rawMax = values.fold<double>(0, math.max);
    final stepBase = rawMax <= 10
        ? 2.0
        : rawMax <= 25
        ? 5.0
        : rawMax <= 60
        ? 10.0
        : 20.0;
    final maxValue = math
        .max(stepBase * 4, (rawMax / stepBase).ceil() * stepBase)
        .toDouble();
    final divisions = math.max(4, (maxValue / stepBase).round()).toInt();
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE6EF)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFB9C9D7)
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF53B3F3), Color(0xFF87C8F5)],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    final selectedBarPaint = Paint()..color = const Color(0xFF0877D8);

    for (var i = 0; i <= divisions; i++) {
      final ratio = i / divisions;
      final y = top + chartHeight - (chartHeight * ratio);
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);

      final value = maxValue * ratio;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          style: const TextStyle(
            color: Color(0xFF5B72A0),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(left - labelPainter.width - 9, y - labelPainter.height / 2),
      );
    }

    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(left, top + chartHeight),
      Offset(left + chartWidth, top + chartHeight),
      axisPaint,
    );

    final slotWidth = chartWidth / values.length;
    final barWidth = math.min(52.0, slotWidth * 0.62).toDouble();

    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      final barHeight = maxValue == 0 ? 0.0 : chartHeight * (value / maxValue);
      final x = left + slotWidth * index + (slotWidth - barWidth) / 2;
      final barTop = top + chartHeight - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barTop, barWidth, barHeight),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        selectedIndex == index ? selectedBarPaint : barPaint,
      );

      if (selectedIndex == index) {
        final valueText = '${_formatChartValue(value)} $unitLabel';
        final tooltipPainter = TextPainter(
          text: TextSpan(
            text: valueText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        const horizontalPadding = 8.0;
        const verticalPadding = 5.0;
        final tooltipWidth = tooltipPainter.width + horizontalPadding * 2;
        final tooltipHeight = tooltipPainter.height + verticalPadding * 2;
        final centerX = x + barWidth / 2;
        final tooltipLeft = (centerX - tooltipWidth / 2)
            .clamp(left, left + chartWidth - tooltipWidth)
            .toDouble();
        final tooltipTop = math.max(top, barTop - tooltipHeight - 5).toDouble();
        final tooltipRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(tooltipLeft, tooltipTop, tooltipWidth, tooltipHeight),
          const Radius.circular(8),
        );
        canvas.drawRRect(tooltipRect, Paint()..color = const Color(0xFF0B2470));
        tooltipPainter.paint(
          canvas,
          Offset(tooltipLeft + horizontalPadding, tooltipTop + verticalPadding),
        );
      }

      if (index < labels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labels[index],
            style: const TextStyle(
              color: Color(0xFF5B72A0),
              fontSize: 9.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: math.max(1.0, slotWidth - 3).toDouble());

        labelPainter.paint(
          canvas,
          Offset(
            left + slotWidth * index + (slotWidth - labelPainter.width) / 2,
            top + chartHeight + 9,
          ),
        );
      }
    }
  }

  static String _formatChartValue(double value) {
    if ((value - value.roundToDouble()).abs() < 0.001) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _SupplierBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.unitLabel != unitLabel;
  }
}

class AnalyticsData {
  const AnalyticsData({
    this.hasCompleteAmounts = true,
    this.identityConflicts = 0,
    required this.completedOrders,
    required this.liveCompletedOrders,
    required this.historicalTransactions,
    required this.totalAmount,
    required this.products,
    required this.selectedProduct,
    required this.selectedPoints,
    required this.rankingBasis,
    required this.simpleForecast,
    required this.seasonalForecast,
    required this.simpleEvaluation,
    required this.seasonalEvaluation,
    required this.selectedMethod,
    required this.variability,
    required this.suggestions,
    required this.stockAlerts,
  });

  final int identityConflicts;
  final int completedOrders;
  final int liveCompletedOrders;
  final int historicalTransactions;
  final bool hasCompleteAmounts;
  final double totalAmount;
  final List<ProductSummary> products;
  final ProductSummary? selectedProduct;
  final List<PeriodPoint> selectedPoints;
  final String rankingBasis;
  final ForecastResult simpleForecast;
  final ForecastResult seasonalForecast;
  final ForecastEvaluation simpleEvaluation;
  final ForecastEvaluation seasonalEvaluation;
  final ForecastMethodSelection selectedMethod;
  final double? variability;
  final List<RestockingSuggestion> suggestions;
  final List<StockAlert> stockAlerts;

  bool get hasTransactions {
    return completedOrders > 0 && products.isNotEmpty;
  }

  factory AnalyticsData.empty() {
    return AnalyticsData(
      completedOrders: 0,
      liveCompletedOrders: 0,
      historicalTransactions: 0,
      totalAmount: 0,
      products: const [],
      selectedProduct: null,
      selectedPoints: const [],
      rankingBasis: '',
      simpleForecast: ForecastResult.unavailable(
        reason: 'No completed periods are available.',
      ),
      seasonalForecast: ForecastResult.unavailable(
        reason: 'No completed periods are available.',
      ),
      simpleEvaluation: ForecastEvaluation.unavailable(
        reason: 'No completed periods are available.',
      ),
      seasonalEvaluation: ForecastEvaluation.unavailable(
        reason: 'No completed periods are available.',
      ),
      selectedMethod: ForecastMethodSelection.unavailable(
        reason: 'No completed periods are available.',
      ),
      variability: null,
      suggestions: const [],
      stockAlerts: const [],
    );
  }
}

class _OrderLine {
  const _OrderLine({
    this.hasKnownAmount = true,
    required this.productId,
    required this.productName,
    required this.quantityUnit,
    required this.emoji,
    required this.quantity,
    required this.amount,
  });

  final String productId;
  final String productName;
  final String quantityUnit;
  final String emoji;
  final double quantity;
  final double amount;
  final bool hasKnownAmount;
}

class ProductSummary implements AnalyticsRankingSeries {
  const ProductSummary({
    this.hasCompleteAmounts = true,
    required this.seriesKey,
    required this.productName,
    required this.quantityUnit,
    required this.emoji,
    required this.quantity,
    required this.amount,
    required this.transactionCount,
  });

  @override
  final String seriesKey;
  @override
  final String productName;
  @override
  final String quantityUnit;
  final String emoji;
  @override
  final double quantity;
  @override
  final bool hasCompleteAmounts;
  @override
  final double amount;
  final int transactionCount;
}

class StockAlert {
  const StockAlert({
    required this.productName,
    required this.emoji,
    required this.quantity,
    required this.quantityUnit,
    required this.lowStockLevel,
  });

  final String productName;
  final String emoji;
  final double quantity;
  final String quantityUnit;
  final double lowStockLevel;
}

class RestockingSuggestion {
  const RestockingSuggestion({
    required this.productName,
    required this.emoji,
    required this.quantityUnit,
    required this.suggestedQuantity,
    required this.selectedMethod,
    required this.evaluationNote,
    required this.targetDate,
  });

  final String productName;
  final String emoji;
  final String quantityUnit;
  final double suggestedQuantity;
  final ForecastingMethod selectedMethod;
  final String evaluationNote;
  final DateTime targetDate;
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(24)),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFE9F7FF), size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD8ECF8),
                      fontSize: 7.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: selected
                ? Border.all(color: const Color(0xFFD9E9F5))
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1000152A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF146BFF)
                  : const Color(0xFF71889A),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  const _CompactEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EEF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF8198A9), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8498A8),
                    fontSize: 8.9,
                    height: 1.32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartStat extends StatelessWidget {
  const _ChartStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EEF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A9DAC),
              fontSize: 7.1,
              letterSpacing: 0.45,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 10.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE0EAF1)
      ..strokeWidth = 1;

    for (var index = 0; index <= 3; index++) {
      final y = size.height * index / 3;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maximum = values.reduce(math.max);
    final minimum = values.reduce(math.min);
    final range = math.max(
      maximum - minimum,
      maximum == 0 ? 1 : maximum * 0.18,
    );

    final horizontalStep = values.length == 1
        ? 0.0
        : size.width / (values.length - 1);

    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final normalized = (values[index] - minimum) / range;
      final x = values.length == 1 ? size.width / 2 : horizontalStep * index;
      final y = size.height - normalized * (size.height * 0.78) - 12;

      points.add(Offset(x, y.clamp(10.0, size.height - 10.0).toDouble()));
    }

    if (points.length > 1) {
      final fillPath = Path()..moveTo(points.first.dx, size.height);

      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }

      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x42146BFF), Color(0x00146BFF)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF146BFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3.2, Paint()..color = const Color(0xFF146BFF));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _AnalyticsHeaderPainter extends CustomPainter {
  const _AnalyticsHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final largeCircle = Paint()..color = Colors.white.withAlpha(13);

    final circleBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(22);

    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.16),
      size.width * 0.25,
      largeCircle,
    );

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.25),
      size.width * 0.19,
      circleBorder,
    );

    canvas.drawCircle(
      Offset(size.width * 0.77, size.height * 0.47),
      size.width * 0.11,
      circleBorder,
    );

    final accent = Paint()..color = Colors.white.withAlpha(10);

    final path = Path()
      ..moveTo(size.width * 0.57, size.height)
      ..lineTo(size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, accent);
  }

  @override
  bool shouldRepaint(covariant _AnalyticsHeaderPainter oldDelegate) {
    return false;
  }
}
