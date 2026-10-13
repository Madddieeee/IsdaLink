import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/services/vendor_order_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class OrderNotificationPanel extends StatelessWidget {
  const OrderNotificationPanel({
    super.key,
    required this.vendorId,
    required this.service,
    required this.orders,
    required this.onNotificationTap,
    required this.onReviewOrder,
  });

  final String vendorId;
  final VendorOrderService service;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>>
  onNotificationTap;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onReviewOrder;

  bool needsReview(QueryDocumentSnapshot<Map<String, dynamic>> order) {
    final data = order.data();
    final status = OrderHelpers.getStringValue(
      data,
      'orderStatus',
      '',
    ).toLowerCase();
    return (status == 'delivered' || status == 'completed') &&
        data['reviewSubmitted'] != true;
  }

  String shortOrderId(String orderId) {
    final value = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    return value.toUpperCase();
  }

  Future<String> currentSupplierMessage(
    Map<String, dynamic> notification,
    String storedMessage,
  ) async {
    final orderId = OrderHelpers.getStringValue(notification, 'orderId', '');
    if (orderId.isEmpty) {
      return storedMessage;
    }

    try {
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final order = orderSnapshot.data() ?? <String, dynamic>{};
      final supplierId = OrderHelpers.getStringValue(order, 'supplierId', '');
      final storedSupplierName = OrderHelpers.getStringValue(
        order,
        'supplierName',
        '',
      );

      if (supplierId.isEmpty || storedSupplierName.isEmpty) {
        return storedMessage;
      }

      final profileSnapshot = await FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(supplierId)
          .get();
      final profile = profileSnapshot.data() ?? <String, dynamic>{};
      final currentSupplierName = OrderHelpers.getStringValue(
        profile,
        'supplierName',
        OrderHelpers.getStringValue(
          profile,
          'storeName',
          OrderHelpers.getStringValue(
            profile,
            'businessName',
            storedSupplierName,
          ),
        ),
      );

      if (currentSupplierName == storedSupplierName) {
        return storedMessage;
      }

      return storedMessage.replaceAll(storedSupplierName, currentSupplierName);
    } catch (_) {
      return storedMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.notificationsStream(vendorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final unreadNotifications = OrderHelpers.sortDocuments(
          snapshot.data!.docs.where((document) {
            final data = document.data();
            return data['isRead'] != true;
          }).toList(),
        );

        final unreadReviewOrderIds = unreadNotifications
            .where((notification) {
              final data = notification.data();
              return OrderHelpers.getStringValue(data, 'title', '') ==
                      'Review Your Order' &&
                  const {'delivered', 'completed'}.contains(
                    OrderHelpers.getStringValue(
                      data,
                      'status',
                      '',
                    ).toLowerCase(),
                  );
            })
            .map(
              (notification) => OrderHelpers.getStringValue(
                notification.data(),
                'orderId',
                '',
              ),
            )
            .where((orderId) => orderId.isNotEmpty)
            .toSet();

        final reviewReminders = OrderHelpers.sortDocuments(
          orders
              .where(
                (order) =>
                    needsReview(order) &&
                    !unreadReviewOrderIds.contains(order.id),
              )
              .toList(),
        ).take(2).toList();

        if (unreadNotifications.isEmpty && reviewReminders.isEmpty) {
          return const SizedBox.shrink();
        }

        final notificationLimit = 3 - reviewReminders.length;
        final notificationsToShow = unreadNotifications
            .take(notificationLimit > 0 ? notificationLimit : 0)
            .toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE9F1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF0875D1),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Order Updates',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (unreadNotifications.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          service.markNotificationsRead(unreadNotifications),
                      child: const Text(
                        'Mark as read',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ...reviewReminders.map((order) {
                final data = order.data();
                final productName = OrderHelpers.getStringValue(
                  data,
                  'productName',
                  'fish order',
                );

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Material(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => onReviewOrder(order),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.rate_review_rounded,
                              color: Color(0xFFE59A00),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Needs Review',
                                    style: TextStyle(
                                      color: Color(0xFF102C44),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Order #${shortOrderId(order.id)}: Rate your $productName order and share your experience.',
                                    style: const TextStyle(
                                      color: Color(0xFF52677A),
                                      fontSize: 11,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF87A0B4),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              ...notificationsToShow.map((notification) {
                final data = notification.data();

                final title = OrderHelpers.getStringValue(
                  data,
                  'title',
                  'Order Update',
                );

                final message = OrderHelpers.getStringValue(
                  data,
                  'message',
                  'Your order status has changed.',
                );

                final status = OrderHelpers.getStringValue(
                  data,
                  'status',
                  'Pending',
                );

                final needsReview =
                    (status.toLowerCase() == 'delivered' ||
                        status.toLowerCase() == 'completed') &&
                    title == 'Review Your Order';

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Material(
                    color: const Color(0xFFF4F8FB),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: needsReview
                          ? () => onNotificationTap(notification)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              needsReview
                                  ? Icons.rate_review_rounded
                                  : OrderHelpers.statusIcon(status),
                              color: needsReview
                                  ? const Color(0xFFE59A00)
                                  : OrderHelpers.statusColor(status),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xFF102C44),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  FutureBuilder<String>(
                                    future: currentSupplierMessage(
                                      data,
                                      message,
                                    ),
                                    initialData: message,
                                    builder: (context, messageSnapshot) => Text(
                                      messageSnapshot.data ?? message,
                                      style: const TextStyle(
                                        color: Color(0xFF52677A),
                                        fontSize: 11,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (needsReview) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF87A0B4),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
