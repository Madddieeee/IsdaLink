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

  Widget statusChip(
    String status,
  ) {
    final color = OrderHelpers.statusColor(
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
          18,
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
            OrderHelpers.statusIcon(
              status,
            ),
            color: color,
            size: 14,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentChip(
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
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(
          24,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Text(
        paymentStatus,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget reviewSubmittedChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
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
            size: 18,
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
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
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
      return 'This COD order was cancelled. Any reserved stock was returned to the supplier inventory.';
    }

    if (lowerStatus == 'pending') {
      return 'Your order was placed and is waiting for supplier confirmation.';
    }

    if (lowerStatus == 'accepted') {
      return 'The supplier accepted your order and is preparing it for delivery.';
    }

    if ((lowerStatus == 'delivered' || lowerStatus == 'completed') &&
        !reviewSubmitted) {
      return 'Your order was delivered. You can now rate and review the supplier.';
    }

    if ((lowerStatus == 'delivered' || lowerStatus == 'completed') &&
        reviewSubmitted) {
      return 'Your order was completed and your supplier review has been submitted.';
    }

    return 'Track this COD order from placement to supplier review.';
  }

  Widget trackingTimeline({
    required String orderStatus,
    required bool reviewSubmitted,
  }) {
    final lowerStatus = orderStatus.toLowerCase();
    final currentStep = timelineStepIndex(
      orderStatus: orderStatus,
      reviewSubmitted: reviewSubmitted,
    );

    if (lowerStatus == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          13,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFFFEEF0,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: const Color(
              0xFFD32F2F,
            ).withAlpha(
              50,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cancel_outlined,
              color: Color(
                0xFFD32F2F,
              ),
              size: 22,
            ),
            const SizedBox(
              width: 10,
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
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        14,
        13,
        13,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF4F8FB,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: const Color(
            0xFFE1ECF5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.route_outlined,
                color: Color(
                  0xFF146BFF,
                ),
                size: 18,
              ),
              SizedBox(
                width: 7,
              ),
              Text(
                'Order Tracking',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              TimelineStepItem(
                icon: Icons.payments_outlined,
                label: 'To Pay',
                isActive: currentStep == 0,
                isDone: currentStep > 0,
              ),
              TimelineConnector(
                isDone: currentStep > 0,
              ),
              TimelineStepItem(
                icon: Icons.inventory_2_outlined,
                label: 'To Ship',
                isActive: currentStep == 1,
                isDone: currentStep > 1,
              ),
              TimelineConnector(
                isDone: currentStep > 1,
              ),
              TimelineStepItem(
                icon: Icons.local_shipping_outlined,
                label: 'To Receive',
                isActive: currentStep == 2,
                isDone: currentStep > 2,
              ),
              TimelineConnector(
                isDone: currentStep > 2,
              ),
              TimelineStepItem(
                icon: Icons.star_border,
                label: reviewSubmitted ? 'Rated' : 'To Rate',
                isActive: currentStep == 3,
                isDone: currentStep >= 4,
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            timelineMessage(
              orderStatus: orderStatus,
              reviewSubmitted: reviewSubmitted,
            ),
            style: const TextStyle(
              color: Color(
                0xFF52677A,
              ),
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
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

    final supplierName = OrderHelpers.getStringValue(
      data,
      'supplierName',
      'Supplier',
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

    final color = OrderHelpers.statusColor(
      orderStatus,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(
                20,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(
                  24,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Icon(
                    OrderHelpers.statusIcon(
                      orderStatus,
                    ),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId,
                        style: const TextStyle(
                          color: Color(
                            0xFF102C44,
                          ),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        OrderHelpers.formatDateFromData(
                          data,
                        ),
                        style: const TextStyle(
                          color: Color(
                            0xFF7B8FA3,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
              16,
              16,
              16,
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront,
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      size: 16,
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 14,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(
                          12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEAF7FB,
                          ),
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                color: Color(
                                  0xFF7B8FA3,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '${OrderHelpers.formatNumber(quantity)} $quantityUnit',
                              textAlign: TextAlign.center,
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
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(
                          12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEAF7FB,
                          ),
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Color(
                                  0xFF7B8FA3,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '₱${totalAmount.toStringAsFixed(0)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(
                                  0xFF146BFF,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 14,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEAF7FB,
                        ),
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payments,
                            color: Color(
                              0xFF146BFF,
                            ),
                            size: 14,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            paymentMethod,
                            style: const TextStyle(
                              color: Color(
                                0xFF146BFF,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: paymentChip(
                          paymentStatus,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 14,
                ),
                trackingTimeline(
                  orderStatus: orderStatus,
                  reviewSubmitted: reviewSubmitted,
                ),
                if (orderStatus.toLowerCase() == 'pending') ...[
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: onCancelPendingOrder,
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Cancel Pending Order',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(
                          0xFFD32F2F,
                        ),
                        side: const BorderSide(
                          color: Color(
                            0xFFD32F2F,
                          ),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (isCompletedOrder(orderStatus)) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  if (reviewSubmitted)
                    reviewSubmittedChip()
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: onReviewOrder,
                        icon: const Icon(
                          Icons.star,
                          size: 18,
                        ),
                        label: const Text(
                          'Rate and Review Supplier',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
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
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class TimelineStepItem extends StatelessWidget {
  const TimelineStepItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDone;

  Color get stepColor {
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
          AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: stepColor,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: stepColor.withAlpha(
                          58,
                        ),
                        blurRadius: 10,
                        offset: const Offset(
                          0,
                          4,
                        ),
                      ),
                    ]
                  : const [],
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: stepColor,
              fontSize: 9.5,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineConnector extends StatelessWidget {
  const TimelineConnector({
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
          bottom: 27,
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
