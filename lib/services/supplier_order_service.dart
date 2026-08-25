import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_state.dart';

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
    required String orderId,
    required String status,
    required String productName,
    required String supplierName,
    double requestedQuantity = 0,
    double fulfilledQuantity = 0,
    String quantityUnit = '',
  }) {
    final orderCode = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    final reference = 'Order #$orderCode';

    switch (status.toLowerCase()) {
      case 'accepted':
        if (requestedQuantity > 0 &&
            fulfilledQuantity > 0 &&
            fulfilledQuantity < requestedQuantity) {
          return '$reference: $supplierName accepted ${OrderHelpers.formatNumber(fulfilledQuantity)} '
              'of ${OrderHelpers.formatNumber(requestedQuantity)} '
              '$quantityUnit for your $productName COD order. '
              'The unfulfilled quantity was returned to stock.';
        }

        return '$reference: Your $productName COD order was accepted by $supplierName.';
      case 'delivered':
      case 'completed':
        return '$reference: Your $productName order was delivered and its COD payment was recorded by $supplierName.';
      case 'cancelled':
        return '$reference: Your $productName order was cancelled by $supplierName. Any reserved stock was returned.';
      default:
        return '$reference: Your $productName order was updated by $supplierName.';
    }
  }

  void createNotificationInTransaction({
    required Transaction transaction,
    required Map<String, dynamic> orderData,
    required String orderId,
    required String newStatus,
    double? fulfilledQuantity,
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

    final requestedQuantity = OrderHelpers.getDoubleValue(
      orderData,
      'quantity',
    );
    final quantityUnit = OrderHelpers.getStringValue(
      orderData,
      'quantityUnit',
      'unit',
    );
    final acceptedQuantity =
        fulfilledQuantity ?? requestedQuantity;

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
          orderId: orderId,
          status: newStatus,
          productName: productName,
          supplierName: supplierName,
          requestedQuantity: requestedQuantity,
          fulfilledQuantity: acceptedQuantity,
          quantityUnit: quantityUnit,
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
    double? fulfilledQuantity,
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
            orderId: documentId,
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
          final normalizedNewStatus =
              newStatus.toLowerCase();
          final delivered =
              normalizedNewStatus == 'delivered';

          if (normalizedNewStatus == 'accepted') {
            final requestedQuantity =
                OrderHelpers.getDoubleValue(
              orderData,
              'quantity',
            );

            if (requestedQuantity <= 0) {
              throw StateError(
                'This order has an invalid requested quantity.',
              );
            }

            final acceptedQuantity =
                fulfilledQuantity ?? requestedQuantity;

            if (acceptedQuantity <= 0 ||
                acceptedQuantity > requestedQuantity) {
              throw StateError(
                'Fulfilled quantity must be between 1 and the requested quantity.',
              );
            }

            final unfulfilledQuantity =
                requestedQuantity - acceptedQuantity;
            final partialFulfillment =
                unfulfilledQuantity > 0;

            if (partialFulfillment) {
              await restoreUnfulfilledQuantity(
                transaction: transaction,
                orderData: orderData,
                orderId: documentId,
                quantityToRestore:
                    unfulfilledQuantity,
              );
            }

            final unitPrice =
                OrderHelpers.getDoubleValue(
              orderData,
              'unitPrice',
            );

            transaction.update(
              orderReference,
              {
                'orderStatus': 'Accepted',
                'paymentStatus':
                    'To be paid on delivery',
                'fulfilledQuantity':
                    acceptedQuantity,
                'unfulfilledQuantity':
                    unfulfilledQuantity,
                'fulfilledTotalAmount':
                    unitPrice * acceptedQuantity,
                'reservedQuantity':
                    acceptedQuantity,
                'partialFulfillment':
                    partialFulfillment,
                'fulfillmentStatus':
                    partialFulfillment
                        ? 'partial'
                        : 'full',
                'partialStockRestored':
                    partialFulfillment,
                'partialRestoredQuantity':
                    unfulfilledQuantity,
                if (partialFulfillment)
                  'partialRestoredAt':
                      FieldValue.serverTimestamp(),
                'acceptedAt':
                    FieldValue.serverTimestamp(),
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          } else {
            transaction.update(
              orderReference,
              {
                'orderStatus': newStatus,
                'paymentStatus': paymentStatus,
                'updatedAt':
                    FieldValue.serverTimestamp(),
                if (delivered)
                  'deliveredAt':
                      FieldValue.serverTimestamp(),
                if (delivered)
                  'completedAt':
                      FieldValue.serverTimestamp(),
                if (delivered)
                  'isReviewEligible': true,
              },
            );
          }
        }

        createNotificationInTransaction(
          transaction: transaction,
          orderData: orderData,
          orderId: documentId,
          newStatus: newStatus,
          fulfilledQuantity:
              newStatus.toLowerCase() == 'accepted'
                  ? fulfilledQuantity
                  : null,
        );
      },
    );
  }

  Future<void> restoreUnfulfilledQuantity({
    required Transaction transaction,
    required Map<String, dynamic> orderData,
    required String orderId,
    required double quantityToRestore,
  }) async {
    if (quantityToRestore <= 0) {
      return;
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

    if (stockId.isEmpty) {
      throw StateError(
        'The stock record for this order is unavailable.',
      );
    }

    final stockReference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(stockId);

    final stockSnapshot = await transaction.get(
      stockReference,
    );

    if (!stockSnapshot.exists) {
      throw StateError(
        'The stock record for this order no longer exists.',
      );
    }

    final stockData =
        stockSnapshot.data() ?? <String, dynamic>{};

    final restoredStock =
        StockState.quantity(stockData) + quantityToRestore;
    final hidden =
        StockState.isIntentionallyHidden(stockData);

    transaction.update(
      stockReference,
      {
        ...StockState.fieldsForQuantity(
          stockData,
          quantity: restoredStock,
        ),
        if (!hidden && restoredStock > 0) ...{
          'lastLowStockNotificationAt': null,
          'lastLowStockNotificationStatus': null,
        },
        'lastPartialFulfillmentOrderId':
            orderId,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<bool> restoreStockIfNeeded({
    required Transaction transaction,
    required Map<String, dynamic> orderData,
    required String orderId,
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
    final fulfilledQuantity =
        OrderHelpers.getDoubleValue(
      orderData,
      'fulfilledQuantity',
    );
    final currentStatus = OrderHelpers.getStringValue(
      orderData,
      'orderStatus',
      'Pending',
    ).toLowerCase();

    final quantityToRestore =
        currentStatus == 'accepted' &&
                fulfilledQuantity > 0
            ? fulfilledQuantity
            : orderedQuantity;

    if (stockId.isEmpty || quantityToRestore <= 0) {
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

    final restoredStock =
        StockState.quantity(stockData) + quantityToRestore;
    final hidden = StockState.isIntentionallyHidden(stockData);

    transaction.update(
      stockReference,
      {
        ...StockState.fieldsForQuantity(
          stockData,
          quantity: restoredStock,
        ),
        if (!hidden && restoredStock > 0) ...{
          'lastLowStockNotificationAt': null,
          'lastLowStockNotificationStatus': null,
        },
        // Links the stock restoration to the cancelled order so Rules can
        // validate the order and stock writes as one atomic operation.
        'lastStockRestoreOrderId': orderId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    return true;
  }
}
