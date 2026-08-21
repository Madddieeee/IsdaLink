import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierNotificationService {
  const SupplierNotificationService();

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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> unreadByType(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    String type,
  ) {
    final normalizedType = type.trim().toLowerCase();
    final notifications = documents.where(
      (document) {
        final data = document.data();
        final notificationType = OrderHelpers.getStringValue(
          data,
          'type',
          '',
        ).toLowerCase();

        return notificationType == normalizedType &&
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      unreadProfileChangeNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return unreadByType(
      documents,
      'supplier_profile_change',
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> unreadStockNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return unreadByType(
      documents,
      'stock_alert',
    );
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
}
