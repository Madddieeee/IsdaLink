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

  bool isCompletedStatus(
    String status,
  ) {
    final value = status.toLowerCase();
    return value == 'completed' || value == 'delivered';
  }

  bool isStoppedStatus(
    String status,
  ) {
    final value = status.toLowerCase();
    return value == 'cancelled' ||
        value == 'rejected' ||
        value == 'returned' ||
        value == 'refunded';
  }

  String displayStatus(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Confirmation';
      case 'accepted':
        return 'Accepted';
      case 'delivered':
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'returned':
        return 'Returned';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  Color statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF7A1A);
      case 'accepted':
        return const Color(0xFF0A73D8);
      case 'delivered':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
      case 'rejected':
      case 'returned':
      case 'refunded':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF7B8FA3);
    }
  }

  IconData statusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'delivered':
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
      case 'rejected':
      case 'returned':
      case 'refunded':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String statusMessage(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Waiting for the supplier to accept your order.';
      case 'accepted':
        return 'The supplier confirmed your order.';
      case 'delivered':
      case 'completed':
        return 'The order was received and the transaction was completed.';
      case 'cancelled':
        return 'This order was cancelled.';
      case 'rejected':
        return 'The supplier rejected this order.';
      case 'returned':
        return 'This order was marked as returned.';
      case 'refunded':
        return 'This order was marked as refunded.';
      default:
        return 'Track the latest status of this order.';
    }
  }

  String getString(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    return OrderHelpers.getStringValue(
      data,
      key,
      fallback,
    );
  }

  String productImageUrl(
    Map<String, dynamic> data,
  ) {
    const keys = [
      'productImageUrl',
      'imageUrl',
      'fishImageUrl',
      'photoUrl',
    ];

    for (final key in keys) {
      final value = getString(
        data,
        key,
        '',
      );

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  bool hasNetworkImage(
    String value,
  ) {
    return value.startsWith('http://') ||
        value.startsWith('https://');
  }

  String formattedOrderDate(
    Map<String, dynamic> data,
  ) {
    final value = data['createdAt'];

    if (value is! Timestamp) {
      return 'Placed recently';
    }

    final date = value.toDate().toLocal();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return 'Placed ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String paymentDisplay(
    String paymentStatus,
    String orderStatus,
  ) {
    final payment = paymentStatus.toLowerCase();

    if (payment == 'paid') {
      return 'Paid';
    }

    if (isStoppedStatus(orderStatus) ||
        payment == 'cancelled' ||
        payment == 'refunded') {
      return displayStatus(orderStatus);
    }

    return 'Unpaid';
  }

  int progressIndex(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 1;
      case 'completed':
      case 'delivered':
        return 2;
      case 'pending':
      default:
        return 0;
    }
  }

  Widget statusChip(
    String status,
  ) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon(status),
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            displayStatus(status),
            style: TextStyle(
              color: color,
              fontSize: 9.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget productImage({
    required String imageUrl,
    required String emoji,
  }) {
    final fallback = Container(
      color: const Color(0xFFE8F8FD),
      alignment: Alignment.center,
      child: Text(
        emoji.trim().isEmpty ? '🐟' : emoji,
        style: const TextStyle(
          fontSize: 31,
        ),
      ),
    );

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDEBF3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: hasNetworkImage(imageUrl)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }

  Widget infoCell({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF102C44),
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FAFD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 9.7,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentRow({
    required String paymentStatus,
    required String orderStatus,
  }) {
    final paymentText = paymentDisplay(
      paymentStatus,
      orderStatus,
    );

    final paymentColor = paymentText == 'Paid'
        ? const Color(0xFF2E7D32)
        : paymentText == 'Unpaid'
            ? const Color(0xFFFF7A1A)
            : const Color(0xFFD32F2F);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE3EDF3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Color(0xFF0A73D8),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Payment is collected when the order is received.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9.2,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: paymentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              paymentText,
              style: TextStyle(
                color: paymentColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget progressStep({
    required String label,
    required IconData icon,
    required bool reached,
    required bool current,
  }) {
    final color = reached
        ? const Color(0xFF0A73D8)
        : const Color(0xFFB8C8D4);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: reached
                  ? color
                  : const Color(0xFFEAF1F5),
              shape: BoxShape.circle,
              boxShadow: current
                  ? const [
                      BoxShadow(
                        color: Color(0x330A73D8),
                        blurRadius: 9,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: reached
                  ? Colors.white
                  : const Color(0xFF9DAFBC),
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: reached
                  ? const Color(0xFF0A73D8)
                  : const Color(0xFF9DAFBC),
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget progressLine({
    required bool reached,
  }) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: reached
              ? const Color(0xFF72B8F1)
              : const Color(0xFFD6E2EA),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget progressCard(
    String status,
  ) {
    final stopped = isStoppedStatus(status);
    final color = statusColor(status);

    if (stopped) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: color.withAlpha(35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              statusIcon(status),
              color: color,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                statusMessage(status),
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final index = progressIndex(status);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        13,
        14,
        13,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDEBF3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              progressStep(
                label: 'Pending',
                icon: Icons.schedule_rounded,
                reached: index >= 0,
                current: index == 0,
              ),
              progressLine(
                reached: index >= 1,
              ),
              progressStep(
                label: 'Accepted',
                icon: Icons.check_rounded,
                reached: index >= 1,
                current: index == 1,
              ),
              progressLine(
                reached: index >= 2,
              ),
              progressStep(
                label: 'Completed',
                icon: Icons.task_alt_rounded,
                reached: index >= 2,
                current: index == 2,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              statusMessage(status),
              style: const TextStyle(
                color: Color(0xFF62798B),
                fontSize: 10.3,
                height: 1.35,
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
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: Color(0xFF2E7D32),
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'Review Submitted',
            style: TextStyle(
              color: Color(0xFF2E7D32),
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

    final productName = getString(
      data,
      'productName',
      'Fish Product',
    );

    final supplierName = getString(
      data,
      'supplierName',
      'Supplier',
    );

    final emoji = getString(
      data,
      'productEmoji',
      '🐟',
    );

    final imageUrl = productImageUrl(data);

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );

    final quantityUnit = getString(
      data,
      'quantityUnit',
      'kilo',
    );

    final totalAmount = OrderHelpers.getDoubleValue(
      data,
      'totalAmount',
    );

    final paymentStatus = getString(
      data,
      'paymentStatus',
      'To be paid on delivery',
    );

    final orderStatus = getString(
      data,
      'orderStatus',
      'Pending',
    );

    final reviewSubmitted = data['reviewSubmitted'] == true;
    final color = statusColor(orderStatus);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE1ECF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1000152A),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              15,
              14,
              15,
              14,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(23),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    statusIcon(orderStatus),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId,
                        style: const TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formattedOrderDate(data),
                        style: const TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 10.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                statusChip(orderStatus),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              15,
              15,
              15,
              17,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    productImage(
                      imageUrl: imageUrl,
                      emoji: emoji,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 17,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                color: Color(0xFF7B8FA3),
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  supplierName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF62798B),
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    infoCell(
                      label: 'Quantity',
                      value:
                          '${OrderHelpers.formatNumber(quantity)} $quantityUnit',
                    ),
                    const SizedBox(width: 9),
                    infoCell(
                      label: 'Total',
                      value: '₱${totalAmount.toStringAsFixed(0)}',
                      valueColor: const Color(0xFF0A73D8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                paymentRow(
                  paymentStatus: paymentStatus,
                  orderStatus: orderStatus,
                ),
                const SizedBox(height: 12),
                progressCard(orderStatus),
                if (orderStatus.toLowerCase() == 'pending') ...[
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    height: 43,
                    child: OutlinedButton.icon(
                      onPressed: onCancelPendingOrder,
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 17,
                      ),
                      label: const Text(
                        'Cancel Order',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(
                          color: Color(0xFFD32F2F),
                          width: 1.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
                if (isCompletedStatus(orderStatus)) ...[
                  const SizedBox(height: 13),
                  if (reviewSubmitted)
                    reviewSubmittedChip()
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: ElevatedButton.icon(
                        onPressed: onReviewOrder,
                        icon: const Icon(
                          Icons.star_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Rate Supplier',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB703),
                          foregroundColor: const Color(0xFF102C44),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
