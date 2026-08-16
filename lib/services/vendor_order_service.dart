import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_state.dart';

class VendorOrderService {
  const VendorOrderService();

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  ordersStream(
    String vendorId,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .where(
          'vendorId',
          isEqualTo: vendorId,
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
  notificationsStream(
    String vendorId,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'notifications',
        )
        .where(
          'vendorId',
          isEqualTo: vendorId,
        )
        .snapshots();
  }

  Future<
    void
  >
  markNotificationsRead(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    notifications,
  ) async {
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

  Future<void> cancelPendingOrder({
    required User user,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) async {
    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final orderSnapshot = await transaction.get(
          document.reference,
        );

        if (!orderSnapshot.exists) {
          throw Exception(
            'This order no longer exists.',
          );
        }

        final orderData =
            orderSnapshot.data() ?? <String, dynamic>{};

        final orderVendorId = OrderHelpers.getStringValue(
          orderData,
          'vendorId',
          '',
        );

        if (orderVendorId != user.uid) {
          throw Exception(
            'You can only cancel your own order.',
          );
        }

        final latestStatus = OrderHelpers.getStringValue(
          orderData,
          'orderStatus',
          'Pending',
        );

        if (latestStatus.toLowerCase() != 'pending') {
          throw Exception(
            'This order is no longer pending and cannot be cancelled.',
          );
        }

        final restorationProcessed = await restoreStockIfNeeded(
          transaction: transaction,
          orderData: orderData,
          orderId: document.id,
        );

        final stockDeducted = orderData['stockDeducted'] == true;

        transaction.update(
          document.reference,
          {
            'orderStatus': 'Cancelled',
            'paymentStatus': 'Cancelled',
            'stockRestored': restorationProcessed,
            'stockRestorePending':
                stockDeducted && !restorationProcessed,
            'cancelledBy': 'vendor',
            'cancelledAt': FieldValue.serverTimestamp(),
            if (restorationProcessed)
              'restoredAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  Future<bool> restoreStockIfNeeded({
    required Transaction transaction,
    required Map<String, dynamic> orderData,
    required String orderId,
  }) async {
    final stockRestored = orderData['stockRestored'] == true;
    final stockDeducted = orderData['stockDeducted'] == true;

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

    final restoredStock =
        StockState.quantity(stockData) + orderedQuantity;

    transaction.update(
      stockReference,
      {
        ...StockState.fieldsForQuantity(
          stockData,
          quantity: restoredStock,
        ),
        if (!StockState.isIntentionallyHidden(stockData) &&
            restoredStock > 0) ...{
          'lastLowStockNotificationAt': null,
          'lastLowStockNotificationStatus': null,
        },
        // Security Rules use this marker to verify that the stock increase
        // belongs to this vendor cancellation transaction.
        'lastStockRestoreOrderId': orderId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    return true;
  }

}
