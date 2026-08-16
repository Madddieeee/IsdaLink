import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class VendorOrderCard extends StatefulWidget {
  const VendorOrderCard({
    super.key,
    required this.document,
    required this.onCancelPendingOrder,
    required this.onReviewOrder,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onCancelPendingOrder;
  final VoidCallback onReviewOrder;

  @override
  State<VendorOrderCard> createState() => _VendorOrderCardState();
}

class _VendorOrderCardState extends State<VendorOrderCard> {
  bool isExpanded = false;

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
      case 'completed':
      case 'delivered':
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
        return const Color(0xFF376EF6);
      case 'completed':
      case 'delivered':
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
      case 'completed':
      case 'delivered':
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
      case 'completed':
      case 'delivered':
        return 'Order received and transaction completed.';
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
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withAlpha(45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon(status),
            color: color,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            displayStatus(status),
            style: TextStyle(
              color: color,
              fontSize: 8.7,
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
          fontSize: 25,
        ),
      ),
    );

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FD),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDDEBF3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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

  Widget compactValue({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF102C44),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A9EAD),
            fontSize: 8.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 12.2,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget compactStatusBar(
    String orderStatus,
  ) {
    final color = statusColor(orderStatus);

    return Material(
      color: color.withAlpha(10),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () {
          setState(
            () {
              isExpanded = !isExpanded;
            },
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withAlpha(28),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(42),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon(orderStatus),
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  statusMessage(orderStatus),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isExpanded ? 'Hide' : 'Details',
                style: TextStyle(
                  color: color,
                  fontSize: 9.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedRotation(
                duration: const Duration(
                  milliseconds: 190,
                ),
                turns: isExpanded ? 0.5 : 0,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE3EDF3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Color(0xFF0875D1),
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pay when the order is received.',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: paymentColor.withAlpha(18),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              paymentText,
              style: TextStyle(
                color: paymentColor,
                fontSize: 8.9,
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
        ? const Color(0xFF0875D1)
        : const Color(0xFFB8C8D4);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: reached
                  ? color
                  : const Color(0xFFEAF1F5),
              shape: BoxShape.circle,
              boxShadow: current
                  ? const [
                      BoxShadow(
                        color: Color(0x330875D1),
                        blurRadius: 8,
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
              size: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: reached
                  ? const Color(0xFF0875D1)
                  : const Color(0xFF9DAFBC),
              fontSize: 8,
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
        height: 2,
        margin: const EdgeInsets.only(
          bottom: 17,
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

  Widget compactProgress(
    String status,
  ) {
    final color = statusColor(status);

    if (isStoppedStatus(status)) {
      return Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withAlpha(28),
          ),
        ),
        child: Row(
          children: [
            Icon(
              statusIcon(status),
              color: color,
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusMessage(status),
                style: TextStyle(
                  color: color,
                  fontSize: 9.8,
                  height: 1.3,
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
        10,
        11,
        10,
        9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F9FD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFDDEBF3),
        ),
      ),
      child: Row(
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
    );
  }

  Widget actionArea(
    String orderStatus,
    bool reviewSubmitted,
  ) {
    if (orderStatus.toLowerCase() == 'pending') {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: OutlinedButton.icon(
          onPressed: widget.onCancelPendingOrder,
          icon: const Icon(
            Icons.cancel_outlined,
            size: 15,
          ),
          label: const Text(
            'Cancel Order',
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD32F2F),
            backgroundColor:
                const Color(0xFFD32F2F).withAlpha(7),
            side: const BorderSide(
              color: Color(0x55D32F2F),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      );
    }

    if (isCompletedStatus(orderStatus)) {
      if (reviewSubmitted) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withAlpha(18),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rate_review_outlined,
                color: Color(0xFF2E7D32),
                size: 16,
              ),
              SizedBox(width: 7),
              Text(
                'Review Submitted',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 10.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton.icon(
          onPressed: widget.onReviewOrder,
          icon: const Icon(
            Icons.star_rounded,
            size: 17,
          ),
          label: const Text(
            'Rate Supplier',
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB703),
            foregroundColor: const Color(0xFF102C44),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final data = widget.document.data();

    final orderId = widget.document.id.length > 8
        ? 'ORD-${widget.document.id.substring(0, 8).toUpperCase()}'
        : 'ORD-${widget.document.id.toUpperCase()}';

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

    final requestedQuantity =
        OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );
    final storedFulfilledQuantity =
        OrderHelpers.getDoubleValue(
      data,
      'fulfilledQuantity',
    );
    final quantity =
        storedFulfilledQuantity > 0
            ? storedFulfilledQuantity
            : requestedQuantity;
    final partialFulfillment =
        data['partialFulfillment'] == true ||
            (storedFulfilledQuantity > 0 &&
                storedFulfilledQuantity <
                    requestedQuantity);

    final quantityUnit = getString(
      data,
      'quantityUnit',
      'kilo',
    );

    final originalTotalAmount =
        OrderHelpers.getDoubleValue(
      data,
      'totalAmount',
    );
    final fulfilledTotalAmount =
        OrderHelpers.getDoubleValue(
      data,
      'fulfilledTotalAmount',
    );
    final totalAmount =
        fulfilledTotalAmount > 0
            ? fulfilledTotalAmount
            : originalTotalAmount;

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
        bottom: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE1ECF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D00152A),
            blurRadius: 13,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                11,
                12,
                10,
              ),
              color: color.withAlpha(9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon(orderStatus),
                      color: color,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderId,
                          style: const TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 12.4,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formattedOrderDate(data),
                          style: const TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  statusChip(orderStatus),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                11,
                12,
                12,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      productImage(
                        imageUrl: imageUrl,
                        emoji: emoji,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 15.5,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  color: Color(0xFF7B8FA3),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    supplierName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF62798B),
                                      fontSize: 9.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          compactValue(
                            label: partialFulfillment
                                ? 'Fulfilled'
                                : 'Quantity',
                            value:
                                '${OrderHelpers.formatNumber(quantity)} $quantityUnit',
                          ),
                          const SizedBox(height: 8),
                          compactValue(
                            label: 'Total',
                            value:
                                '₱${totalAmount.toStringAsFixed(0)}',
                            valueColor: const Color(0xFF0875D1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (partialFulfillment) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6E9),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        '${OrderHelpers.formatNumber(quantity)} of '
                        '${OrderHelpers.formatNumber(requestedQuantity)} '
                        '$quantityUnit accepted. Your COD total was adjusted '
                        'to the fulfilled quantity.',
                        style: const TextStyle(
                          color: Color(0xFF8A5500),
                          fontSize: 8.9,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  compactStatusBar(orderStatus),
                  AnimatedSize(
                    duration: const Duration(
                      milliseconds: 230,
                    ),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: isExpanded
                        ? Column(
                            children: [
                              const SizedBox(height: 10),
                              paymentRow(
                                paymentStatus: paymentStatus,
                                orderStatus: orderStatus,
                              ),
                              const SizedBox(height: 9),
                              compactProgress(orderStatus),
                              if (orderStatus.toLowerCase() ==
                                      'pending' ||
                                  isCompletedStatus(orderStatus)) ...[
                                const SizedBox(height: 9),
                                actionArea(
                                  orderStatus,
                                  reviewSubmitted,
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
