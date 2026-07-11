import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierOrderService {
  const SupplierOrderService();

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  ordersStream(
    String supplierId,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'orders',
        )
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
        return 'Your COD order for $productName was marked as delivered by $supplierName.';
      case 'cancelled':
        return 'Your COD order for $productName was cancelled by $supplierName. The reserved stock was returned.';
      default:
        return 'Your COD order for $productName was updated by $supplierName.';
    }
  }

  void createNotificationInTransaction({
    required Transaction transaction,
    required Map<
      String,
      dynamic
    >
    orderData,
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
        .collection(
          'notifications',
        )
        .doc();

    transaction.set(
      notificationReference,
      {
        'vendorId': vendorId,
        'orderId': orderId,
        'title': notificationTitle(
          newStatus,
        ),
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

  Future<
    void
  >
  updateOrderStatus({
    required String documentId,
    required String newStatus,
    required String paymentStatus,
  }) async {
    final orderReference = FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .doc(
          documentId,
        );

    await FirebaseFirestore.instance.runTransaction(
      (
        transaction,
      ) async {
        final orderSnapshot = await transaction.get(
          orderReference,
        );

        if (!orderSnapshot.exists) {
          throw Exception(
            'This order no longer exists.',
          );
        }

        final orderData =
            orderSnapshot.data() ??
            <
              String,
              dynamic
            >{};

        final currentStatus = OrderHelpers.getStringValue(
          orderData,
          'orderStatus',
          'Pending',
        ).toLowerCase();

        if (currentStatus ==
            newStatus.toLowerCase()) {
          return;
        }

        if (newStatus.toLowerCase() ==
            'cancelled') {
          await restoreStockIfNeeded(
            transaction: transaction,
            orderData: orderData,
          );

          transaction.update(
            orderReference,
            {
              'orderStatus': newStatus,
              'paymentStatus': paymentStatus,
              'stockRestored': true,
              'cancelledBy': 'supplier',
              'restoredAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          transaction.update(
            orderReference,
            {
              'orderStatus': newStatus,
              'paymentStatus': paymentStatus,
              'updatedAt': FieldValue.serverTimestamp(),
              if (newStatus.toLowerCase() ==
                  'accepted')
                'acceptedAt': FieldValue.serverTimestamp(),
              if (newStatus.toLowerCase() ==
                  'delivered')
                'deliveredAt': FieldValue.serverTimestamp(),
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

  Future<
    void
  >
  restoreStockIfNeeded({
    required Transaction transaction,
    required Map<
      String,
      dynamic
    >
    orderData,
  }) async {
    final stockRestored =
        orderData['stockRestored'] ==
        true;
    final stockDeducted =
        orderData['stockDeducted'] ==
        true;

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

    if (stockRestored ||
        !stockDeducted ||
        stockId.isEmpty ||
        orderedQuantity <=
            0) {
      return;
    }

    final stockReference = FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .doc(
          stockId,
        );

    final stockSnapshot = await transaction.get(
      stockReference,
    );

    if (!stockSnapshot.exists) {
      return;
    }

    final stockData =
        stockSnapshot.data() ??
        <
          String,
          dynamic
        >{};

    final currentStock = OrderHelpers.getDoubleValue(
      stockData,
      'quantity',
    );

    final restoredStock =
        currentStock +
        orderedQuantity;

    transaction.update(
      stockReference,
      {
        'quantity': restoredStock,
        'status': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
