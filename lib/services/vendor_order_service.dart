import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/utils/order_helpers.dart';

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

  Future<
    void
  >
  cancelPendingOrder({
    required User user,
    required QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  }) async {
    await FirebaseFirestore.instance.runTransaction(
      (
        transaction,
      ) async {
        final orderSnapshot = await transaction.get(
          document.reference,
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

        final orderVendorId = OrderHelpers.getStringValue(
          orderData,
          'vendorId',
          '',
        );

        if (orderVendorId !=
            user.uid) {
          throw Exception(
            'You can only cancel your own order.',
          );
        }

        final latestStatus = OrderHelpers.getStringValue(
          orderData,
          'orderStatus',
          'Pending',
        );

        if (latestStatus.toLowerCase() !=
            'pending') {
          throw Exception(
            'This order is no longer pending and cannot be cancelled.',
          );
        }

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

        if (!stockRestored &&
            stockDeducted &&
            stockId.isNotEmpty &&
            orderedQuantity >
                0) {
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

          if (stockSnapshot.exists) {
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

        transaction.update(
          document.reference,
          {
            'orderStatus': 'Cancelled',
            'paymentStatus': 'Cancelled',
            'stockRestored': true,
            'cancelledBy': 'vendor',
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }
}
