import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class AnalyticsScreen
    extends
        StatelessWidget {
  const AnalyticsScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<
    DocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  userProfileStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          uid,
        )
        .snapshots();
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  ordersStream({
    required String uid,
    required bool isSupplier,
  }) {
    final field = isSupplier
        ? 'supplierId'
        : 'vendorId';

    return FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .where(
          field,
          isEqualTo: uid,
        )
        .snapshots();
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  fishStocksStream({
    required String uid,
    required bool isSupplier,
  }) {
    if (isSupplier) {
      return FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .where(
            'supplierId',
            isEqualTo: uid,
          )
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .snapshots();
  }

  bool isCompletedOrder(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final status = OrderHelpers.getStringValue(
      data,
      'orderStatus',
      'Pending',
    ).toLowerCase();

    return status ==
            'delivered' ||
        status ==
            'completed';
  }

  double simpleMovingAverage(
    List<
      double
    >
    values, {
    int window = 3,
  }) {
    if (values.isEmpty) {
      return 0.0;
    }

    final usableWindow =
        values.length <
            window
        ? values.length
        : window;
    final recentValues = values.sublist(
      values.length -
          usableWindow,
    );

    final totalValue =
        recentValues.fold<
          double
        >(
          0.0,
          (
            runningTotal,
            value,
          ) =>
              runningTotal +
              value,
        );

    return totalValue /
        usableWindow;
  }

  double seasonalMovingAverage(
    List<
      DailySalesPoint
    >
    points,
  ) {
    if (points.isEmpty) {
      return 0.0;
    }

    final now = DateTime.now();
    final sameWeekday = points
        .where(
          (
            point,
          ) =>
              point.date.weekday ==
              now.weekday,
        )
        .map(
          (
            point,
          ) => point.quantity,
        )
        .toList();

    if (sameWeekday.isEmpty) {
      return simpleMovingAverage(
        points
            .map(
              (
                point,
              ) => point.quantity,
            )
            .toList(),
      );
    }

    final totalValue =
        sameWeekday.fold<
          double
        >(
          0.0,
          (
            runningTotal,
            value,
          ) =>
              runningTotal +
              value,
        );

    return totalValue /
        sameWeekday.length;
  }

  ForecastEvaluation evaluateSimpleMovingAverage(
    List<
      double
    >
    values, {
    int window = 3,
  }) {
    if (values.length <=
        window) {
      return const ForecastEvaluation(
        mape: 0.0,
        mae: 0.0,
        hasEnoughData: false,
      );
    }

    final absoluteErrors =
        <
          double
        >[];
    final percentageErrors =
        <
          double
        >[];

    for (
      var index = window;
      index <
          values.length;
      index++
    ) {
      final previousValues = values.sublist(
        index -
            window,
        index,
      );
      final forecast =
          previousValues.fold<
            double
          >(
            0.0,
            (
              runningTotal,
              value,
            ) =>
                runningTotal +
                value,
          ) /
          window;

      final actual = values[index];
      final error =
          (actual -
                  forecast)
              .abs();

      absoluteErrors.add(
        error,
      );

      if (actual >
          0) {
        percentageErrors.add(
          error /
              actual *
              100,
        );
      }
    }

    final mae =
        absoluteErrors.fold<
          double
        >(
          0.0,
          (
            runningTotal,
            value,
          ) =>
              runningTotal +
              value,
        ) /
        absoluteErrors.length;

    final mape = percentageErrors.isEmpty
        ? 0.0
        : percentageErrors.fold<
                double
              >(
                0.0,
                (
                  runningTotal,
                  value,
                ) =>
                    runningTotal +
                    value,
              ) /
              percentageErrors.length;

    return ForecastEvaluation(
      mape: mape,
      mae: mae,
      hasEnoughData: true,
    );
  }

  DateTime dateFromOrderData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final deliveredAt = data['deliveredAt'];
    final createdAt = data['createdAt'];

    if (deliveredAt
        is Timestamp) {
      return deliveredAt.toDate();
    }

    if (createdAt
        is Timestamp) {
      return createdAt.toDate();
    }

    return DateTime.now();
  }

  AnalyticsData buildAnalyticsData({
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    orderDocuments,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    stockDocuments,
  }) {
    final completedOrders = orderDocuments.where(
      (
        document,
      ) {
        return isCompletedOrder(
          document.data(),
        );
      },
    ).toList();

    double totalRevenue = 0.0;
    double totalQuantity = 0.0;

    final productSales =
        <
          String,
          ProductSalesSummary
        >{};
    final dailySalesMap =
        <
          String,
          DailySalesPoint
        >{};

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
        quantity:
            (currentProduct?.quantity ??
                0.0) +
            quantity,
        revenue:
            (currentProduct?.revenue ??
                0.0) +
            totalAmount,
      );

      final date = dateFromOrderData(
        data,
      );

      final dateKey = '${date.year}-${date.month}-${date.day}';
      final currentDailyPoint = dailySalesMap[dateKey];

      dailySalesMap[dateKey] = DailySalesPoint(
        date: DateTime(
          date.year,
          date.month,
          date.day,
        ),
        quantity:
            (currentDailyPoint?.quantity ??
                0.0) +
            quantity,
        revenue:
            (currentDailyPoint?.revenue ??
                0.0) +
            totalAmount,
      );
    }

    final dailySales = dailySalesMap.values.toList()
      ..sort(
        (
          a,
          b,
        ) => a.date.compareTo(
          b.date,
        ),
      );

    final dailyQuantities = dailySales.map(
      (
        point,
      ) {
        return point.quantity;
      },
    ).toList();

    final topProducts = productSales.values.toList()
      ..sort(
        (
          a,
          b,
        ) => b.quantity.compareTo(
          a.quantity,
        ),
      );

    final stockAlerts = stockDocuments
        .where(
          (
            document,
          ) {
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

            return status !=
                    'unavailable' &&
                quantity <=
                    lowStockLevel;
          },
        )
        .map(
          (
            document,
          ) {
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

    final simpleForecast = simpleMovingAverage(
      dailyQuantities,
    );

    final seasonalForecast = seasonalMovingAverage(
      dailySales,
    );

    final evaluation = evaluateSimpleMovingAverage(
      dailyQuantities,
    );

    return AnalyticsData(
      completedOrders: completedOrders.length,
      totalQuantity: totalQuantity,
      totalRevenue: totalRevenue,
      topProducts: topProducts,
      stockAlerts: stockAlerts,
      simpleForecast: simpleForecast,
      seasonalForecast: seasonalForecast,
      evaluation: evaluation,
    );
  }

  String formatNumber(
    double value,
  ) {
    if (value %
            1 ==
        0) {
      return value.toStringAsFixed(
        0,
      );
    }

    return value.toStringAsFixed(
      2,
    );
  }

  Widget statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 76,
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(
            38,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(
              36,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFFDCE9F5,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFF146BFF,
                      ).withAlpha(
                        24,
                      ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(
                    0xFF146BFF,
                  ),
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          child,
        ],
      ),
    );
  }

  Widget metricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(
            22,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: color.withAlpha(
              56,
            ),
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
            const SizedBox(
              height: 4,
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFF102C44,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(
                  0xFF7B8FA3,
                ),
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget forecastMethodCard({
    required String title,
    required String description,
    required String useCase,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF4F8FB,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFE1E9F0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(
                0xFF146BFF,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(
                      0xFF52677A,
                    ),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEAF7FB,
                    ),
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(
                    useCase,
                    style: const TextStyle(
                      color: Color(
                        0xFF146BFF,
                      ),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget stockAlertTile(
    StockAlertSummary alert,
  ) {
    final isOutOfStock =
        alert.quantity <=
        0;
    final color = isOutOfStock
        ? const Color(
            0xFFD32F2F,
          )
        : const Color(
            0xFFFF7A1A,
          );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF4F8FB,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(
                0xFFEAF7FB,
              ),
              borderRadius: BorderRadius.circular(
                17,
              ),
            ),
            child: Center(
              child: Text(
                alert.emoji,
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.productName,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  alert.supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  '${formatNumber(alert.quantity)} ${alert.quantityUnit} left',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(
                24,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: Text(
              isOutOfStock
                  ? 'Out of Stock'
                  : 'Low Stock',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget topProductTile({
    required int rank,
    required ProductSalesSummary product,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF4F8FB,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(
                0xFF146BFF,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            product.emoji,
            style: const TextStyle(
              fontSize: 26,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '${formatNumber(product.quantity)} total units sold',
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₱${product.revenue.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(
                0xFF146BFF,
              ),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingBody() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    );
  }

  Widget errorBody(
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          22,
        ),
        child: Text(
          'Unable to load analytics data: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(
              0xFFD32F2F,
            ),
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget analyticsContent({
    required BuildContext context,
    required AnalyticsData data,
    required bool isSupplier,
  }) {
    final analyticsLabel = isSupplier
        ? 'Supplier Analytics'
        : 'Vendor Analytics';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            54,
            20,
            24,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(
                  0xFF102C44,
                ),
                Color(
                  0xFF146BFF,
                ),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(
                32,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(
                      context,
                    ),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          38,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      analyticsLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                isSupplier
                    ? 'Firebase-based sales analytics from completed orders received by this supplier account.'
                    : 'Firebase-based purchase analytics from completed orders made by this vendor account.',
                style: const TextStyle(
                  color: Color(
                    0xFFDCE9F5,
                  ),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Row(
                children: [
                  statCard(
                    value: '${data.completedOrders}',
                    label: 'Completed',
                    icon: Icons.receipt_long,
                  ),
                  statCard(
                    value: formatNumber(
                      data.totalQuantity,
                    ),
                    label: 'Quantity',
                    icon: Icons.scale,
                  ),
                  statCard(
                    value: '₱${data.totalRevenue.toStringAsFixed(0)}',
                    label: 'Revenue',
                    icon: Icons.analytics,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              20,
            ),
            children: [
              sectionCard(
                title: 'Forecasting Methods',
                subtitle: 'These analytics are computed from completed Firebase order records.',
                icon: Icons.trending_up,
                child: Column(
                  children: [
                    forecastMethodCard(
                      title: 'Simple Moving Average',
                      description: 'Uses recent completed order quantities to estimate short-term demand.',
                      useCase: 'Current forecast: ${formatNumber(data.simpleForecast)} units',
                      icon: Icons.show_chart,
                    ),
                    forecastMethodCard(
                      title: 'Seasonal Moving Average',
                      description: 'Uses recurring weekday patterns when matching sales records are available.',
                      useCase: 'Current forecast: ${formatNumber(data.seasonalForecast)} units',
                      icon: Icons.calendar_month,
                    ),
                  ],
                ),
              ),
              sectionCard(
                title: 'Forecast Evaluation',
                subtitle: data.evaluation.hasEnoughData
                    ? 'MAPE and MAE are computed using simple moving average back-testing.'
                    : 'More completed daily sales records are needed to compute stable MAPE and MAE values.',
                icon: Icons.fact_check,
                child: Row(
                  children: [
                    metricTile(
                      label: 'MAPE',
                      value: data.evaluation.hasEnoughData
                          ? '${data.evaluation.mape.toStringAsFixed(2)}%'
                          : '--',
                      subtitle: 'Percentage error',
                      color: const Color(
                        0xFF146BFF,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    metricTile(
                      label: 'MAE',
                      value: data.evaluation.hasEnoughData
                          ? formatNumber(
                              data.evaluation.mae,
                            )
                          : '--',
                      subtitle: 'Average absolute error',
                      color: const Color(
                        0xFFFF7A1A,
                      ),
                    ),
                  ],
                ),
              ),
              sectionCard(
                title: 'Restocking Suggestions',
                subtitle: isSupplier
                    ? 'This shows low-stock products owned by this supplier account.'
                    : 'This shows low-stock products currently visible in Firebase.',
                icon: Icons.notification_important,
                child: data.stockAlerts.isEmpty
                    ? const Text(
                        'No low-stock or out-of-stock items found.',
                        style: TextStyle(
                          color: Color(
                            0xFF7B8FA3,
                          ),
                          fontSize: 13,
                        ),
                      )
                    : Column(
                        children: data.stockAlerts
                            .take(
                              5,
                            )
                            .map(
                              stockAlertTile,
                            )
                            .toList(),
                      ),
              ),
              sectionCard(
                title: 'Top Product Insights',
                subtitle: 'Ranking is based on completed Firebase order quantity.',
                icon: Icons.emoji_events,
                child: data.topProducts.isEmpty
                    ? const Text(
                        'No completed order records yet.',
                        style: TextStyle(
                          color: Color(
                            0xFF7B8FA3,
                          ),
                          fontSize: 13,
                        ),
                      )
                    : Column(
                        children: data.topProducts
                            .take(
                              5,
                            )
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (
                                entry,
                              ) => topProductTile(
                                rank:
                                    entry.key +
                                    1,
                                product: entry.value,
                              ),
                            )
                            .toList(),
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(
                  16,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF7FB,
                  ),
                  borderRadius: BorderRadius.circular(
                    22,
                  ),
                  border: Border.all(
                    color:
                        const Color(
                          0xFF146BFF,
                        ).withAlpha(
                          42,
                        ),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cloud_done,
                      color: Color(
                        0xFF146BFF,
                      ),
                      size: 22,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        'Firebase mode: Analytics use completed order records, visible stock records, Simple Moving Average, Seasonal Moving Average, MAPE, and MAE.',
                        style: TextStyle(
                          color: Color(
                            0xFF52677A,
                          ),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loggedOutBody() {
    return const Scaffold(
      backgroundColor: Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: Text(
          'Please log in first to view analytics.',
          style: TextStyle(
            color: Color(
              0xFFD32F2F,
            ),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user ==
        null) {
      return loggedOutBody();
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body:
          StreamBuilder<
            DocumentSnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: userProfileStream(
              user.uid,
            ),
            builder:
                (
                  context,
                  userSnapshot,
                ) {
                  if (userSnapshot.hasError) {
                    return errorBody(
                      userSnapshot.error!,
                    );
                  }

                  if (!userSnapshot.hasData) {
                    return loadingBody();
                  }

                  final userData =
                      userSnapshot.data!.data() ??
                      {};
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

                  final isSupplier =
                      role ==
                          'supplier' ||
                      supplierStatus ==
                          'approved';

                  return StreamBuilder<
                    QuerySnapshot<
                      Map<
                        String,
                        dynamic
                      >
                    >
                  >(
                    stream: ordersStream(
                      uid: user.uid,
                      isSupplier: isSupplier,
                    ),
                    builder:
                        (
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

                          return StreamBuilder<
                            QuerySnapshot<
                              Map<
                                String,
                                dynamic
                              >
                            >
                          >(
                            stream: fishStocksStream(
                              uid: user.uid,
                              isSupplier: isSupplier,
                            ),
                            builder:
                                (
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

                                  final analyticsData = buildAnalyticsData(
                                    orderDocuments: orderSnapshot.data!.docs,
                                    stockDocuments: stockSnapshot.data!.docs,
                                  );

                                  return analyticsContent(
                                    context: context,
                                    data: analyticsData,
                                    isSupplier: isSupplier,
                                  );
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
    required this.totalQuantity,
    required this.totalRevenue,
    required this.topProducts,
    required this.stockAlerts,
    required this.simpleForecast,
    required this.seasonalForecast,
    required this.evaluation,
  });

  final int completedOrders;
  final double totalQuantity;
  final double totalRevenue;
  final List<
    ProductSalesSummary
  >
  topProducts;
  final List<
    StockAlertSummary
  >
  stockAlerts;
  final double simpleForecast;
  final double seasonalForecast;
  final ForecastEvaluation evaluation;
}

class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productName,
    required this.emoji,
    required this.quantity,
    required this.revenue,
  });

  final String productName;
  final String emoji;
  final double quantity;
  final double revenue;
}

class StockAlertSummary {
  const StockAlertSummary({
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

class DailySalesPoint {
  const DailySalesPoint({
    required this.date,
    required this.quantity,
    required this.revenue,
  });

  final DateTime date;
  final double quantity;
  final double revenue;
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
