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
  String? selectedSeriesKey;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get isSupplier => widget.mode == AnalyticsMode.supplier;

  String get title => isSupplier ? 'Supplier Analytics' : 'Vendor Analytics';

  String get roleLabel => isSupplier ? 'SUPPLIER SIDE' : 'VENDOR SIDE';

  String get subtitle => isSupplier
      ? 'Sales trends, forecasts, stock alerts, and product insights from validated historical records and completed COD orders.'
      : 'Purchase trends, forecasts, and restocking insights from validated historical records and completed COD orders.';

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

  Stream<QuerySnapshot<Map<String, dynamic>>> historicalTransactionsStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('historicalTransactions')
        .where(
          isSupplier ? 'supplierUid' : 'vendorUid',
          isEqualTo: uid,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> supplierStocksStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('fishStocks')
        .where(
          'supplierId',
          isEqualTo: uid,
        )
        .snapshots();
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

  double doubleValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
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
      // Analytics is grouped by the transaction/order date, not by the
      // completion date. Completion timestamps remain fallback values for
      // legacy records that do not yet store a separate transaction date.
      'transactionDate',
      'orderDate',
      'createdAt',
      'completedAt',
      'deliveredAt',
      'updatedAt',
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
    final status = firstString(
      data,
      const [
        'orderStatus',
        'status',
      ],
      fallback: 'pending',
    ).toLowerCase();

    return status == 'completed' || status == 'delivered';
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
        'grandTotal',
      ],
    );
  }

  String normalizeAnalyticsUnit(
    String rawUnit,
  ) {
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

  String analyticsProductKey(
    String productName,
  ) {
    return productName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool isEligibleHistoricalTransaction(
    Map<String, dynamic> data,
  ) {
    final analyticsEligible = data['analyticsEligible'];

    if (analyticsEligible is bool && !analyticsEligible) {
      return false;
    }

    final orderStatus = firstString(
      data,
      const [
        'orderStatus',
        'order_status',
      ],
      fallback: '',
    ).toLowerCase();

    final validationStatus = firstString(
      data,
      const [
        'validationStatus',
        'validation_status',
      ],
      fallback: '',
    ).toLowerCase();

    return orderStatus == 'completed' &&
        validationStatus == 'validated';
  }

  DateTime historicalTransactionDate(
    Map<String, dynamic> data,
  ) {
    const keys = [
      'transactionDate',
      'transaction_date',
      'transactionDateIso',
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
        final parsed = DateTime.tryParse(value.trim());

        if (parsed != null) {
          return parsed.toLocal();
        }
      }
    }

    return DateTime.now();
  }

  List<_OrderLine> extractHistoricalLines(
    Map<String, dynamic> data,
  ) {
    if (!isEligibleHistoricalTransaction(data)) {
      return const [];
    }

    final quantity = firstPositiveDouble(
      data,
      const [
        'quantityFulfilled',
        'quantity_fulfilled',
      ],
    );

    if (quantity <= 0) {
      return const [];
    }

    final productName = firstString(
      data,
      const [
        'productName',
        'fishProduct',
        'fish_product',
      ],
      fallback: 'Fish Product',
    );

    final quantityUnit = normalizeAnalyticsUnit(
      firstString(
        data,
        const [
          'quantityUnit',
          'quantity_unit',
        ],
        fallback: 'kilogram',
      ),
    );

    var amount = firstPositiveDouble(
      data,
      const [
        'totalAmount',
        'totalAmountPhp',
        'total_amount_php',
      ],
    );

    if (amount <= 0) {
      final unitPrice = firstPositiveDouble(
        data,
        const [
          'unitPrice',
          'unitPricePhp',
          'unit_price_php',
        ],
      );
      amount = unitPrice * quantity;
    }

    return [
      _OrderLine(
        productId: analyticsProductKey(productName),
        productName: productName,
        quantityUnit: quantityUnit,
        emoji: '🐟',
        quantity: quantity,
        amount: amount,
      ),
    ];
  }

  DateTime periodStart(
    DateTime date,
  ) {
    if (selectedPeriod == AnalyticsPeriod.monthly) {
      return DateTime(
        date.year,
        date.month,
      );
    }

    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return normalized.subtract(
      Duration(
        days: normalized.weekday - DateTime.monday,
      ),
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

    final end = date.add(
      const Duration(days: 6),
    );

    if (date.month == end.month) {
      return '${months[date.month - 1]} ${date.day}-${end.day}';
    }

    return '${months[date.month - 1]} ${date.day}';
  }

  List<_OrderLine> extractOrderLines(
    Map<String, dynamic> order,
  ) {
    final rawItems = order['items'] ?? order['orderItems'];

    if (rawItems is List && rawItems.isNotEmpty) {
      final lines = <_OrderLine>[];

      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          continue;
        }

        final item = Map<String, dynamic>.from(rawItem);
        final quantity = firstPositiveDouble(
          item,
          const [
            'validatedFulfilledQuantity',
            'fulfilledQuantity',
            'quantity',
          ],
        );

        if (quantity <= 0) {
          continue;
        }

        final productName = firstString(
          item,
          const [
            'productName',
            'fishName',
            'name',
          ],
          fallback: 'Fish Product',
        );

        final productId = firstString(
          item,
          const [
            'productId',
            'fishStockId',
            'stockId',
          ],
          fallback: productName.toLowerCase(),
        );

        final quantityUnit = normalizeAnalyticsUnit(
          firstString(
            item,
            const [
              'quantityUnit',
              'unit',
              'unitType',
            ],
            fallback: 'kilogram',
          ),
        );

        final emoji = firstString(
          item,
          const [
            'productEmoji',
            'emoji',
          ],
          fallback: '🐟',
        );

        var amount = firstPositiveDouble(
          item,
          const [
            'validatedTotalAmount',
            'fulfilledTotalAmount',
            'lineTotal',
            'subtotal',
            'totalAmount',
          ],
        );

        if (amount <= 0) {
          final price = firstPositiveDouble(
            item,
            const [
              'price',
              'unitPrice',
              'pricePerUnit',
            ],
          );
          amount = price * quantity;
        }

        lines.add(
          _OrderLine(
            productId: productId,
            productName: productName,
            quantityUnit: quantityUnit,
            emoji: emoji,
            quantity: quantity,
            amount: amount,
          ),
        );
      }

      if (lines.isNotEmpty) {
        return lines;
      }
    }

    final quantity = firstPositiveDouble(
      order,
      const [
        'validatedFulfilledQuantity',
        'fulfilledQuantity',
        'quantity',
      ],
    );

    if (quantity <= 0) {
      return const [];
    }

    final productName = firstString(
      order,
      const [
        'productName',
        'fishName',
        'name',
      ],
      fallback: 'Fish Product',
    );

    final productId = firstString(
      order,
      const [
        'productId',
        'fishStockId',
        'stockId',
      ],
      fallback: productName.toLowerCase(),
    );

    final quantityUnit = normalizeAnalyticsUnit(
      firstString(
        order,
        const [
          'quantityUnit',
          'unit',
          'unitType',
        ],
        fallback: 'kilogram',
      ),
    );

    final emoji = firstString(
      order,
      const [
        'productEmoji',
        'emoji',
      ],
      fallback: '🐟',
    );

    return [
      _OrderLine(
        productId: productId,
        productName: productName,
        quantityUnit: quantityUnit,
        emoji: emoji,
        quantity: quantity,
        amount: completedAmount(order),
      ),
    ];
  }

  AnalyticsData buildAnalyticsData({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        historicalTransactions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  }) {
    final completedOrders = orders.where(
      (document) => isCompletedOrder(document.data()),
    ).toList();

    final eligibleHistorical = historicalTransactions.where(
      (document) => isEligibleHistoricalTransaction(document.data()),
    ).toList();

    double totalAmount = 0;

    final productMap = <String, ProductSummary>{};
    final productPeriodMap = <String, Map<String, PeriodPoint>>{};
    final quantityUnits = <String>{};

    void addLine({
      required _OrderLine line,
      required DateTime date,
      required double fallbackAmount,
    }) {
      final normalizedUnit = normalizeAnalyticsUnit(
        line.quantityUnit,
      );
      final normalizedProductName = analyticsProductKey(
        line.productName,
      );
      final productKey = '$normalizedProductName|$normalizedUnit';

      quantityUnits.add(normalizedUnit);

      final lineAmount = line.amount > 0 ? line.amount : fallbackAmount;
      final existingProduct = productMap[productKey];

      productMap[productKey] = ProductSummary(
        seriesKey: productKey,
        productName: line.productName,
        quantityUnit: normalizedUnit,
        emoji: line.emoji,
        quantity: (existingProduct?.quantity ?? 0) + line.quantity,
        amount: (existingProduct?.amount ?? 0) + lineAmount,
        transactionCount:
            (existingProduct?.transactionCount ?? 0) + 1,
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
      );
    }

    // Live operational orders.
    for (final document in completedOrders) {
      final data = document.data();
      final date = periodStart(
        orderDate(data),
      );
      final lines = extractOrderLines(data);
      final orderTotal = completedAmount(data);
      final lineTotals = lines.fold<double>(
        0,
        (total, line) => total + line.amount,
      );

      totalAmount += orderTotal > 0 ? orderTotal : lineTotals;

      for (final line in lines) {
        addLine(
          line: line,
          date: date,
          fallbackAmount: lines.length == 1 ? orderTotal : 0,
        );
      }
    }

    // Historical field records imported from the verified Transaction Log.
    // The source manual defines transaction_date as the analytics grouping
    // date and quantity_fulfilled as the completed purchase/sale quantity.
    for (final document in eligibleHistorical) {
      final data = document.data();
      final date = periodStart(
        historicalTransactionDate(data),
      );
      final lines = extractHistoricalLines(data);

      if (lines.isEmpty) {
        continue;
      }

      final historicalTotal = firstPositiveDouble(
        data,
        const [
          'totalAmount',
          'totalAmountPhp',
          'total_amount_php',
        ],
      );

      final lineTotals = lines.fold<double>(
        0,
        (total, line) => total + line.amount,
      );

      totalAmount += historicalTotal > 0
          ? historicalTotal
          : lineTotals;

      for (final line in lines) {
        addLine(
          line: line,
          date: date,
          fallbackAmount: historicalTotal,
        );
      }
    }

    final products = productMap.values.toList();
    final mixedUnits = quantityUnits.length > 1;

    products.sort(
      mixedUnits
          ? (a, b) => b.amount.compareTo(a.amount)
          : (a, b) => b.quantity.compareTo(a.quantity),
    );

    final productSeries = <String, List<PeriodPoint>>{};

    for (final entry in productPeriodMap.entries) {
      final points = entry.value.values.toList()
        ..sort(
          (a, b) => a.date.compareTo(b.date),
        );

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

    final quantities = selectedPoints
        .map(
          (point) => point.quantity,
        )
        .toList();

    final simpleForecast = simpleMovingAverageForecast(selectedPoints);
    final seasonalForecast = seasonalMovingAverageForecast(selectedPoints);
    final simpleEvaluation = evaluateSimpleMovingAverage(selectedPoints);
    final seasonalEvaluation = evaluateSeasonalMovingAverage(selectedPoints);
    final selectedMethod = selectForecastMethod(
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
      simpleEvaluation: simpleEvaluation,
      seasonalEvaluation: seasonalEvaluation,
    );
    final variabilityValue = variability(quantities);

    final rankingBasis = mixedUnits
        ? 'Ranked by completed transaction amount because fish-and-unit series use different units.'
        : 'Ranked by completed quantity within ${quantityUnits.isEmpty ? 'the recorded unit' : quantityUnits.first}.';

    return AnalyticsData(
      completedOrders:
          completedOrders.length + eligibleHistorical.length,
      liveCompletedOrders: completedOrders.length,
      historicalTransactions: eligibleHistorical.length,
      totalAmount: totalAmount,
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
      ),
      stockAlerts: buildStockAlerts(stocks),
    );
  }

  int get smaWindow {
    return selectedPeriod == AnalyticsPeriod.weekly ? 4 : 3;
  }

  int get seasonalInterval {
    return selectedPeriod == AnalyticsPeriod.weekly ? 4 : 12;
  }

  int get seasonalComparablePeriods {
    return selectedPeriod == AnalyticsPeriod.weekly ? 3 : 2;
  }

  int get seasonalMinimumPrecedingPeriods {
    return seasonalInterval * seasonalComparablePeriods;
  }

  String get periodName {
    return selectedPeriod == AnalyticsPeriod.weekly
        ? 'weekly'
        : 'monthly';
  }

  DateTime shiftAnalyticsPeriod(
    DateTime date,
    int offset,
  ) {
    final start = periodStart(date);

    if (selectedPeriod == AnalyticsPeriod.monthly) {
      return DateTime(
        start.year,
        start.month + offset,
      );
    }

    return start.add(
      Duration(
        days: 7 * offset,
      ),
    );
  }

  bool sameAnalyticsPeriod(
    DateTime left,
    DateTime right,
  ) {
    final leftStart = periodStart(left);
    final rightStart = periodStart(right);

    return leftStart.year == rightStart.year &&
        leftStart.month == rightStart.month &&
        leftStart.day == rightStart.day;
  }

  PeriodPoint? pointForAnalyticsPeriod(
    List<PeriodPoint> points,
    DateTime targetDate,
  ) {
    for (final point in points) {
      if (sameAnalyticsPeriod(
        point.date,
        targetDate,
      )) {
        return point;
      }
    }

    return null;
  }

  double meanOf(
    List<double> values,
  ) {
    if (values.isEmpty) {
      return 0;
    }

    return values.fold<double>(
          0,
          (total, value) => total + value,
        ) /
        values.length;
  }

  ForecastResult simpleMovingAverageForTarget({
    required List<PeriodPoint> precedingPoints,
    required DateTime targetDate,
  }) {
    final values = <double>[];

    for (var offset = smaWindow; offset >= 1; offset--) {
      final expectedDate = shiftAnalyticsPeriod(
        targetDate,
        -offset,
      );
      final point = pointForAnalyticsPeriod(
        precedingPoints,
        expectedDate,
      );

      if (point == null) {
        return ForecastResult.unavailable(
          reason:
              'Requires $smaWindow consecutive preceding $periodName periods.',
        );
      }

      values.add(
        point.quantity,
      );
    }

    return ForecastResult.available(
      meanOf(values),
    );
  }

  ForecastResult simpleMovingAverageForecast(
    List<PeriodPoint> points,
  ) {
    if (points.isEmpty) {
      return ForecastResult.unavailable(
        reason: 'No completed periods are available.',
      );
    }

    final targetDate = shiftAnalyticsPeriod(
      points.last.date,
      1,
    );

    return simpleMovingAverageForTarget(
      precedingPoints: points,
      targetDate: targetDate,
    );
  }

  ForecastResult seasonalMovingAverageForTarget({
    required List<PeriodPoint> precedingPoints,
    required DateTime targetDate,
  }) {
    // The final configuration requires not only the comparable lags but the
    // full preceding-history coverage: 12 weekly periods or 24 monthly
    // periods before the target.
    for (
      var offset = 1;
      offset <= seasonalMinimumPrecedingPeriods;
      offset++
    ) {
      final expectedDate = shiftAnalyticsPeriod(
        targetDate,
        -offset,
      );

      if (pointForAnalyticsPeriod(
            precedingPoints,
            expectedDate,
          ) ==
          null) {
        return ForecastResult.unavailable(
          reason: selectedPeriod == AnalyticsPeriod.weekly
              ? 'Requires 12 consecutive preceding weekly observations before the three 4-week seasonal comparisons can be evaluated.'
              : 'Requires 24 consecutive preceding monthly observations before the two 12-month seasonal comparisons can be evaluated.',
        );
      }
    }

    final comparableValues = <double>[];

    for (
      var comparableIndex = 1;
      comparableIndex <= seasonalComparablePeriods;
      comparableIndex++
    ) {
      final expectedDate = shiftAnalyticsPeriod(
        targetDate,
        -(seasonalInterval * comparableIndex),
      );

      final point = pointForAnalyticsPeriod(
        precedingPoints,
        expectedDate,
      );

      if (point == null) {
        return ForecastResult.unavailable(
          reason: selectedPeriod == AnalyticsPeriod.weekly
              ? 'Requires 3 comparable weekly observations spaced 4 weeks apart, with at least 12 preceding weeks.'
              : 'Requires 2 comparable monthly observations spaced 12 months apart, with at least 24 preceding months.',
        );
      }

      comparableValues.add(
        point.quantity,
      );
    }

    return ForecastResult.available(
      meanOf(comparableValues),
    );
  }

  ForecastResult seasonalMovingAverageForecast(
    List<PeriodPoint> points,
  ) {
    if (points.isEmpty) {
      return ForecastResult.unavailable(
        reason: 'No completed periods are available.',
      );
    }

    final targetDate = shiftAnalyticsPeriod(
      points.last.date,
      1,
    );

    return seasonalMovingAverageForTarget(
      precedingPoints: points,
      targetDate: targetDate,
    );
  }

  ForecastEvaluation evaluateSimpleMovingAverage(
    List<PeriodPoint> points,
  ) {
    return evaluateForecastMethod(
      points: points,
      method: ForecastingMethod.simpleMovingAverage,
    );
  }

  ForecastEvaluation evaluateSeasonalMovingAverage(
    List<PeriodPoint> points,
  ) {
    return evaluateForecastMethod(
      points: points,
      method: ForecastingMethod.seasonalMovingAverage,
    );
  }

  ForecastEvaluation evaluateForecastMethod({
    required List<PeriodPoint> points,
    required ForecastingMethod method,
  }) {
    final absoluteErrors = <double>[];
    final percentageErrors = <double>[];
    var zeroActualMapeExclusions = 0;

    for (var index = 0; index < points.length; index++) {
      final target = points[index];
      final preceding = points.sublist(
        0,
        index,
      );

      final forecast = switch (method) {
        ForecastingMethod.simpleMovingAverage =>
          simpleMovingAverageForTarget(
            precedingPoints: preceding,
            targetDate: target.date,
          ),
        ForecastingMethod.seasonalMovingAverage =>
          seasonalMovingAverageForTarget(
            precedingPoints: preceding,
            targetDate: target.date,
          ),
      };

      if (!forecast.hasValue) {
        continue;
      }

      final actual = target.quantity;
      final absoluteError = (actual - forecast.value).abs();

      // MAE keeps every otherwise valid actual-versus-forecast pair,
      // including a valid target period whose actual quantity equals zero.
      absoluteErrors.add(
        absoluteError,
      );

      // MAPE excludes zero actuals because the actual value is the
      // denominator. The exclusion is counted and surfaced in the UI.
      if (actual == 0) {
        zeroActualMapeExclusions++;
      } else {
        percentageErrors.add(
          absoluteError / actual.abs() * 100,
        );
      }
    }

    if (absoluteErrors.isEmpty) {
      final reason = method == ForecastingMethod.simpleMovingAverage
          ? 'No target period yet has $smaWindow valid preceding $periodName observations for one-period-ahead SMA evaluation.'
          : selectedPeriod == AnalyticsPeriod.weekly
              ? 'No target period yet has the 12 preceding weeks needed for three 4-week seasonal comparisons.'
              : 'No target period yet has the 24 preceding months needed for two 12-month seasonal comparisons.';

      return ForecastEvaluation.unavailable(
        reason: reason,
      );
    }

    final mae = meanOf(
      absoluteErrors,
    );

    final hasMape = percentageErrors.isNotEmpty;
    final mape = hasMape
        ? meanOf(
            percentageErrors,
          )
        : 0.0;

    return ForecastEvaluation.available(
      mape: mape,
      mae: mae,
      hasMape: hasMape,
      maePairCount: absoluteErrors.length,
      mapePairCount: percentageErrors.length,
      zeroActualMapeExclusions: zeroActualMapeExclusions,
      reason: hasMape
          ? ''
          : 'MAPE is unavailable because every valid evaluation pair has an actual quantity of zero. MAE remains valid.',
    );
  }

  ForecastMethodSelection selectForecastMethod({
    required ForecastResult simpleForecast,
    required ForecastResult seasonalForecast,
    required ForecastEvaluation simpleEvaluation,
    required ForecastEvaluation seasonalEvaluation,
  }) {
    final simpleEligible = simpleForecast.hasValue &&
        simpleEvaluation.hasMae &&
        simpleEvaluation.hasMape;

    final seasonalEligible = seasonalForecast.hasValue &&
        seasonalEvaluation.hasMae &&
        seasonalEvaluation.hasMape;

    if (simpleEligible && !seasonalEligible) {
      return ForecastMethodSelection.selected(
        method: ForecastingMethod.simpleMovingAverage,
        forecast: simpleForecast.value,
        reason:
            'Simple Moving Average is the only method currently eligible for accuracy-based selection.',
      );
    }

    if (!simpleEligible && seasonalEligible) {
      return ForecastMethodSelection.selected(
        method: ForecastingMethod.seasonalMovingAverage,
        forecast: seasonalForecast.value,
        reason:
            'Seasonal Moving Average is the only method currently eligible for accuracy-based selection.',
      );
    }

    if (!simpleEligible && !seasonalEligible) {
      return ForecastMethodSelection.unavailable(
        reason:
            'A selected method will appear when at least one forecast has a valid MAPE evaluation.',
      );
    }

    const tolerance = 0.0000001;
    final mapeDifference =
        (simpleEvaluation.mape - seasonalEvaluation.mape).abs();

    if (mapeDifference > tolerance) {
      if (simpleEvaluation.mape < seasonalEvaluation.mape) {
        return ForecastMethodSelection.selected(
          method: ForecastingMethod.simpleMovingAverage,
          forecast: simpleForecast.value,
          reason: 'Selected because it has the lower MAPE.',
        );
      }

      return ForecastMethodSelection.selected(
        method: ForecastingMethod.seasonalMovingAverage,
        forecast: seasonalForecast.value,
        reason: 'Selected because it has the lower MAPE.',
      );
    }

    final maeDifference =
        (simpleEvaluation.mae - seasonalEvaluation.mae).abs();

    if (maeDifference > tolerance) {
      if (simpleEvaluation.mae < seasonalEvaluation.mae) {
        return ForecastMethodSelection.selected(
          method: ForecastingMethod.simpleMovingAverage,
          forecast: simpleForecast.value,
          reason:
              'MAPE is tied, so Simple Moving Average is selected by the lower MAE.',
        );
      }

      return ForecastMethodSelection.selected(
        method: ForecastingMethod.seasonalMovingAverage,
        forecast: seasonalForecast.value,
        reason:
            'MAPE is tied, so Seasonal Moving Average is selected by the lower MAE.',
      );
    }

    // The controlling analytics configuration defines lower MAE as the
    // tie-break after MAPE, but it does not define a third tie-break when
    // both measures are exactly equal. Do not invent one.
    return ForecastMethodSelection.unavailable(
      reason:
          'MAPE and MAE are tied for both eligible methods, so no method is automatically preferred.',
    );
  }

  double roundForecastQuantity(
    double value,
  ) {
    final nonNegative = math.max(
      0,
      value,
    ).toDouble();

    return (nonNegative * 100).roundToDouble() / 100;
  }

  double variability(
    List<double> values,
  ) {
    if (values.length < 2) {
      return 0;
    }

    final mean = values.fold<double>(
          0,
          (total, value) => total + value,
        ) /
        values.length;

    if (mean == 0) {
      return 0;
    }

    // Final analytics configuration uses the sample standard deviation,
    // therefore variance is divided by n - 1 rather than n.
    final variance = values.map(
      (value) => math.pow(
        value - mean,
        2,
      ).toDouble(),
    ).fold<double>(
          0,
          (total, value) => total + value,
        ) /
        (values.length - 1);

    return math.sqrt(variance) / mean * 100;
  }

  List<StockAlert> buildStockAlerts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  ) {
    if (!isSupplier) {
      return const [];
    }

    final alerts = <StockAlert>[];

    for (final document in stocks) {
      final data = document.data();
      final status = firstString(
        data,
        const [
          'stockStatus',
          'status',
        ],
        fallback: 'available',
      ).toLowerCase();

      if (status == 'hidden' || status == 'unavailable') {
        continue;
      }

      final quantity = doubleValue(
        data,
        'quantity',
      );
      final lowStockLevel = doubleValue(
        data,
        'lowStockLevel',
      );

      if (quantity > lowStockLevel) {
        continue;
      }

      alerts.add(
        StockAlert(
          productName: firstString(
            data,
            const [
              'productName',
              'fishName',
            ],
            fallback: 'Fish Product',
          ),
          emoji: firstString(
            data,
            const [
              'productEmoji',
              'emoji',
            ],
            fallback: '🐟',
          ),
          quantity: quantity,
          quantityUnit: firstString(
            data,
            const [
              'quantityUnit',
              'unit',
            ],
            fallback: 'kilo',
          ),
          lowStockLevel: lowStockLevel,
        ),
      );
    }

    alerts.sort(
      (a, b) => a.quantity.compareTo(b.quantity),
    );

    return alerts;
  }

  List<RestockingSuggestion> buildSuggestions({
    required List<ProductSummary> products,
    required Map<String, List<PeriodPoint>> productSeries,
  }) {
    final suggestions = <RestockingSuggestion>[];

    for (final product in products.take(4)) {
      final points =
          productSeries[product.seriesKey] ?? const <PeriodPoint>[];

      final simple = simpleMovingAverageForecast(
        points,
      );
      final seasonal = seasonalMovingAverageForecast(
        points,
      );
      final simpleEvaluation = evaluateSimpleMovingAverage(
        points,
      );
      final seasonalEvaluation = evaluateSeasonalMovingAverage(
        points,
      );

      final selection = selectForecastMethod(
        simpleForecast: simple,
        seasonalForecast: seasonal,
        simpleEvaluation: simpleEvaluation,
        seasonalEvaluation: seasonalEvaluation,
      );

      if (!selection.hasSelection) {
        continue;
      }

      final suggestedQuantity = roundForecastQuantity(
        selection.forecast,
      );

      if (suggestedQuantity <= 0) {
        continue;
      }

      suggestions.add(
        RestockingSuggestion(
          productName: product.productName,
          emoji: product.emoji,
          quantityUnit: product.quantityUnit,
          suggestedQuantity: suggestedQuantity,
          selectedMethod: selection.method!,
        ),
      );
    }

    return suggestions;
  }

  String forecastingMethodLabel(
    ForecastingMethod method,
  ) {
    return switch (method) {
      ForecastingMethod.simpleMovingAverage => 'Simple Moving Average',
      ForecastingMethod.seasonalMovingAverage => 'Seasonal Moving Average',
    };
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
      expandedHeight: 300,
      toolbarHeight: 62,
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
        padding: const EdgeInsets.only(
          left: 12,
        ),
        child: _HeaderButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            Navigator.pop(context);
          },
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
                Color(0xFF063B66),
                Color(0xFF075FAE),
                Color(0xFF146BFF),
              ],
              stops: [
                0.0,
                0.56,
                1.0,
              ],
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
                  MediaQuery.paddingOf(context).top + 66,
                  18,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withAlpha(35),
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
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            roleLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.7,
                              letterSpacing: 0.75,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDDEFFA),
                        fontSize: 11,
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
                          icon: Icons.category_outlined,
                          value: '${data.products.length}',
                          label: 'Series',
                        ),
                        const SizedBox(width: 9),
                        _HeaderMetric(
                          icon: Icons.payments_outlined,
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
          bottom: Radius.circular(29),
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Color iconColor = const Color(0xFF146BFF),
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F00152A),
            blurRadius: 16,
            offset: Offset(0, 8),
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
                width: 41,
                height: 41,
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
                        fontSize: 15.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10.8,
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

  Widget seriesSelector(
    AnalyticsData data,
  ) {
    final selected = data.selectedProduct;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.products.isEmpty
            ? null
            : () {
                showSeriesPicker(data);
              },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(
            13,
            12,
            12,
            12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7FB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFB8DFFF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F4FD),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  selected?.emoji ?? '🐟',
                  style: const TextStyle(
                    fontSize: 23,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FISH AND UNIT SERIES',
                      style: TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.8,
                        letterSpacing: 0.55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selected == null
                          ? 'No series available'
                          : '${selected.productName} · ${selected.quantityUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${selected.transactionCount} completed transaction${selected.transactionCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF52677A),
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showSeriesPicker(
    AnalyticsData data,
  ) async {
    final searchController = TextEditingController();

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(165),
      builder: (
        sheetContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final query =
                searchController.text.trim().toLowerCase();

            final filtered = data.products.where(
              (product) {
                if (query.isEmpty) {
                  return true;
                }

                return product.productName.toLowerCase().contains(query) ||
                    product.quantityUnit.toLowerCase().contains(query);
              },
            ).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(sheetContext).size.height * 0.82,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBFD),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
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
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        12,
                        14,
                      ),
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
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        13,
                      ),
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
                                  icon: const Icon(
                                    Icons.close_rounded,
                                  ),
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
                    Divider(
                      height: 1,
                      color: Colors.black.withAlpha(15),
                    ),
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
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                8,
                                12,
                                20,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (
                                context,
                                index,
                              ) {
                                return const SizedBox(height: 4);
                              },
                              itemBuilder: (
                                context,
                                index,
                              ) {
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
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 170),
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
                                        borderRadius:
                                            BorderRadius.circular(16),
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
                                                  '${product.productName} · ${product.quantityUnit}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF102C44),
                                                    fontSize: 12.5,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${formatNumber(product.quantity)} ${product.quantityUnit} · ${product.transactionCount} transaction${product.transactionCount == 1 ? '' : 's'}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF7B8FA3),
                                                    fontSize: 9.5,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .chevron_right_rounded,
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
    });
  }

  Widget analyticsFilters(
    AnalyticsData data,
  ) {
    return sectionCard(
      title: 'Analytics Filters',
      subtitle:
          'Choose a period and one fish-and-unit series for accurate analysis.',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          periodSelector(),
          const SizedBox(height: 11),
          seriesSelector(data),
        ],
      ),
    );
  }

  Widget trendChart(
    List<PeriodPoint> points,
  ) {
    if (points.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.show_chart_rounded,
        title: 'No completed periods for this series',
        subtitle: 'Select another fish series or complete more COD orders.',
      );
    }

    final visible = points.length > 8
        ? points.sublist(
            points.length - 8,
          )
        : points;

    return Column(
      children: [
        Container(
          height: 172,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            10,
            12,
            10,
            7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: CustomPaint(
            painter: _TrendChartPainter(
              values: visible
                  .map(
                    (point) => point.quantity,
                  )
                  .toList(),
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
                    fontSize: 7.4,
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

  Widget selectedSeriesSummary(
    AnalyticsData data,
  ) {
    final product = data.selectedProduct;

    if (product == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9F7FF),
            Color(0xFFEAFBF5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF39C9A0).withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              product.emoji,
              style: const TextStyle(
                fontSize: 23,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECTED SERIES',
                  style: TextStyle(
                    color: Color(0xFF147D64),
                    fontSize: 8.8,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.productName} · ${product.quantityUnit}',
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.selectedPoints.length} completed ${selectedPeriod == AnalyticsPeriod.weekly ? 'weekly' : 'monthly'} period${data.selectedPoints.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF1DBB8A),
            size: 22,
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
    bool selected = false,
  }) {
    final available = result.hasValue;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFFF2F8FD)
            : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: available
              ? const Color(0xFFCFE5F5)
              : const Color(0xFFE3E9EE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: available
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF0875D1),
                        Color(0xFF176BFF),
                      ],
                    )
                  : null,
              color: available
                  ? null
                  : const Color(0xFFE4EBF0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: available
                  ? Colors.white
                  : const Color(0xFF8BA0B1),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
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
                          fontSize: 13,
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
                          color: const Color(0xFFE4F6EE),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'SELECTED',
                          style: TextStyle(
                            color: Color(0xFF147D64),
                            fontSize: 7.2,
                            letterSpacing: 0.4,
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
                    color: Color(0xFF6D8293),
                    fontSize: 10.2,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (available)
                  Text(
                    'Forecast: ${formatNumber(result.value)} $unit',
                    style: const TextStyle(
                      color: Color(0xFF0875D1),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else ...[
                  const Text(
                    'Not enough data',
                    style: TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    result.reason,
                    style: const TextStyle(
                      color: Color(0xFF8BA0B1),
                      fontSize: 9.4,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                fontSize: 19,
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
                fontSize: 9.1,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget methodEvaluationCard({
    required String title,
    required ForecastEvaluation evaluation,
    required String unit,
    required bool selected,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFF0FAF6)
            : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? const Color(0xFFBEE7D8)
              : const Color(0xFFE0EAF0),
        ),
      ),
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
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF147D64),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 9),
          if (!evaluation.hasMae)
            Text(
              evaluation.reason,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 9.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Row(
              children: [
                evaluationTile(
                  label: 'MAPE',
                  value: evaluation.hasMape
                      ? '${evaluation.mape.toStringAsFixed(2)}%'
                      : 'N/A',
                  subtitle: evaluation.hasMape
                      ? '${evaluation.mapePairCount} valid percentage-error pair${evaluation.mapePairCount == 1 ? '' : 's'}'
                      : 'Zero actuals cannot enter MAPE',
                  color: const Color(0xFF176BFF),
                ),
                const SizedBox(width: 9),
                evaluationTile(
                  label: 'MAE',
                  value:
                      '${formatNumber(evaluation.mae)} $unit',
                  subtitle:
                      '${evaluation.maePairCount} valid absolute-error pair${evaluation.maePairCount == 1 ? '' : 's'}',
                  color: const Color(0xFFFF7A1A),
                ),
              ],
            ),
            if (evaluation.zeroActualMapeExclusions > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${evaluation.zeroActualMapeExclusions} valid pair${evaluation.zeroActualMapeExclusions == 1 ? '' : 's'} with actual quantity 0 ${evaluation.zeroActualMapeExclusions == 1 ? 'was' : 'were'} excluded from MAPE but retained in MAE.',
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 8.9,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget forecastEvaluation(
    AnalyticsData data,
  ) {
    final product = data.selectedProduct;

    if (product == null) {
      return const SizedBox.shrink();
    }

    final selection = data.selectedMethod;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            bottom: 11,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selection.hasSelection
                ? const Color(0xFFEAF7FB)
                : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selection.hasSelection
                  ? const Color(0xFFCBE6F1)
                  : const Color(0xFFE0E7EC),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selection.hasSelection
                    ? Icons.workspace_premium_rounded
                    : Icons.hourglass_top_rounded,
                color: selection.hasSelection
                    ? const Color(0xFF087AC0)
                    : const Color(0xFF7B8FA3),
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selection.hasSelection
                          ? 'Selected Method: ${forecastingMethodLabel(selection.method!)}'
                          : 'Method Selection Pending',
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selection.reason,
                      style: const TextStyle(
                        color: Color(0xFF657C8E),
                        fontSize: 9.3,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (selection.hasSelection) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Next-period forecast: ${formatNumber(selection.forecast, decimals: 2)} ${product.quantityUnit}',
                        style: const TextStyle(
                          color: Color(0xFF087AC0),
                          fontSize: 9.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        methodEvaluationCard(
          title: 'Simple Moving Average',
          evaluation: data.simpleEvaluation,
          unit: product.quantityUnit,
          selected: selection.method ==
              ForecastingMethod.simpleMovingAverage,
        ),
        methodEvaluationCard(
          title: 'Seasonal Moving Average',
          evaluation: data.seasonalEvaluation,
          unit: product.quantityUnit,
          selected: selection.method ==
              ForecastingMethod.seasonalMovingAverage,
        ),
      ],
    );
  }

  Widget variabilityPanel(
    double value,
  ) {
    String label;
    String message;
    Color color;

    if (value <= 0) {
      label = 'Not enough data';
      message = 'At least two completed periods are required.';
      color = const Color(0xFF8BA0B1);
    } else if (value <= 10) {
      label = 'Low variability';
      message = 'Coefficient of variation is 10% or less.';
      color = const Color(0xFF147D64);
    } else if (value <= 25) {
      label = 'Moderate variability';
      message = 'Coefficient of variation is above 10% through 25%.';
      color = const Color(0xFFFF7A1A);
    } else {
      label = 'High variability';
      message = 'Completed quantities fluctuate considerably.';
      color = const Color(0xFFD32F2F);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withAlpha(50),
        ),
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
              value <= 0 ? '--' : '${value.toStringAsFixed(1)}%',
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

  Widget suggestions(
    List<RestockingSuggestion> suggestions,
  ) {
    if (suggestions.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No restocking suggestion yet',
        subtitle:
            'A suggestion appears after an eligible forecast method has an accuracy evaluation for the selected product-and-unit series.',
      );
    }

    return Column(
      children: suggestions.map(
        (suggestion) {
          return Container(
            margin: const EdgeInsets.only(
              bottom: 9,
            ),
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
                    style: const TextStyle(
                      fontSize: 22,
                    ),
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
                            ? 'Consider preparing ${formatNumber(suggestion.suggestedQuantity, decimals: 2)} ${suggestion.quantityUnit} for the next period.'
                            : 'Consider purchasing ${formatNumber(suggestion.suggestedQuantity, decimals: 2)} ${suggestion.quantityUnit} for the next period.',
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

  Widget stockAlerts(
    List<StockAlert> alerts,
  ) {
    if (alerts.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No stock alerts',
        subtitle: 'Current supplier inventory does not require attention.',
      );
    }

    return Column(
      children: alerts.take(5).map(
        (alert) {
          final outOfStock = alert.quantity <= 0;
          final color = outOfStock
              ? const Color(0xFFD32F2F)
              : const Color(0xFFFF7A1A);

          return Container(
            margin: const EdgeInsets.only(
              bottom: 9,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withAlpha(40),
              ),
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
                  child: Text(
                    alert.emoji,
                    style: const TextStyle(
                      fontSize: 22,
                    ),
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
                          fontSize: 12.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatNumber(alert.quantity)} ${alert.quantityUnit} remaining · Alert at ${formatNumber(alert.lowStockLevel)} ${alert.quantityUnit}',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
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
        },
      ).toList(),
    );
  }

  Widget topProducts(
    List<ProductSummary> products,
  ) {
    return Column(
      children: products.take(5).toList().asMap().entries.map(
        (entry) {
          final product = entry.value;

          return Container(
            margin: const EdgeInsets.only(
              bottom: 8,
            ),
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
                const SizedBox(width: 9),
                Text(
                  product.emoji,
                  style: const TextStyle(
                    fontSize: 21,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product.productName} · ${product.quantityUnit}',
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
                        '${formatNumber(product.quantity)} ${product.quantityUnit} · ${product.transactionCount} transaction${product.transactionCount == 1 ? '' : 's'}',
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
                  formatCurrency(product.amount),
                  style: const TextStyle(
                    color: Color(0xFF0875D1),
                    fontSize: 11.2,
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

  Widget roleDataNote(
    AnalyticsData data,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF72C6F8).withAlpha(75),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(170),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: Color(0xFF146BFF),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROLE-SPECIFIC DATA',
                  style: TextStyle(
                    color: Color(0xFF146BFF),
                    fontSize: 8.8,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSupplier
                      ? 'This screen combines ${data.historicalTransactions} linked validated historical sale${data.historicalTransactions == 1 ? '' : 's'} with ${data.liveCompletedOrders} completed live COD sale${data.liveCompletedOrders == 1 ? '' : 's'} for this supplier account. Current inventory is used only for stock alerts.'
                      : 'This screen combines ${data.historicalTransactions} linked validated historical purchase${data.historicalTransactions == 1 ? '' : 's'} with ${data.liveCompletedOrders} completed live COD purchase${data.liveCompletedOrders == 1 ? '' : 's'} for this vendor account. Supplier sales are excluded.',
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 10.5,
                    height: 1.38,
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

  Widget noDataOverview(
    AnalyticsData data,
  ) {
    return CustomScrollView(
      slivers: [
        analyticsHeader(data),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFE1EBF2),
                    ),
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
                            colors: [
                              Color(0xFFE8F6FF),
                              Color(0xFFE9FBF5),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF9BD8F9),
                          ),
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
                        padding: const EdgeInsets.fromLTRB(
                          13,
                          12,
                          13,
                          12,
                        ),
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            isSupplier
                                ? Icons.receipt_long_outlined
                                : Icons.storefront_outlined,
                            size: 20,
                          ),
                          label: Text(
                            emptyActionLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
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
                    subtitle:
                        'Current low-stock and out-of-stock listings still require attention.',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFFFF7A1A),
                    child: stockAlerts(data.stockAlerts),
                  ),
                ],
                roleDataNote(data),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget analyticsContent(
    AnalyticsData data,
  ) {
    if (!data.hasTransactions) {
      return noDataOverview(data);
    }

    final selectedProduct = data.selectedProduct;

    return CustomScrollView(
      slivers: [
        analyticsHeader(data),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                analyticsFilters(data),
                selectedSeriesSummary(data),
                sectionCard(
                  title: trendTitle,
                  subtitle:
                      '$trendDescription Showing the most recent ${data.selectedPoints.length > 8 ? '8' : data.selectedPoints.length} period${data.selectedPoints.length == 1 ? '' : 's'}.',
                  icon: Icons.auto_graph_rounded,
                  child: trendChart(data.selectedPoints),
                ),
                sectionCard(
                  title: 'Forecast Summary',
                  subtitle:
                      'Forecasts are calculated only for ${selectedProduct?.productName ?? 'the selected fish'} in ${selectedProduct?.quantityUnit ?? 'its recorded unit'}.',
                  icon: Icons.trending_up_rounded,
                  child: Column(
                    children: [
                      forecastMethodCard(
                        title: 'Simple Moving Average',
                        description: selectedPeriod == AnalyticsPeriod.weekly
                            ? 'Uses the 4 immediately preceding weekly observations.'
                            : 'Uses the 3 immediately preceding monthly observations.',
                        result: data.simpleForecast,
                        unit: selectedProduct?.quantityUnit ?? 'unit',
                        icon: Icons.show_chart_rounded,
                        selected: data.selectedMethod.method ==
                            ForecastingMethod.simpleMovingAverage,
                      ),
                      forecastMethodCard(
                        title: 'Seasonal Moving Average',
                        description: selectedPeriod == AnalyticsPeriod.weekly
                            ? 'Averages 3 comparable weekly observations spaced 4 weeks apart; requires at least 12 preceding weeks.'
                            : 'Averages 2 comparable monthly observations spaced 12 months apart; requires at least 24 preceding months.',
                        result: data.seasonalForecast,
                        unit: selectedProduct?.quantityUnit ?? 'unit',
                        icon: Icons.calendar_month_rounded,
                        selected: data.selectedMethod.method ==
                            ForecastingMethod.seasonalMovingAverage,
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Forecast Evaluation',
                  subtitle:
                      'SMA and Seasonal Moving Average are evaluated separately using one-period-ahead forecasts. Lower MAPE selects the method; lower MAE breaks a MAPE tie.',
                  icon: Icons.fact_check_outlined,
                  child: forecastEvaluation(data),
                ),
                if (isSupplier)
                  sectionCard(
                    title: 'Sales Variability',
                    subtitle:
                        'Shows how much the selected sales series changes across completed periods.',
                    icon: Icons.multiline_chart_rounded,
                    child: variabilityPanel(data.variability),
                  ),
                sectionCard(
                  title: 'Restocking Suggestions',
                  subtitle: isSupplier
                      ? 'Forecast-based guidance supports stock preparation and never changes inventory automatically.'
                      : 'Forecast-based guidance supports purchasing decisions and never places orders automatically.',
                  icon: Icons.notifications_active_outlined,
                  child: suggestions(data.suggestions),
                ),
                if (isSupplier)
                  sectionCard(
                    title: 'Stock Alerts',
                    subtitle:
                        'Current low-stock and out-of-stock listings owned by this supplier account.',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFFFF7A1A),
                    child: stockAlerts(data.stockAlerts),
                  ),
                sectionCard(
                  title: isSupplier
                      ? 'Top-Selling Fish Insights'
                      : 'Top Purchased Fish Insights',
                  subtitle: data.rankingBasis,
                  icon: Icons.emoji_events_outlined,
                  child: topProducts(data.products),
                ),
                roleDataNote(data),
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
              color: Color(0xFF146BFF),
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
              child: _CompactEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load analytics',
                subtitle:
                    'Please check your connection and try opening Analytics again.',
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
        builder: (
          context,
          orderSnapshot,
        ) {
          if (orderSnapshot.hasError) {
            return errorBody(
              orderSnapshot.error!,
            );
          }

          if (!orderSnapshot.hasData) {
            return loadingBody();
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: historicalTransactionsStream(user.uid),
            builder: (
              context,
              historicalSnapshot,
            ) {
              if (historicalSnapshot.hasError) {
                return errorBody(
                  historicalSnapshot.error!,
                );
              }

              if (!historicalSnapshot.hasData) {
                return loadingBody();
              }

              if (!isSupplier) {
                final data = buildAnalyticsData(
                  orders: orderSnapshot.data!.docs,
                  historicalTransactions:
                      historicalSnapshot.data!.docs,
                  stocks: const [],
                );

                return analyticsContent(data);
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: supplierStocksStream(user.uid),
                builder: (
                  context,
                  stockSnapshot,
                ) {
                  if (stockSnapshot.hasError) {
                    return errorBody(
                      stockSnapshot.error!,
                    );
                  }

                  if (!stockSnapshot.hasData) {
                    return loadingBody();
                  }

                  final data = buildAnalyticsData(
                    orders: orderSnapshot.data!.docs,
                    historicalTransactions:
                        historicalSnapshot.data!.docs,
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

class AnalyticsData {
  const AnalyticsData({
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

  final int completedOrders;
  final int liveCompletedOrders;
  final int historicalTransactions;
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
  final double variability;
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
      variability: 0,
      suggestions: const [],
      stockAlerts: const [],
    );
  }
}

class _OrderLine {
  const _OrderLine({
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
    required this.transactionCount,
  });

  final String seriesKey;
  final String productName;
  final String quantityUnit;
  final String emoji;
  final double quantity;
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
  });

  final String productName;
  final String emoji;
  final String quantityUnit;
  final double suggestedQuantity;
  final ForecastingMethod selectedMethod;
}

class ForecastResult {
  const ForecastResult._({
    required this.value,
    required this.hasValue,
    required this.reason,
  });

  final double value;
  final bool hasValue;
  final String reason;

  factory ForecastResult.available(
    double value,
  ) {
    return ForecastResult._(
      value: value,
      hasValue: true,
      reason: '',
    );
  }

  factory ForecastResult.unavailable({
    required String reason,
  }) {
    return ForecastResult._(
      value: 0,
      hasValue: false,
      reason: reason,
    );
  }
}

enum ForecastingMethod {
  simpleMovingAverage,
  seasonalMovingAverage,
}

class ForecastEvaluation {
  const ForecastEvaluation._({
    required this.mape,
    required this.mae,
    required this.hasMape,
    required this.hasMae,
    required this.maePairCount,
    required this.mapePairCount,
    required this.zeroActualMapeExclusions,
    required this.reason,
  });

  final double mape;
  final double mae;
  final bool hasMape;
  final bool hasMae;
  final int maePairCount;
  final int mapePairCount;
  final int zeroActualMapeExclusions;
  final String reason;

  factory ForecastEvaluation.available({
    required double mape,
    required double mae,
    required bool hasMape,
    required int maePairCount,
    required int mapePairCount,
    required int zeroActualMapeExclusions,
    required String reason,
  }) {
    return ForecastEvaluation._(
      mape: mape,
      mae: mae,
      hasMape: hasMape,
      hasMae: true,
      maePairCount: maePairCount,
      mapePairCount: mapePairCount,
      zeroActualMapeExclusions: zeroActualMapeExclusions,
      reason: reason,
    );
  }

  factory ForecastEvaluation.unavailable({
    required String reason,
  }) {
    return ForecastEvaluation._(
      mape: 0,
      mae: 0,
      hasMape: false,
      hasMae: false,
      maePairCount: 0,
      mapePairCount: 0,
      zeroActualMapeExclusions: 0,
      reason: reason,
    );
  }
}

class ForecastMethodSelection {
  const ForecastMethodSelection._({
    required this.method,
    required this.forecast,
    required this.reason,
  });

  final ForecastingMethod? method;
  final double forecast;
  final String reason;

  bool get hasSelection => method != null;

  factory ForecastMethodSelection.selected({
    required ForecastingMethod method,
    required double forecast,
    required String reason,
  }) {
    return ForecastMethodSelection._(
      method: method,
      forecast: forecast,
      reason: reason,
    );
  }

  factory ForecastMethodSelection.unavailable({
    required String reason,
  }) {
    return ForecastMethodSelection._(
      method: null,
      forecast: 0,
      reason: reason,
    );
  }
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(24),
            ),
          ),
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
        constraints: const BoxConstraints(
          minHeight: 66,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha(32),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFDCEFFA),
                fontSize: 8,
                fontWeight: FontWeight.w800,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
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
                  : const Color(0xFF6F8798),
              fontSize: 11.2,
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        17,
        14,
        17,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF93ADBF),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8BA0B1),
              fontSize: 9.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
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
    if (values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE0EAF1)
      ..strokeWidth = 1;

    for (var index = 0; index <= 3; index++) {
      final y = size.height * index / 3;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
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
      final x = values.length == 1
          ? size.width / 2
          : horizontalStep * index;
      final y = size.height - normalized * (size.height * 0.78) - 12;

      points.add(
        Offset(
          x,
          y.clamp(10.0, size.height - 10.0).toDouble(),
        ),
      );
    }

    if (points.length > 1) {
      final fillPath = Path()
        ..moveTo(
          points.first.dx,
          size.height,
        );

      for (final point in points) {
        fillPath.lineTo(
          point.dx,
          point.dy,
        );
      }

      fillPath
        ..lineTo(
          points.last.dx,
          size.height,
        )
        ..close();

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x42146BFF),
            Color(0x00146BFF),
          ],
        ).createShader(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
        );

      canvas.drawPath(
        fillPath,
        fillPaint,
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFF146BFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()
      ..moveTo(
        points.first.dx,
        points.first.dy,
      );

    for (final point in points.skip(1)) {
      linePath.lineTo(
        point.dx,
        point.dy,
      );
    }

    canvas.drawPath(
      linePath,
      linePaint,
    );

    for (final point in points) {
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = Colors.white,
      );
      canvas.drawCircle(
        point,
        3.2,
        Paint()
          ..color = const Color(0xFF146BFF),
      );
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
    final largeCircle = Paint()
      ..color = Colors.white.withAlpha(13);

    final circleBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(22);

    canvas.drawCircle(
      Offset(
        size.width * 0.88,
        size.height * 0.16,
      ),
      size.width * 0.25,
      largeCircle,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.86,
        size.height * 0.25,
      ),
      size.width * 0.19,
      circleBorder,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.77,
        size.height * 0.47,
      ),
      size.width * 0.11,
      circleBorder,
    );

    final accent = Paint()
      ..color = Colors.white.withAlpha(10);

    final path = Path()
      ..moveTo(
        size.width * 0.57,
        size.height,
      )
      ..lineTo(
        size.width,
        size.height * 0.52,
      )
      ..lineTo(
        size.width,
        size.height,
      )
      ..close();

    canvas.drawPath(
      path,
      accent,
    );
  }

  @override
  bool shouldRepaint(
    covariant _AnalyticsHeaderPainter oldDelegate,
  ) {
    return false;
  }
}
