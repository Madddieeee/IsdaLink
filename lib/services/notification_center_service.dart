import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationCenterService {
  const NotificationCenterService();

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  bool hasSupplierAccess(Map<String, dynamic>? userData) {
    if (userData == null) {
      return false;
    }

    final role = (userData['role'] ?? 'vendor').toString().trim().toLowerCase();
    final supplierStatus = (userData['supplierStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return role == 'supplier' && supplierStatus == 'approved';
  }

  String categoryOf(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().trim().toLowerCase();

    if (type == 'stock_alert') {
      return 'stock';
    }

    if (type == 'new_order' || type == 'order_status') {
      return 'orders';
    }

    return 'account';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> visibleForAccess(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents, {
    required bool isSupplier,
  }) {
    if (isSupplier) {
      return documents.toList();
    }

    return documents
        .where((document) => categoryOf(document.data()) != 'stock')
        .toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedNotifications(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final result = documents.toList();
    result.sort(
      (a, b) => createdAtMillis(b.data()).compareTo(createdAtMillis(a.data())),
    );
    return result;
  }

  int unreadCount(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents
        .where((document) => document.data()['isRead'] != true)
        .length;
  }

  Future<void> markRead(
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    if (notification.data()['isRead'] == true) {
      return;
    }

    await notification.reference.update(<String, dynamic>{
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllRead(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    final unread = notifications
        .where((notification) => notification.data()['isRead'] != true)
        .toList();

    for (var start = 0; start < unread.length; start += 450) {
      final batch = FirebaseFirestore.instance.batch();

      for (final notification in unread.skip(start).take(450)) {
        batch.update(notification.reference, <String, dynamic>{
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }

  int createdAtMillis(Map<String, dynamic> data) {
    final value = data['createdAt'];

    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }
}
