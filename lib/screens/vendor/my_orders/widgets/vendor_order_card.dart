import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class VendorOrderCard extends StatelessWidget {
  const VendorOrderCard({
    super.key,
    required this.document,
    required this.onCancelPendingOrder,
    required this.onReviewOrder,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onCancelPendingOrder;
  final VoidCallback onReviewOrder;

  bool isCompletedOrder(
    String status,
  ) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'delivered' || lowerStatus == 'completed';
  }

  Color statusColor(
    String status,
  ) {
    final lowerStatus = status.toLowerCase();

    if (lowerStatus == 'completed') {
      return const Color(
        0xFF2E7D32,
      );
    }

    return OrderHelpers.statusColor(
      status,
    );
  }

  IconData statusIcon(
    String status,
  ) {
    final lowerStatus = status.toLowerCase();

    if (lowerStatus == 'completed') {
      return Icons.check_circle;
    }

    return OrderHelpers.statusIcon(
      status,
    );
  }

  String statusLabel(
    String status,
  ) {
    final lowerStatus = status.toLowerCase();

    if (lowerStatus == 'pending') {
      return 'To Pay';
    }

    if (lowerStatus == 'accepted') {
      return 'To Ship';
    }

    if (lowerStatus == 'delivered' || lowerStatus == 'completed') {
      return 'Delivered';
    }

    return status;
  }

  int timelineStepIndex({
    required String orderStatus,
    required bool reviewSubmitted,
  }) {
    final lowerStatus = orderStatus.toLowerCase();

    if (lowerStatus == 'cancelled') {
      return -1;
    }

    if (lowerStatus == 'pending') {
      return 0;
    }

    if (lowerStatus == 'accepted') {
      return 1;
    }

    if (lowerStatus == 'delivered' || lowerStatus == 'completed') {
      return reviewSubmitted ? 4 : 3;
    }

    return 0;
  }

  String timelineMessage({
    required String orderStatus,
    required bool reviewSubmitted,
  }) {
    final lowerStatus = orderStatus.toLowerCase();

    if (lowerStatus == 'cancelled') {
      return 'Order cancelled. The reserved stock was returned to supplier inventory.';
    }

    if (lowerStatus == 'pending') {
      return 'Waiting for supplier confirmation.';
    }

    if (lowerStatus == 'accepted') {
      return 'Supplier accepted your order and is preparing delivery.';
    }

    if ((lowerStatus == 'delivered' || lowerStatus == 'completed') &&
        !reviewSubmitted) {
      return 'Order delivered. You can now rate the supplier.';
    }

    if ((lowerStatus == 'delivered' || lowerStatus == 'completed') &&
        reviewSubmitted) {
      return 'Order completed and supplier review submitted.';
    }

    return 'Track this COD order from placement to rating.';
  }

  Widget statusChip(
    String status,
  ) {
    final color = statusColor(
      status,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(
          24,
        ),
        borderRadius: BorderRadius.circular(
          99,
        ),
        border: Border.all(
          color: color.withAlpha(
            60,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon(
              status,
            ),
            color: color,
            size: 13,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            statusLabel(
              status,
            ),
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentPill(
    String paymentMethod,
    String paymentStatus,
  ) {
    final bool isPaid = paymentStatus.toLowerCase() == 'paid';
    final color = isPaid
        ? const Color(
            0xFF2E7D32,
          )
        : const Color(
            0xFFFF7A1A,
          );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(
          22,
        ),
        borderRadius: BorderRadius.circular(
          99,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_outlined,
            color: color,
            size: 13,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            paymentMethod,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget infoBox({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFEAF8FC,
          ),
          borderRadius: BorderRadius.circular(
            16,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFF7B8FA3,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(
                  0xFF102C44,
                ),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget orderTimeline({
    required String orderStatus,
    required bool reviewSubmitted,
  }) {
    final step = timelineStepIndex(
      orderStatus: orderStatus,
      reviewSubmitted: reviewSubmitted,
    );

    if (step < 0) {
      return Container(
        padding: const EdgeInsets.all(
          12,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFFFEEF0,
          ),
          borderRadius: BorderRadius.circular(
            17,
          ),
          border: Border.all(
            color: const Color(
              0xFFD32F2F,
            ).withAlpha(
              40,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel_outlined,
              color: Color(
                0xFFD32F2F,
              ),
              size: 18,
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                timelineMessage(
                  orderStatus: orderStatus,
                  reviewSubmitted: reviewSubmitted,
                ),
                style: const TextStyle(
                  color: Color(
                    0xFF52677A,
                  ),
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        11,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF4FAFF,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFDDECF5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              MiniTimelineStep(
                label: 'To Pay',
                icon: Icons.payments_outlined,
                isDone: step > 0,
                isActive: step == 0,
              ),
              MiniTimelineConnector(
                isDone: step > 0,
              ),
              MiniTimelineStep(
                label: 'To Ship',
                icon: Icons.inventory_2_outlined,
                isDone: step > 1,
                isActive: step == 1,
              ),
              MiniTimelineConnector(
                isDone: step > 1,
              ),
              MiniTimelineStep(
                label: 'Receive',
                icon: Icons.local_shipping_outlined,
                isDone: step > 2,
                isActive: step == 2,
              ),
              MiniTimelineConnector(
                isDone: step > 2,
              ),
              MiniTimelineStep(
                label: reviewSubmitted ? 'Rated' : 'To Rate',
                icon: Icons.star_border,
                isDone: step >= 4,
                isActive: step == 3,
              ),
            ],
          ),
          const SizedBox(
            height: 9,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              timelineMessage(
                orderStatus: orderStatus,
                reviewSubmitted: reviewSubmitted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(
                  0xFF52677A,
                ),
                fontSize: 10.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget reviewSubmittedChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF2E7D32,
        ).withAlpha(
          24,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review,
            color: Color(
              0xFF2E7D32,
            ),
            size: 17,
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            'Review Submitted',
            style: TextStyle(
              color: Color(
                0xFF2E7D32,
              ),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final data = document.data();

    final orderId = document.id.length > 8
        ? 'ORD-${document.id.substring(0, 8).toUpperCase()}'
        : 'ORD-${document.id.toUpperCase()}';

    final productName = OrderHelpers.getStringValue(
      data,
      'productName',
      'Fish Product',
    );

    final productEmoji = OrderHelpers.getStringValue(
      data,
      'productEmoji',
      OrderHelpers.getStringValue(
        data,
        'emoji',
        '🐟',
      ),
    );

    final supplierName = OrderHelpers.getStringValue(
      data,
      'supplierName',
      'Verified Supplier',
    );

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );

    final quantityUnit = OrderHelpers.getStringValue(
      data,
      'quantityUnit',
      'kilo',
    );

    final totalAmount = OrderHelpers.getDoubleValue(
      data,
      'totalAmount',
    );

    final paymentMethod = OrderHelpers.getStringValue(
      data,
      'paymentMethod',
      'COD',
    );

    final paymentStatus = OrderHelpers.getStringValue(
      data,
      'paymentStatus',
      'To be paid on delivery',
    );

    final orderStatus = OrderHelpers.getStringValue(
      data,
      'orderStatus',
      'Pending',
    );

    final reviewSubmitted = data['reviewSubmitted'] == true;
    final createdDate = OrderHelpers.formatDateFromData(
      data,
    );
    final color = statusColor(
      orderStatus,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: const Color(
            0xFFE1EEF6,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0F000000,
            ),
            blurRadius: 13,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          24,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                14,
                13,
                14,
                13,
              ),
              decoration: BoxDecoration(
                color: color.withAlpha(
                  18,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: color.withAlpha(
                        28,
                      ),
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        productEmoji,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(
                              0xFF102C44,
                            ),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          createdDate,
                          style: const TextStyle(
                            color: Color(
                              0xFF7B8FA3,
                            ),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  statusChip(
                    orderStatus,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        size: 15,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          supplierName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(
                              0xFF7B8FA3,
                            ),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      paymentPill(
                        paymentMethod,
                        paymentStatus,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 13,
                  ),
                  Row(
                    children: [
                      infoBox(
                        label: 'Quantity',
                        value:
                            '${OrderHelpers.formatNumber(quantity)} $quantityUnit',
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      infoBox(
                        label: 'Total',
                        value: '₱${OrderHelpers.formatNumber(totalAmount)}',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 13,
                  ),
                  orderTimeline(
                    orderStatus: orderStatus,
                    reviewSubmitted: reviewSubmitted,
                  ),
                  if (orderStatus.toLowerCase() == 'pending') ...[
                    const SizedBox(
                      height: 13,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: onCancelPendingOrder,
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Cancel Pending Order',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(
                            0xFFD32F2F,
                          ),
                          side: const BorderSide(
                            color: Color(
                              0xFFD32F2F,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (isCompletedOrder(
                        orderStatus,
                      ) &&
                      !reviewSubmitted) ...[
                    const SizedBox(
                      height: 13,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onReviewOrder,
                        icon: const Icon(
                          Icons.star,
                          size: 18,
                        ),
                        label: const Text(
                          'Rate Supplier',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFFFB703,
                          ),
                          foregroundColor: const Color(
                            0xFF102C44,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (isCompletedOrder(
                        orderStatus,
                      ) &&
                      reviewSubmitted) ...[
                    const SizedBox(
                      height: 13,
                    ),
                    reviewSubmittedChip(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniTimelineStep extends StatelessWidget {
  const MiniTimelineStep({
    super.key,
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final bool isDone;
  final bool isActive;

  Color get color {
    if (isDone) {
      return const Color(
        0xFF2E7D32,
      );
    }

    if (isActive) {
      return const Color(
        0xFF146BFF,
      );
    }

    return const Color(
      0xFFB7C6D3,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class MiniTimelineConnector extends StatelessWidget {
  const MiniTimelineConnector({
    super.key,
    required this.isDone,
  });

  final bool isDone;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(
          bottom: 22,
        ),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(
                  0xFF2E7D32,
                )
              : const Color(
                  0xFFD8E3EC,
                ),
          borderRadius: BorderRadius.circular(
            99,
          ),
        ),
      ),
    );
  }
}
