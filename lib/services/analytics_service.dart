import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/models/analytics_models.dart';
import 'package:isdalink/utils/order_helpers.dart';

class AnalyticsService {
  const AnalyticsService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream({
    required String uid,
    required bool isSupplierMode,
  }) {
    final field = isSupplierMode ? 'supplierId' : 'vendorId';

    return FirebaseFirestore.instance
        .collection('orders')
        .where(field, isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fishStocksStream({
    required String uid,
    required bool isSupplierMode,
  }) {
    if (isSupplierMode) {
      return FirebaseFirestore.instance
          .collection('fishStocks')
          .where('supplierId', isEqualTo: uid)
          .snapshots();
    }

    return FirebaseFirestore.instance.collection('fishStocks').snapshots();
  }

  bool hasSupplierAccess(
    Map<String, dynamic> userData,
  ) {
    final role = OrderHelpers.getStringValue(
      userData,
      'role',
      'vendor',
    ).toLowerCase();

    final supplierStatus = OrderHelpers.getStringValue(
      userData,
      'supplierStatus',
      'not_applicable',
    ).toLowerCase();

    return role == 'supplier' || supplierStatus == 'approved';
  }

  bool isCompletedOrder(
    Map<String, dynamic> data,
  ) {
    final status = OrderHelpers.getStringValue(
      data,
      'orderStatus',
      'Pending',
    ).toLowerCase();

    return status == 'delivered' || status == 'completed';
  }

  double simpleMovingAverage(
    List<double> values, {
    int window = 3,
  }) {
    if (values.isEmpty) {
      return 0.0;
    }

    final usableWindow = values.length < window ? values.length : window;
    final recentValues = values.sublist(values.length - usableWindow);

    final totalValue = recentValues.fold<double>(
      0.0,
      (runningTotal, value) => runningTotal + value,
    );

    return totalValue / usableWindow;
  }

  double seasonalMovingAverage(
    List<DailySalesPoint> points,
  ) {
    if (points.isEmpty) {
      return 0.0;
    }

    final now = DateTime.now();
    final sameWeekday = points
        .where(
          (point) => point.date.weekday == now.weekday,
        )
        .map(
          (point) => point.quantity,
        )
        .toList();

    if (sameWeekday.isEmpty) {
      return simpleMovingAverage(
        points.map((point) => point.quantity).toList(),
      );
    }

    final totalValue = sameWeekday.fold<double>(
      0.0,
      (runningTotal, value) => runningTotal + value,
    );

    return totalValue / sameWeekday.length;
  }

  ForecastEvaluation evaluateSimpleMovingAverage(
    List<double> values, {
    int window = 3,
  }) {
    if (values.length <= window) {
      return const ForecastEvaluation(
        mape: 0.0,
        mae: 0.0,
        hasEnoughData: false,
      );
    }

    final absoluteErrors = <double>[];
    final percentageErrors = <double>[];

    for (var index = window; index < values.length; index++) {
      final previousValues = values.sublist(index - window, index);
      final forecast = previousValues.fold<double>(
            0.0,
            (runningTotal, value) => runningTotal + value,
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
          0.0,
          (runningTotal, value) => runningTotal + value,
        ) /
        absoluteErrors.length;

    final mape = percentageErrors.isEmpty
        ? 0.0
        : percentageErrors.fold<double>(
              0.0,
              (runningTotal, value) => runningTotal + value,
            ) /
            percentageErrors.length;

    return ForecastEvaluation(
      mape: mape,
      mae: mae,
      hasEnoughData: true,
    );
  }

  DateTime dateFromOrderData(
    Map<String, dynamic> data,
  ) {
    final deliveredAt = data['deliveredAt'];
    final createdAt = data['createdAt'];

    if (deliveredAt is Timestamp) {
      return deliveredAt.toDate();
    }

    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return DateTime.now();
  }

  AnalyticsData buildAnalyticsData({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orderDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stockDocuments,
  }) {
    final completedOrders = orderDocuments.where(
      (document) {
        return isCompletedOrder(document.data());
      },
    ).toList();

    double totalRevenue = 0.0;
    double totalQuantity = 0.0;

    final productSales = <String, ProductSalesSummary>{};
    final dailySalesMap = <String, DailySalesPoint>{};

    for (final document in completedOrders) {
      final data = document.data();

      final productName = OrderHelpers.getStringValue(
        data,
        'productName',
        'Fish Product',
      );

      final emoji = OrderHelpers.getStringValue(
        data,
        'productEmoji',
        '🐟',
      );

      final quantity = OrderHelpers.getDoubleValue(
        data,
        'quantity',
      );

      final totalAmount = OrderHelpers.getDoubleValue(
        data,
        'totalAmount',
      );

      totalRevenue += totalAmount;
      totalQuantity += quantity;

      final currentProduct = productSales[productName];

      productSales[productName] = ProductSalesSummary(
        productName: productName,
        emoji: emoji,
        quantity: (currentProduct?.quantity ?? 0.0) + quantity,
        revenue: (currentProduct?.revenue ?? 0.0) + totalAmount,
      );

      final date = dateFromOrderData(data);
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final currentDailyPoint = dailySalesMap[dateKey];

      dailySalesMap[dateKey] = DailySalesPoint(
        date: DateTime(
          date.year,
          date.month,
          date.day,
        ),
        quantity: (currentDailyPoint?.quantity ?? 0.0) + quantity,
        revenue: (currentDailyPoint?.revenue ?? 0.0) + totalAmount,
      );
    }

    final dailySales = dailySalesMap.values.toList()
      ..sort(
        (a, b) => a.date.compareTo(b.date),
      );

    final dailyQuantities = dailySales.map(
      (point) {
        return point.quantity;
      },
    ).toList();

    final topProducts = productSales.values.toList()
      ..sort(
        (a, b) => b.quantity.compareTo(a.quantity),
      );

    final stockAlerts = stockDocuments
        .where(
          (document) {
            final data = document.data();

            final status = OrderHelpers.getStringValue(
              data,
              'status',
              'available',
            ).toLowerCase();

            final quantity = OrderHelpers.getDoubleValue(
              data,
              'quantity',
            );

            final lowStockLevel = OrderHelpers.getDoubleValue(
              data,
              'lowStockLevel',
            );

            return status != 'unavailable' && quantity <= lowStockLevel;
          },
        )
        .map(
          (document) {
            final data = document.data();

            return StockAlertSummary(
              productName: OrderHelpers.getStringValue(
                data,
                'productName',
                'Fish Product',
              ),
              supplierName: OrderHelpers.getStringValue(
                data,
                'supplierName',
                'Supplier',
              ),
              emoji: OrderHelpers.getStringValue(
                data,
                'emoji',
                '🐟',
              ),
              quantity: OrderHelpers.getDoubleValue(
                data,
                'quantity',
              ),
              quantityUnit: OrderHelpers.getStringValue(
                data,
                'quantityUnit',
                'kilo',
              ),
              lowStockLevel: OrderHelpers.getDoubleValue(
                data,
                'lowStockLevel',
              ),
            );
          },
        )
        .toList();

    final simpleForecast = simpleMovingAverage(dailyQuantities);
    final seasonalForecast = seasonalMovingAverage(dailySales);
    final evaluation = evaluateSimpleMovingAverage(dailyQuantities);

    return AnalyticsData(
      completedOrders: completedOrders.length,
      totalQuantity: totalQuantity,
      totalRevenue: totalRevenue,
      topProducts: topProducts,
      stockAlerts: stockAlerts,
      dailySales: dailySales,
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
      evaluation: evaluation,
    );
  }
}
