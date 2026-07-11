import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/services/vendor_order_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class OrderNotificationPanel
    extends
        StatelessWidget {
  const OrderNotificationPanel({
    super.key,
    required this.vendorId,
    required this.service,
  });

  final String vendorId;
  final VendorOrderService service;

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<
      QuerySnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: service.notificationsStream(
        vendorId,
      ),
      builder:
          (
            context,
            snapshot,
          ) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final unreadNotifications = OrderHelpers.sortDocuments(
              snapshot.data!.docs.where(
                (
                  document,
                ) {
                  final data = document.data();
                  return data['isRead'] !=
                      true;
                },
              ).toList(),
            );

            if (unreadNotifications.isEmpty) {
              return const SizedBox.shrink();
            }

            final notificationsToShow = unreadNotifications
                .take(
                  3,
                )
                .toList();

            return Container(
              margin: const EdgeInsets.only(
                bottom: 16,
              ),
              padding: const EdgeInsets.all(
                14,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFFF7E8,
                ),
                borderRadius: BorderRadius.circular(
                  22,
                ),
                border: Border.all(
                  color:
                      const Color(
                        0xFFFFB703,
                      ).withAlpha(
                        80,
                      ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(
                          0xFFFF7A1A,
                        ),
                        size: 20,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Expanded(
                        child: Text(
                          'Order Updates',
                          style: TextStyle(
                            color: Color(
                              0xFF102C44,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => service.markNotificationsRead(
                          unreadNotifications,
                        ),
                        child: const Text(
                          'Mark read',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  ...notificationsToShow.map(
                    (
                      notification,
                    ) {
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

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                          top: 8,
                        ),
                        padding: const EdgeInsets.all(
                          12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            18,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              OrderHelpers.statusIcon(
                                status,
                              ),
                              color: OrderHelpers.statusColor(
                                status,
                              ),
                              size: 20,
                            ),
                            const SizedBox(
                              width: 8,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      color: Color(
                                        0xFF52677A,
                                      ),
                                      fontSize: 11,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
    );
  }
}
