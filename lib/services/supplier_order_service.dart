import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierOrderService {
  const SupplierOrderService();

  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream(
    String supplierId,
  ) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where(
          'supplierId',
          isEqualTo: supplierId,
        )
        .snapshots();
  }

  String notificationTitle(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Order Accepted';
      case 'delivered':
      case 'completed':
        return 'Order Delivered';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Updated';
    }
  }

  String notificationMessage({
    required String status,
    required String productName,
    required String supplierName,
  }) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Your COD order for $productName was accepted by $supplierName.';
      case 'delivered':
      case 'completed':
        return 'Your COD order for $productName was delivered and its COD payment was recorded by $supplierName.';
      case 'cancelled':
        return 'Your COD order for $productName was cancelled by $supplierName. Any reserved stock was returned.';
      default:
        return 'Your COD order for $productName was updated by $supplierName.';
    }
  }

  void createNotificationInTransaction({
    required Transaction transaction,
    required Map<String, dynamic> orderData,
    required String orderId,
    required String newStatus,
  }) {
    final vendorId = OrderHelpers.getStringValue(
      orderData,
      'vendorId',
      '',
    );

    if (vendorId.isEmpty) {
      return;
    }

    final productName = OrderHelpers.getStringValue(
      orderData,
      'productName',
      'Fish Product',
    );

    final supplierName = OrderHelpers.getStringValue(
      orderData,
      'supplierName',
      'Supplier',
    );

    final notificationReference = FirebaseFirestore.instance
        .collection('notifications')
        .doc();

    transaction.set(
      notificationReference,
      {
        'vendorId': vendorId,
        'userId': vendorId,
        'orderId': orderId,
        'title': notificationTitle(newStatus),
        'message': notificationMessage(
          status: newStatus,
          productName: productName,
          supplierName: supplierName,
        ),
        'status': newStatus,
        'type': 'order_status',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  bool isAllowedTransition({
    required String currentStatus,
    required String newStatus,
  }) {
    final current = currentStatus.toLowerCase();
    final next = newStatus.toLowerCase();

    if (current == next) {
      return true;
    }

    if (current == 'pending') {
      return next == 'accepted' || next == 'cancelled';
    }

    if (current == 'accepted') {
      return next == 'delivered' || next == 'cancelled';
    }

    return false;
  }

  Future<void> updateOrderStatus({
    required String documentId,
    required String newStatus,
    required String paymentStatus,
  }) async {
    final orderReference = FirebaseFirestore.instance
        .collection('orders')
        .doc(documentId);

    await FirebaseFirestore.instance.runTransaction(
      (
        transaction,
      ) async {
        final orderSnapshot = await transaction.get(
          orderReference,
        );

        if (!orderSnapshot.exists) {
          throw StateError(
            'This order is no longer available.',
          );
        }

        final orderData =
            orderSnapshot.data() ?? <String, dynamic>{};

        final currentStatus = OrderHelpers.getStringValue(
          orderData,
          'orderStatus',
          'Pending',
        );

        if (!isAllowedTransition(
          currentStatus: currentStatus,
          newStatus: newStatus,
        )) {
          throw StateError(
            'This order has already moved to another stage.',
          );
        }

        if (currentStatus.toLowerCase() ==
            newStatus.toLowerCase()) {
          return;
        }

        if (newStatus.toLowerCase() == 'cancelled') {
          final restorationProcessed =
              await restoreStockIfNeeded(
            transaction: transaction,
            orderData: orderData,
          );

          transaction.update(
            orderReference,
            {
              'orderStatus': 'Cancelled',
              'paymentStatus': 'Cancelled',
              'stockRestored': restorationProcessed,
              'stockRestorePending':
                  orderData['stockDeducted'] == true &&
                      !restorationProcessed,
              'cancelledBy': 'supplier',
              'cancelledAt': FieldValue.serverTimestamp(),
              'restoredAt': restorationProcessed
                  ? FieldValue.serverTimestamp()
                  : null,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          final delivered =
              newStatus.toLowerCase() == 'delivered';

          transaction.update(
            orderReference,
            {
              'orderStatus': newStatus,
              'paymentStatus': paymentStatus,
              'updatedAt': FieldValue.serverTimestamp(),
              if (newStatus.toLowerCase() == 'accepted')
                'acceptedAt': FieldValue.serverTimestamp(),
              if (delivered)
                'deliveredAt': FieldValue.serverTimestamp(),
              if (delivered)
                'completedAt': FieldValue.serverTimestamp(),
              if (delivered) 'isReviewEligible': true,
            },
          );
        }

        createNotificationInTransaction(
          transaction: transaction,
          orderData: orderData,
          orderId: documentId,
          newStatus: newStatus,
        );
      },
    );
  }

  Future<bool> restoreStockIfNeeded({
    required Transaction transaction,
    required Map<String, dynamic> orderData,
  }) async {
    final stockRestored =
        orderData['stockRestored'] == true;
    final stockDeducted =
        orderData['stockDeducted'] == true;

    if (stockRestored || !stockDeducted) {
      return true;
    }

    final stockId = OrderHelpers.getStringValue(
      orderData,
      'stockId',
      OrderHelpers.getStringValue(
        orderData,
        'fishStockId',
        '',
      ),
    );

    final orderedQuantity = OrderHelpers.getDoubleValue(
      orderData,
      'quantity',
    );

    if (stockId.isEmpty || orderedQuantity <= 0) {
      return false;
    }

    final stockReference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(stockId);

    final stockSnapshot = await transaction.get(
      stockReference,
    );

    if (!stockSnapshot.exists) {
      return false;
    }

    final stockData =
        stockSnapshot.data() ?? <String, dynamic>{};

    final currentStock = OrderHelpers.getDoubleValue(
      stockData,
      'quantity',
    );
    final lowStockLevel = OrderHelpers.getDoubleValue(
      stockData,
      'lowStockLevel',
    );

    final status = OrderHelpers.getStringValue(
      stockData,
      'status',
      'available',
    ).toLowerCase();

    final hidden = status == 'unavailable' ||
        stockData['isActive'] == false;

    final restoredStock =
        currentStock + orderedQuantity;

    final stockStatus = hidden
        ? 'hidden'
        : restoredStock <= 0
            ? 'outOfStock'
            : restoredStock <= lowStockLevel
                ? 'lowStock'
                : 'available';

    transaction.update(
      stockReference,
      {
        'quantity': restoredStock,
        'status': hidden ? 'unavailable' : 'available',
        'isActive': !hidden,
        'stockStatus': stockStatus,
        if (!hidden && restoredStock > lowStockLevel)
          'lastLowStockNotificationAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    return true;
  }
}
