import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_state.dart';

class StockNotificationTransition {
  const StockNotificationTransition({
    required this.previousStatus,
    required this.nextStatus,
    required this.shouldNotify,
    required this.shouldReset,
  });

  final String previousStatus;
  final String nextStatus;
  final bool shouldNotify;
  final bool shouldReset;

  Map<String, dynamic> markerFields() {
    if (shouldNotify) {
      return {
        'lastLowStockNotificationAt': FieldValue.serverTimestamp(),
        'lastLowStockNotificationStatus': nextStatus,
      };
    }

    if (shouldReset) {
      return {
        'lastLowStockNotificationAt': null,
        'lastLowStockNotificationStatus': null,
      };
    }

    return const <String, dynamic>{};
  }
}

class StockNotificationService {
  const StockNotificationService();

  bool notificationsEnabled(
    Map<String, dynamic> data,
  ) {
    return data['lowStockNotificationEnabled'] != false;
  }

  StockNotificationTransition transitionFor({
    required Map<String, dynamic> stockData,
    required double nextQuantity,
    double? lowStockLevelOverride,
    bool? hiddenOverride,
  }) {
    final previousStatus = StockState.calculatedStockStatus(
      stockData,
    );

    final nextStatus = StockState.calculatedStockStatus(
      stockData,
      quantityOverride: nextQuantity,
      lowStockLevelOverride: lowStockLevelOverride,
      hiddenOverride: hiddenOverride,
    );

    final lastNotifiedStatus = OrderHelpers.getStringValue(
      stockData,
      'lastLowStockNotificationStatus',
      '',
    );

    if (nextStatus == 'hidden' ||
        !notificationsEnabled(stockData)) {
      return StockNotificationTransition(
        previousStatus: previousStatus,
        nextStatus: nextStatus,
        shouldNotify: false,
        shouldReset: nextStatus == 'available',
      );
    }

    final shouldNotifyOutOfStock =
        nextStatus == 'outOfStock' &&
        previousStatus != 'outOfStock' &&
        lastNotifiedStatus != 'outOfStock';

    final shouldNotifyLowStock =
        nextStatus == 'lowStock' &&
        previousStatus == 'available' &&
        lastNotifiedStatus != 'lowStock';

    final recoveringFromOutOfStock =
        previousStatus == 'outOfStock' &&
        nextStatus == 'lowStock';

    return StockNotificationTransition(
      previousStatus: previousStatus,
      nextStatus: nextStatus,
      shouldNotify:
          shouldNotifyOutOfStock || shouldNotifyLowStock,
      shouldReset:
          nextStatus == 'available' ||
          recoveringFromOutOfStock,
    );
  }

  void createNotificationInTransaction({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> stockReference,
    required Map<String, dynamic> stockData,
    required double nextQuantity,
    required StockNotificationTransition transition,
    String supplierIdOverride = '',
    String productNameOverride = '',
    String quantityUnitOverride = '',
    double? lowStockLevelOverride,
    String sourceOrderId = '',
  }) {
    if (!transition.shouldNotify) {
      return;
    }

    final supplierId = supplierIdOverride.trim().isNotEmpty
        ? supplierIdOverride.trim()
        : OrderHelpers.getStringValue(
            stockData,
            'supplierId',
            '',
          );

    if (supplierId.isEmpty) {
      return;
    }

    final productName = productNameOverride.trim().isNotEmpty
        ? productNameOverride.trim()
        : OrderHelpers.getStringValue(
            stockData,
            'productName',
            'Fish Product',
          );

    final quantityUnit = quantityUnitOverride.trim().isNotEmpty
        ? quantityUnitOverride.trim()
        : OrderHelpers.getStringValue(
            stockData,
            'quantityUnit',
            'kilo',
          );

    final threshold = lowStockLevelOverride ??
        StockState.lowStockLevel(stockData);

    final outOfStock = transition.nextStatus == 'outOfStock';

    final notificationReference = FirebaseFirestore.instance
        .collection('notifications')
        .doc();

    transaction.set(
      notificationReference,
      {
        'supplierId': supplierId,
        'userId': supplierId,
        'stockId': stockReference.id,
        'productName': productName,
        'title': outOfStock
            ? '$productName Out of Stock'
            : 'Low Stock: $productName',
        'message': outOfStock
            ? '$productName is out of stock. Restock this listing to keep it available to vendors.'
            : '$productName has ${formatNumber(nextQuantity)} $quantityUnit remaining, reaching the ${formatNumber(threshold)} $quantityUnit alert level.',
        'stockStatus': transition.nextStatus,
        if (sourceOrderId.trim().isNotEmpty)
          'sourceOrderId': sourceOrderId.trim(),
        'type': 'stock_alert',
        'severity': outOfStock ? 'critical' : 'warning',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream(
    String supplierId,
  ) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'supplierId',
          isEqualTo: supplierId,
        )
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> unreadStockNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final notifications = documents.where(
      (document) {
        final data = document.data();
        final type = OrderHelpers.getStringValue(
          data,
          'type',
          '',
        ).toLowerCase();

        return type == 'stock_alert' &&
            data['isRead'] != true;
      },
    ).toList();

    notifications.sort(
      (a, b) => createdAtMillis(b).compareTo(
        createdAtMillis(a),
      ),
    );

    return notifications;
  }

  Future<void> markNotificationsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    if (notifications.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final notification in notifications) {
      batch.update(
        notification.reference,
        {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  int createdAtMillis(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final value = document.data()['createdAt'];

    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}
