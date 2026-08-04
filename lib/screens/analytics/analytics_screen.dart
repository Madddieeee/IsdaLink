import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AnalyticsMode {
  vendor,
  supplier,
}

enum AnalyticsPeriod {
  weekly,
  monthly,
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    this.mode = AnalyticsMode.vendor,
  });

  final AnalyticsMode mode;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriod selectedPeriod = AnalyticsPeriod.weekly;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get isSupplier => widget.mode == AnalyticsMode.supplier;

  String get title => isSupplier ? 'Supplier Analytics' : 'Vendor Analytics';

  String get subtitle => isSupplier
      ? 'Sales insights from your completed Cash on Delivery orders.'
      : 'Purchase insights from your completed Cash on Delivery orders.';

  String get amountLabel => isSupplier ? 'Sales' : 'Amount';

  String get trendTitle => isSupplier ? 'Sales Trend' : 'Purchase Trend';

  String get trendSubtitle => isSupplier
      ? 'Completed sales quantities grouped by the selected period.'
      : 'Completed purchase quantities grouped by the selected period.';

  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where(
          isSupplier ? 'supplierId' : 'vendorId',
          isEqualTo: uid,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> stocksStream(
    String uid,
  ) {
    if (isSupplier) {
      return FirebaseFirestore.instance
          .collection('fishStocks')
          .where('supplierId', isEqualTo: uid)
          .snapshots();
    }

    return FirebaseFirestore.instance.collection('fishStocks').snapshots();
  }

  String stringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double doubleValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  double firstPositiveDouble(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = doubleValue(data, key);

      if (value > 0) {
        return value;
      }
    }

    return 0;
  }

  DateTime orderDate(
    Map<String, dynamic> data,
  ) {
    const keys = [
      'completedAt',
      'deliveredAt',
      'updatedAt',
      'createdAt',
    ];

    for (final key in keys) {
      final value = data[key];

      if (value is Timestamp) {
        return value.toDate().toLocal();
      }

      if (value is DateTime) {
        return value.toLocal();
      }

      if (value is String) {
        final parsed = DateTime.tryParse(value);

        if (parsed != null) {
          return parsed.toLocal();
        }
      }
    }

    return DateTime.now();
  }

  bool isCompletedOrder(
    Map<String, dynamic> data,
  ) {
    final status = stringValue(
      data,
      'orderStatus',
      'pending',
    ).toLowerCase();

    return status == 'completed' || status == 'delivered';
  }

  double fulfilledQuantity(
    Map<String, dynamic> data,
  ) {
    return firstPositiveDouble(
      data,
      const [
        'validatedFulfilledQuantity',
        'fulfilledQuantity',
        'quantity',
      ],
    );
  }

  double completedAmount(
    Map<String, dynamic> data,
  ) {
    return firstPositiveDouble(
      data,
      const [
        'validatedTotalAmount',
        'fulfilledTotalAmount',
        'totalAmount',
      ],
    );
  }

  DateTime periodStart(
    DateTime date,
  ) {
    if (selectedPeriod == AnalyticsPeriod.monthly) {
      return DateTime(date.year, date.month);
    }

    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  String periodKey(
    DateTime date,
  ) {
    final start = periodStart(date);
    return '${start.year}-${start.month}-${start.day}';
  }

  String periodLabel(
    DateTime date,
  ) {
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
    return '${months[date.month - 1]} ${date.day}–${end.day}';
  }

  AnalyticsData buildAnalyticsData({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  }) {
    final completedOrders = orders.where(
      (document) => isCompletedOrder(document.data()),
    ).toList();

    double totalQuantity = 0;
    double totalAmount = 0;

    final productMap = <String, ProductSummary>{};
    final productPeriodMap = <String, Map<String, PeriodPoint>>{};
    final quantityUnits = <String>{};

    for (final document in completedOrders) {
      final data = document.data();
      final quantity = fulfilledQuantity(data);
      final amount = completedAmount(data);
      final productName = stringValue(data, 'productName', 'Fish Product');
      final quantityUnit = stringValue(data, 'quantityUnit', 'kilo');
      final emoji = stringValue(data, 'productEmoji', '🐟');
      final date = periodStart(orderDate(data));
      final key = periodKey(date);
      final productKey = '${productName.toLowerCase()}|${quantityUnit.toLowerCase()}';

      quantityUnits.add(quantityUnit.toLowerCase());
      totalQuantity += quantity;
      totalAmount += amount;

      final existingProduct = productMap[productKey];
      productMap[productKey] = ProductSummary(
        seriesKey: productKey,
        productName: productName,
        quantityUnit: quantityUnit,
        emoji: emoji,
        quantity: (existingProduct?.quantity ?? 0) + quantity,
        amount: (existingProduct?.amount ?? 0) + amount,
      );

      final series = productPeriodMap.putIfAbsent(
        productKey,
        () => <String, PeriodPoint>{},
      );
      final existingSeriesPoint = series[key];
      series[key] = PeriodPoint(
        date: date,
        quantity: (existingSeriesPoint?.quantity ?? 0) + quantity,
        amount: (existingSeriesPoint?.amount ?? 0) + amount,
      );
    }

    final products = productMap.values.toList();
    final mixedUnits = quantityUnits.length > 1;
    products.sort(
      mixedUnits
          ? (a, b) => b.amount.compareTo(a.amount)
          : (a, b) => b.quantity.compareTo(a.quantity),
    );

    final productRankingBasis = mixedUnits
        ? 'Ranking uses completed transaction amount because quantities use different units.'
        : 'Ranking uses completed transaction quantity within ${quantityUnits.isEmpty ? 'the recorded unit' : quantityUnits.first}.';

    final productSeries = <String, List<PeriodPoint>>{};
    for (final entry in productPeriodMap.entries) {
      final seriesPoints = entry.value.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      productSeries[entry.key] = seriesPoints;
    }

    final focusProduct = products.isEmpty ? null : products.first;
    final focusPoints = focusProduct == null
        ? <PeriodPoint>[]
        : productSeries[focusProduct.seriesKey] ?? <PeriodPoint>[];

    final simpleForecast = simpleMovingAverage(
      focusPoints.map((point) => point.quantity).toList(),
    );

    final seasonalForecast = seasonalMovingAverage(focusPoints);
    final evaluation = evaluateForecast(
      focusPoints.map((point) => point.quantity).toList(),
    );

    final stockAlerts = buildStockAlerts(
      stocks: stocks,
      purchasedProducts: products,
    );

    final suggestions = buildSuggestions(
      products: products,
      productSeries: productSeries,
    );

    final quantityDisplay = quantityUnits.length <= 1
        ? '${formatNumber(totalQuantity)}${quantityUnits.isEmpty ? '' : ' ${quantityUnits.first}'}'
        : 'Mixed';

    return AnalyticsData(
      completedOrders: completedOrders.length,
      totalQuantity: totalQuantity,
      quantityDisplay: quantityDisplay,
      totalAmount: totalAmount,
      focusSeriesLabel: focusProduct == null
          ? 'No product series yet'
          : '${focusProduct.productName} · ${focusProduct.quantityUnit}',
      productRankingBasis: productRankingBasis,
      periodPoints: focusPoints,
      topProducts: products,
      stockAlerts: stockAlerts,
      suggestions: suggestions,
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
      evaluation: evaluation,
      variability: variability(
        focusPoints.map((point) => point.quantity).toList(),
      ),
    );
  }

  List<StockAlert> buildStockAlerts({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
    required List<ProductSummary> purchasedProducts,
  }) {
    final purchasedNames = purchasedProducts
        .map((product) => product.productName.toLowerCase())
        .toSet();

    return stocks.where(
      (document) {
        final data = document.data();
        final status = stringValue(data, 'status', 'available').toLowerCase();
        final quantity = doubleValue(data, 'quantity');
        final lowStockLevel = doubleValue(data, 'lowStockLevel');
        final productName = stringValue(data, 'productName', '').toLowerCase();

        if (status == 'unavailable') {
          return false;
        }

        if (!isSupplier &&
            purchasedNames.isNotEmpty &&
            !purchasedNames.contains(productName)) {
          return false;
        }

        return quantity <= lowStockLevel;
      },
    ).map(
      (document) {
        final data = document.data();
        return StockAlert(
          productName: stringValue(data, 'productName', 'Fish Product'),
          supplierName: stringValue(data, 'supplierName', 'Supplier'),
          emoji: stringValue(data, 'emoji', '🐟'),
          quantity: doubleValue(data, 'quantity'),
          quantityUnit: stringValue(data, 'quantityUnit', 'kilo'),
          lowStockLevel: doubleValue(data, 'lowStockLevel'),
        );
      },
    ).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
  }

  List<RestockingSuggestion> buildSuggestions({
    required List<ProductSummary> products,
    required Map<String, List<PeriodPoint>> productSeries,
  }) {
    if (products.isEmpty) {
      return const [];
    }

    return products.take(3).map(
      (product) {
        final points = productSeries[product.seriesKey] ?? const <PeriodPoint>[];
        final simple = simpleMovingAverage(
          points.map((point) => point.quantity).toList(),
        );
        final seasonal = seasonalMovingAverage(points);

        return RestockingSuggestion(
          productName: product.productName,
          emoji: product.emoji,
          quantityUnit: product.quantityUnit,
          suggestedQuantity: math.max(simple, seasonal).toDouble(),
        );
      },
    ).where(
      (suggestion) => suggestion.suggestedQuantity > 0,
    ).toList();
  }

  double simpleMovingAverage(
    List<double> values, {
    int window = 3,
  }) {
    if (values.isEmpty) {
      return 0;
    }

    final actualWindow = math.min(window, values.length);
    final recent = values.sublist(values.length - actualWindow);
    final total = recent.fold<double>(0, (sum, value) => sum + value);
    return total / actualWindow;
  }

  double seasonalMovingAverage(
    List<PeriodPoint> points,
  ) {
    if (points.isEmpty) {
      return 0;
    }

    if (selectedPeriod == AnalyticsPeriod.monthly) {
      final currentMonth = DateTime.now().month;
      final matching = points
          .where((point) => point.date.month == currentMonth)
          .map((point) => point.quantity)
          .toList();

      if (matching.isNotEmpty) {
        return matching.fold<double>(0, (sum, value) => sum + value) /
            matching.length;
      }
    } else {
      final currentWeekPosition = ((DateTime.now().day - 1) ~/ 7) + 1;
      final matching = points.where(
        (point) {
          final weekPosition = ((point.date.day - 1) ~/ 7) + 1;
          return weekPosition == currentWeekPosition;
        },
      ).map((point) => point.quantity).toList();

      if (matching.isNotEmpty) {
        return matching.fold<double>(0, (sum, value) => sum + value) /
            matching.length;
      }
    }

    return simpleMovingAverage(
      points.map((point) => point.quantity).toList(),
    );
  }

  ForecastEvaluation evaluateForecast(
    List<double> values, {
    int window = 3,
  }) {
    if (values.length <= window) {
      return const ForecastEvaluation(
        mape: 0,
        mae: 0,
        hasEnoughData: false,
      );
    }

    final absoluteErrors = <double>[];
    final percentageErrors = <double>[];

    for (var index = window; index < values.length; index++) {
      final previous = values.sublist(index - window, index);
      final forecast = previous.fold<double>(
            0,
            (sum, value) => sum + value,
          ) /
          window;
      final actual = values[index];
      final error = (actual - forecast).abs();

      absoluteErrors.add(error);

      if (actual > 0) {
        percentageErrors.add(error / actual * 100);
      }
    }

    final mae = absoluteErrors.fold<double>(
          0,
          (sum, value) => sum + value,
        ) /
        absoluteErrors.length;

    final double mape = percentageErrors.isEmpty
        ? 0.0
        : percentageErrors.fold<double>(
              0,
              (sum, value) => sum + value,
            ) /
            percentageErrors.length;

    return ForecastEvaluation(
      mape: mape,
      mae: mae,
      hasEnoughData: true,
    );
  }

  double variability(
    List<double> values,
  ) {
    if (values.length < 2) {
      return 0;
    }

    final mean = values.fold<double>(0, (sum, value) => sum + value) /
        values.length;

    if (mean == 0) {
      return 0;
    }

    final squaredDifferences = values.map(
      (value) => math.pow(value - mean, 2).toDouble(),
    );

    final variance = squaredDifferences.fold<double>(
          0,
          (sum, value) => sum + value,
        ) /
        values.length;

    return math.sqrt(variance) / mean * 100;
  }

  String formatNumber(
    double value, {
    int decimals = 1,
  }) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(decimals);
  }

  String formatCurrency(
    double value,
  ) {
    if (value >= 1000000) {
      return '₱${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}K';
    }

    return '₱${value.toStringAsFixed(0)}';
  }

  Widget analyticsHeader(
    AnalyticsData data,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 255,
      toolbarHeight: 62,
      elevation: 0,
      backgroundColor: const Color(0xFF06355F),
      foregroundColor: Colors.white,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _HeaderButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      leadingWidth: 56,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF06355F),
                Color(0xFF0875D1),
                Color(0xFF176BFF),
              ],
              stops: [0, 0.58, 1],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _AnalyticsHeaderPainter(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.paddingOf(context).top + 70,
                  18,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(24),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withAlpha(34),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSupplier
                                    ? Icons.storefront_rounded
                                    : Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isSupplier
                                    ? 'SUPPLIER SIDE'
                                    : 'VENDOR SIDE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDDEFFA),
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _HeaderMetric(
                          icon: Icons.receipt_long_outlined,
                          value: '${data.completedOrders}',
                          label: 'Completed',
                        ),
                        const SizedBox(width: 9),
                        _HeaderMetric(
                          icon: Icons.scale_outlined,
                          value: data.quantityDisplay,
                          label: 'Quantity',
                        ),
                        const SizedBox(width: 9),
                        _HeaderMetric(
                          icon: Icons.analytics_outlined,
                          value: formatCurrency(data.totalAmount),
                          label: amountLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
    );
  }

  Widget periodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodButton(
              label: 'Weekly',
              selected: selectedPeriod == AnalyticsPeriod.weekly,
              onTap: () {
                setState(() {
                  selectedPeriod = AnalyticsPeriod.weekly;
                });
              },
            ),
          ),
          Expanded(
            child: _PeriodButton(
              label: 'Monthly',
              selected: selectedPeriod == AnalyticsPeriod.monthly,
              onTap: () {
                setState(() {
                  selectedPeriod = AnalyticsPeriod.monthly;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Color iconColor = const Color(0xFF0875D1),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2EDF4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E00152A),
            blurRadius: 14,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 11.2,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget forecastCard({
    required String title,
    required String description,
    required double value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDE8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0875D1),
                  Color(0xFF176BFF),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 13.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF6D8293),
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Forecast: ${formatNumber(value)} units',
                  style: const TextStyle(
                    color: Color(0xFF0875D1),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withAlpha(55),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 9.2,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget trendChart(
    List<PeriodPoint> points,
  ) {
    if (points.isEmpty) {
      return const _EmptyAnalyticsState(
        icon: Icons.show_chart_rounded,
        title: 'No completed transaction records yet',
        subtitle:
            'The trend will appear after completed Cash on Delivery orders are recorded.',
      );
    }

    final visible = points.length > 8
        ? points.sublist(points.length - 8)
        : points;

    return Column(
      children: [
        SizedBox(
          height: 154,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendChartPainter(
              values: visible.map((point) => point.quantity).toList(),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: visible.map(
            (point) {
              return Expanded(
                child: Text(
                  periodLabel(point.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8BA0B0),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  Widget stockAlerts(
    List<StockAlert> alerts,
  ) {
    if (alerts.isEmpty) {
      return const _EmptyAnalyticsState(
        icon: Icons.inventory_2_outlined,
        title: 'No low-stock items found',
        subtitle: 'Current inventory records do not require an alert.',
      );
    }

    return Column(
      children: alerts.take(4).map(
        (alert) {
          final outOfStock = alert.quantity <= 0;
          final color = outOfStock
              ? const Color(0xFFD32F2F)
              : const Color(0xFFFF7A1A);

          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5FB),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    alert.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatNumber(alert.quantity)} ${alert.quantityUnit} available',
                        style: TextStyle(
                          color: color,
                          fontSize: 10.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    outOfStock ? 'Out' : 'Low',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  Widget suggestions(
    List<RestockingSuggestion> suggestions,
  ) {
    if (suggestions.isEmpty) {
      return const _EmptyAnalyticsState(
        icon: Icons.notifications_none_rounded,
        title: 'No restocking suggestion yet',
        subtitle:
            'More completed transactions are needed before a suggestion is generated.',
      );
    }

    return Column(
      children: suggestions.map(
        (suggestion) {
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F9FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFDDEBF3),
              ),
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
                        'Consider ${formatNumber(suggestion.suggestedQuantity)} ${suggestion.quantityUnit} for the next period.',
                        style: const TextStyle(
                          color: Color(0xFF657C8E),
                          fontSize: 10.1,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  Widget topProducts(
    List<ProductSummary> products,
  ) {
    if (products.isEmpty) {
      return const _EmptyAnalyticsState(
        icon: Icons.emoji_events_outlined,
        title: 'No product ranking yet',
        subtitle: 'Completed transactions will create product insights.',
      );
    }

    return Column(
      children: products.take(5).toList().asMap().entries.map(
        (entry) {
          final product = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0875D1).withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: Color(0xFF0875D1),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 21),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatNumber(product.quantity)} ${product.quantityUnit}',
                        style: const TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 9.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency(product.amount),
                  style: const TextStyle(
                    color: Color(0xFF0875D1),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  Widget analyticsContent(
    AnalyticsData data,
  ) {
    return CustomScrollView(
      slivers: [
        analyticsHeader(data),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                sectionCard(
                  title: 'Analytics Period',
                  subtitle:
                      'View transaction records using a consistent weekly or monthly series.',
                  icon: Icons.date_range_outlined,
                  child: periodSelector(),
                ),
                sectionCard(
                  title: 'Forecasting Methods',
                  subtitle:
                      'Forecast series: ${data.focusSeriesLabel}. Quantities are never combined across different units.',
                  icon: Icons.trending_up_rounded,
                  child: Column(
                    children: [
                      forecastCard(
                        title: 'Simple Moving Average',
                        description:
                            'Uses the three most recent ${selectedPeriod == AnalyticsPeriod.weekly ? 'weekly' : 'monthly'} periods.',
                        value: data.simpleForecast,
                        icon: Icons.show_chart_rounded,
                      ),
                      forecastCard(
                        title: 'Seasonal Moving Average',
                        description:
                            'Uses comparable recurring ${selectedPeriod == AnalyticsPeriod.weekly ? 'weekly' : 'monthly'} periods when available.',
                        value: data.seasonalForecast,
                        icon: Icons.calendar_month_rounded,
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Forecast Evaluation',
                  subtitle: data.evaluation.hasEnoughData
                      ? 'MAPE and MAE were computed through moving-average back-testing.'
                      : 'At least four completed periods are needed for stable MAPE and MAE values.',
                  icon: Icons.fact_check_outlined,
                  child: Row(
                    children: [
                      evaluationTile(
                        label: 'MAPE',
                        value: data.evaluation.hasEnoughData
                            ? '${data.evaluation.mape.toStringAsFixed(2)}%'
                            : '--',
                        subtitle: 'Percentage error',
                        color: const Color(0xFF176BFF),
                      ),
                      const SizedBox(width: 10),
                      evaluationTile(
                        label: 'MAE',
                        value: data.evaluation.hasEnoughData
                            ? formatNumber(data.evaluation.mae)
                            : '--',
                        subtitle: 'Average absolute error',
                        color: const Color(0xFFFF7A1A),
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: trendTitle,
                  subtitle: '$trendSubtitle Series: ${data.focusSeriesLabel}.',
                  icon: Icons.auto_graph_rounded,
                  child: trendChart(data.periodPoints),
                ),
                if (isSupplier)
                  sectionCard(
                    title: 'Sales Variability',
                    subtitle:
                        'Shows how much completed sales quantities change across periods.',
                    icon: Icons.multiline_chart_rounded,
                    child: _VariabilityPanel(
                      value: data.variability,
                    ),
                  ),
                sectionCard(
                  title: 'Restocking Suggestions',
                  subtitle: isSupplier
                      ? 'Suggestions support supplier stock planning and do not change inventory automatically.'
                      : 'Suggestions support vendor purchasing decisions and do not place orders automatically.',
                  icon: Icons.notifications_active_outlined,
                  child: suggestions(data.suggestions),
                ),
                if (isSupplier)
                  sectionCard(
                    title: 'Stock Alerts',
                    subtitle:
                        'Low-stock and out-of-stock records owned by this supplier account.',
                    icon: Icons.inventory_2_outlined,
                    child: stockAlerts(data.stockAlerts),
                  ),
                sectionCard(
                  title: isSupplier
                      ? 'Top-Selling Fish Insights'
                      : 'Top Purchased Fish Insights',
                  subtitle: data.productRankingBasis,
                  icon: Icons.emoji_events_outlined,
                  child: topProducts(data.topProducts),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0875D1).withAlpha(35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cloud_done_rounded,
                        color: Color(0xFF0875D1),
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          isSupplier
                              ? 'Supplier Analytics uses this supplier account’s completed COD sales and owned inventory records.'
                              : 'Vendor Analytics uses this account’s completed COD purchases. Supplier sales records are not included.',
                          style: const TextStyle(
                            color: Color(0xFF52677A),
                            fontSize: 10.5,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget loadingBody() {
    final empty = AnalyticsData.empty();

    return CustomScrollView(
      slivers: [
        analyticsHeader(empty),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF0875D1),
            ),
          ),
        ),
      ],
    );
  }

  Widget errorBody(
    Object error,
  ) {
    final empty = AnalyticsData.empty();

    return CustomScrollView(
      slivers: [
        analyticsHeader(empty),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: _EmptyAnalyticsState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load analytics',
                subtitle: '$error',
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
            stream: stocksStream(user.uid),
            builder: (context, stockSnapshot) {
              if (stockSnapshot.hasError) {
                return errorBody(stockSnapshot.error!);
              }

              if (!stockSnapshot.hasData) {
                return loadingBody();
              }

              final data = buildAnalyticsData(
                orders: orderSnapshot.data!.docs,
                stocks: stockSnapshot.data!.docs,
              );

              return analyticsContent(data);
            },
          );
        },
      ),
    );
  }
}

class AnalyticsData {
  const AnalyticsData({
    required this.completedOrders,
    required this.totalQuantity,
    required this.quantityDisplay,
    required this.totalAmount,
    required this.focusSeriesLabel,
    required this.productRankingBasis,
    required this.periodPoints,
    required this.topProducts,
    required this.stockAlerts,
    required this.suggestions,
    required this.simpleForecast,
    required this.seasonalForecast,
    required this.evaluation,
    required this.variability,
  });

  factory AnalyticsData.empty() {
    return const AnalyticsData(
      completedOrders: 0,
      totalQuantity: 0,
      quantityDisplay: '0',
      totalAmount: 0,
      focusSeriesLabel: 'No product series yet',
      productRankingBasis: 'No completed product records yet.',
      periodPoints: [],
      topProducts: [],
      stockAlerts: [],
      suggestions: [],
      simpleForecast: 0,
      seasonalForecast: 0,
      evaluation: ForecastEvaluation(
        mape: 0,
        mae: 0,
        hasEnoughData: false,
      ),
      variability: 0,
    );
  }

  final int completedOrders;
  final double totalQuantity;
  final String quantityDisplay;
  final double totalAmount;
  final String focusSeriesLabel;
  final String productRankingBasis;
  final List<PeriodPoint> periodPoints;
  final List<ProductSummary> topProducts;
  final List<StockAlert> stockAlerts;
  final List<RestockingSuggestion> suggestions;
  final double simpleForecast;
  final double seasonalForecast;
  final ForecastEvaluation evaluation;
  final double variability;
}

class PeriodPoint {
  const PeriodPoint({
    required this.date,
    required this.quantity,
    required this.amount,
  });

  final DateTime date;
  final double quantity;
  final double amount;
}

class ProductSummary {
  const ProductSummary({
    required this.seriesKey,
    required this.productName,
    required this.quantityUnit,
    required this.emoji,
    required this.quantity,
    required this.amount,
  });

  final String seriesKey;
  final String productName;
  final String quantityUnit;
  final String emoji;
  final double quantity;
  final double amount;
}

class StockAlert {
  const StockAlert({
    required this.productName,
    required this.supplierName,
    required this.emoji,
    required this.quantity,
    required this.quantityUnit,
    required this.lowStockLevel,
  });

  final String productName;
  final String supplierName;
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
  });

  final String productName;
  final String emoji;
  final String quantityUnit;
  final double suggestedQuantity;
}

class ForecastEvaluation {
  const ForecastEvaluation({
    required this.mape,
    required this.mae,
    required this.hasEnoughData,
  });

  final double mape;
  final double mae;
  final bool hasEnoughData;
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white.withAlpha(28),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
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
  Widget build(
    BuildContext context,
  ) {
    return Expanded(
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withAlpha(30),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFDCECF8),
                fontSize: 8.8,
                fontWeight: FontWeight.w700,
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
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1000152A),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF0875D1)
                  : const Color(0xFF71889A),
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF8DA6B8),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A9EAD),
              fontSize: 9.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VariabilityPanel extends StatelessWidget {
  const _VariabilityPanel({
    required this.value,
  });

  final double value;

  String get label {
    if (value == 0) {
      return 'Not enough data';
    }

    if (value < 15) {
      return 'Stable';
    }

    if (value < 35) {
      return 'Moderate variation';
    }

    return 'High variation';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final progress = (value / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                value == 0 ? '--' : '${value.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF0875D1),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFDDEAF2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0875D1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({
    required this.values,
  });

  final List<double> values;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDDE8F0)
      ..strokeWidth = 1;

    for (var line = 0; line < 4; line++) {
      final y = 12 + (size.height - 24) * line / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    if (values.isEmpty) {
      return;
    }

    final maximum = values.reduce(math.max);
    final safeMaximum = maximum <= 0 ? 1.0 : maximum;
    final chartHeight = size.height - 30;
    final horizontalStep = values.length <= 1
        ? 0.0
        : size.width / (values.length - 1);

    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = values.length <= 1 ? size.width / 2 : horizontalStep * index;
      final normalized = values[index] / safeMaximum;
      final y = size.height - 14 - normalized * chartHeight;
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height - 14);

    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }

    fillPath
      ..lineTo(points.last.dx, size.height - 14)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x55176BFF),
            Color(0x07176BFF),
          ],
        ).createShader(Offset.zero & size),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 1; index < points.length; index++) {
      linePath.lineTo(points[index].dx, points[index].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF0875D1)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final pointPaint = Paint()..color = const Color(0xFF0875D1);
    final pointInnerPaint = Paint()..color = Colors.white;

    for (final point in points) {
      canvas
        ..drawCircle(point, 5, pointPaint)
        ..drawCircle(point, 2, pointInnerPaint);
    }
  }

  @override
  bool shouldRepaint(
    covariant _TrendChartPainter oldDelegate,
  ) {
    return oldDelegate.values != values;
  }
}

class _AnalyticsHeaderPainter extends CustomPainter {
  const _AnalyticsHeaderPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(18);

    canvas
      ..drawCircle(
        Offset(size.width * 0.86, size.height * 0.28),
        size.width * 0.22,
        paint,
      )
      ..drawCircle(
        Offset(size.width * 0.92, size.height * 0.30),
        size.width * 0.12,
        paint,
      );

    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.30),
      size.width * 0.17,
      Paint()..color = Colors.white.withAlpha(7),
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
