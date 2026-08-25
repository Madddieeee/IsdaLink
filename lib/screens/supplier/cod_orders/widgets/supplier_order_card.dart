import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/map/caraga_location_picker_screen.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierOrderCard extends StatelessWidget {
  const SupplierOrderCard({
    super.key,
    required this.document,
    required this.expanded,
    required this.isBusy,
    required this.onToggle,
    required this.onAccept,
    required this.onCancel,
    required this.onMarkDelivered,
    this.highlighted = false,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final bool expanded;
  final bool isBusy;
  final VoidCallback onToggle;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onMarkDelivered;
  final bool highlighted;

  String firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  double firstDouble(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final parsed = double.tryParse(value.trim());

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 0;
  }

  String normalizedStatus(
    String status,
  ) {
    final normalized = status.toLowerCase();

    if (normalized == 'completed') {
      return 'delivered';
    }

    return normalized;
  }

  String displayStatus(
    String status,
  ) {
    final normalized = normalizedStatus(status);

    switch (normalized) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color statusColor(
    String status,
  ) {
    final normalized = normalizedStatus(status);

    switch (normalized) {
      case 'pending':
        return const Color(0xFFFF8A24);
      case 'accepted':
        return const Color(0xFF146BFF);
      case 'delivered':
        return const Color(0xFF147D64);
      case 'cancelled':
        return const Color(0xFFD94A45);
      default:
        return const Color(0xFF7B8FA3);
    }
  }

  IconData statusIcon(
    String status,
  ) {
    final normalized = normalizedStatus(status);

    switch (normalized) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'accepted':
        return Icons.inventory_2_outlined;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String orderReference() {
    final data = document.data();
    final provided = firstString(
      data,
      const [
        'orderNumber',
        'referenceNumber',
      ],
      fallback: '',
    );

    if (provided.isNotEmpty) {
      return provided;
    }

    final shortId = document.id.length > 8
        ? document.id.substring(0, 8).toUpperCase()
        : document.id.toUpperCase();

    return '#$shortId';
  }

  Widget productImage(
    String imageUrl,
  ) {
    final placeholder = Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE4F5FC),
            Color(0xFFCDEAF6),
          ],
        ),
      ),
      child: const Icon(
        Icons.set_meal_outlined,
        color: Color(0xFF146BFF),
        size: 30,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: imageUrl.isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return placeholder;
              },
            ),
    );
  }

  Widget statusChip(
    String status,
  ) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withAlpha(55),
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
          const SizedBox(width: 4),
          Text(
            displayStatus(status),
            style: TextStyle(
              color: color,
              fontSize: 8.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget metric({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF102C44),
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          8,
          9,
          8,
          9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF146BFF),
              size: 17,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8BA0B1),
                fontSize: 7.2,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: valueColor,
                fontSize: 9.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF146BFF),
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 9.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 9.8,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openDeliveryPin({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String vendorName,
    required String deliveryAddress,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            CaragaLocationPickerScreen(
          title: 'Delivery Reference Pin',
          subtitle:
              '$vendorName · $deliveryAddress',
          initialLatitude: latitude,
          initialLongitude: longitude,
          instructionText:
              'This is the vendor-selected COD delivery reference point. '
              'It is a location reference only and does not calculate routes.',
          markerTitle:
              'COD delivery reference point',
          readOnly: true,
        ),
      ),
    );
  }

  Widget progressStage({
    required IconData icon,
    required String label,
    required bool active,
    required bool complete,
  }) {
    final color = complete
        ? const Color(0xFF147D64)
        : active
            ? const Color(0xFF146BFF)
            : const Color(0xFFB1C1CC);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(
                complete || active ? 22 : 14,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withAlpha(70),
              ),
            ),
            child: Icon(
              complete
                  ? Icons.check_rounded
                  : icon,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 8.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool primary,
    Color? color,
  }) {
    if (primary) {
      return Expanded(
        child: SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 18,
            ),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  color ?? const Color(0xFF146BFF),
              disabledBackgroundColor:
                  const Color(0xFFDCE7EF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 18,
          ),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                color ?? const Color(0xFFD94A45),
            side: BorderSide(
              color: (color ?? const Color(0xFFD94A45))
                  .withAlpha(105),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final data = document.data();

    final productName = firstString(
      data,
      const [
        'productName',
        'fishName',
      ],
      fallback: 'Fish Product',
    );
    final imageUrl = firstString(
      data,
      const [
        'productImageUrl',
        'imageUrl',
        'fishImageUrl',
      ],
      fallback: '',
    );
    final vendorName = firstString(
      data,
      const [
        'vendorName',
        'buyerName',
        'customerName',
      ],
      fallback: 'Registered Vendor',
    );
    final vendorPhone = firstString(
      data,
      const [
        'vendorPhone',
        'vendorContactNumber',
        'contactNumber',
        'phone',
      ],
      fallback: 'Not provided',
    );
    final vendorLocation = firstString(
      data,
      const [
        'vendorLocation',
        'deliveryAddress',
        'location',
      ],
      fallback: 'Caraga Region',
    );
    final deliveryLatitude = firstDouble(
      data,
      const ['deliveryLatitude'],
    );
    final deliveryLongitude = firstDouble(
      data,
      const ['deliveryLongitude'],
    );
    final hasDeliveryPin =
        deliveryLatitude != 0 &&
        deliveryLongitude != 0;
    final requestedQuantity = firstDouble(
      data,
      const [
        'quantity',
      ],
    );
    final fulfilledQuantity = firstDouble(
      data,
      const [
        'fulfilledQuantity',
        'quantity',
      ],
    );
    final unfulfilledQuantity = firstDouble(
      data,
      const [
        'unfulfilledQuantity',
      ],
    );
    final partialFulfillment =
        data['partialFulfillment'] == true ||
            (fulfilledQuantity > 0 &&
                requestedQuantity > fulfilledQuantity);
    final quantity = fulfilledQuantity;
    final quantityUnit = firstString(
      data,
      const [
        'quantityUnit',
        'unit',
      ],
      fallback: 'kilo',
    );
    final totalAmount = firstDouble(
      data,
      const [
        'fulfilledTotalAmount',
        'totalAmount',
        'grandTotal',
      ],
    );
    final paymentMethod = firstString(
      data,
      const [
        'paymentMethod',
      ],
      fallback: 'COD',
    );
    final paymentStatus = firstString(
      data,
      const [
        'paymentStatus',
      ],
      fallback: 'To be paid on delivery',
    );
    final rawStatus = firstString(
      data,
      const [
        'orderStatus',
        'status',
      ],
      fallback: 'Pending',
    );
    final status = normalizedStatus(rawStatus);
    final color = statusColor(status);

    final pending = status == 'pending';
    final accepted = status == 'accepted';
    final delivered = status == 'delivered';
    final cancelled = status == 'cancelled';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isBusy ? 0.62 : 1,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: highlighted
                ? const Color(0xFF146BFF)
                : const Color(0xFFE1EBF2),
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: highlighted
              ? const [
                  BoxShadow(
                    color: Color(0x2B146BFF),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0F00152A),
                    blurRadius: 18,
                    offset: Offset(0, 9),
                  ),
                ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: productImage(imageUrl),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF102C44),
                                  fontSize: 14.5,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            statusChip(status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ordered by $vendorName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF52677A),
                            fontSize: 10.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                OrderHelpers.formatDateFromData(
                                  data,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8BA0B1),
                                  fontSize: 9.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              orderReference(),
                              style: const TextStyle(
                                color: Color(0xFF146BFF),
                                fontSize: 8.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: const Color(0xFFE8EFF4),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                12,
                14,
                13,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      metric(
                        icon: Icons.scale_outlined,
                        label: 'QUANTITY',
                        value:
                            '${OrderHelpers.formatNumber(quantity)} $quantityUnit',
                      ),
                      const SizedBox(width: 8),
                      metric(
                        icon: Icons.payments_outlined,
                        label: 'ORDER TOTAL',
                        value:
                            '₱${OrderHelpers.formatNumber(totalAmount)}',
                        valueColor:
                            const Color(0xFF0875D1),
                      ),
                      const SizedBox(width: 8),
                      metric(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'PAYMENT',
                        value: paymentMethod,
                      ),
                    ],
                  ),
                  if (partialFulfillment) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD9A6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.call_split_rounded,
                            color: Color(0xFFB86500),
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Partial fulfillment: '
                              '${OrderHelpers.formatNumber(fulfilledQuantity)} of '
                              '${OrderHelpers.formatNumber(requestedQuantity)} '
                              '$quantityUnit accepted. '
                              '${OrderHelpers.formatNumber(unfulfilledQuantity)} '
                              '$quantityUnit returned to stock.',
                              style: const TextStyle(
                                color: Color(0xFF8A5500),
                                fontSize: 9.1,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isBusy ? null : onToggle,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color.withAlpha(35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              delivered
                                  ? Icons.verified_rounded
                                  : cancelled
                                      ? Icons
                                          .assignment_return_outlined
                                      : Icons
                                          .info_outline_rounded,
                              color: color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                delivered
                                    ? 'COD payment recorded as paid upon delivery.'
                                    : cancelled
                                        ? 'Order cancelled. Reserved stock restoration was processed.'
                                        : paymentStatus,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9.6,
                                  height: 1.28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              expanded
                                  ? Icons
                                      .keyboard_arrow_up_rounded
                                  : Icons
                                      .keyboard_arrow_down_rounded,
                              color: const Color(0xFF52677A),
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 190),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              10,
                              12,
                              10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                detailRow(
                                  icon:
                                      Icons.person_outline_rounded,
                                  label: 'Vendor',
                                  value: vendorName,
                                ),
                                detailRow(
                                  icon:
                                      Icons.phone_outlined,
                                  label: 'Contact',
                                  value: vendorPhone,
                                ),
                                detailRow(
                                  icon:
                                      Icons.location_on_outlined,
                                  label: 'Location',
                                  value: vendorLocation,
                                ),
                                if (hasDeliveryPin) ...[
                                  const SizedBox(height: 7),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 41,
                                    child:
                                        OutlinedButton.icon(
                                      onPressed: () {
                                        openDeliveryPin(
                                          context: context,
                                          latitude:
                                              deliveryLatitude,
                                          longitude:
                                              deliveryLongitude,
                                          vendorName:
                                              vendorName,
                                          deliveryAddress:
                                              vendorLocation,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.map_outlined,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        'View Delivery Pin',
                                        style: TextStyle(
                                          fontSize: 9.8,
                                          fontWeight:
                                              FontWeight.w900,
                                        ),
                                      ),
                                      style: OutlinedButton
                                          .styleFrom(
                                        foregroundColor:
                                            const Color(
                                          0xFF146BFF,
                                        ),
                                        side:
                                            const BorderSide(
                                          color: Color(
                                            0xFF146BFF,
                                          ),
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              progressStage(
                                icon: Icons.schedule_rounded,
                                label: 'Pending',
                                active: pending,
                                complete: accepted ||
                                    delivered ||
                                    cancelled,
                              ),
                              Container(
                                width: 24,
                                height: 1,
                                color: accepted || delivered
                                    ? const Color(0xFF147D64)
                                    : const Color(0xFFD8E3EA),
                              ),
                              progressStage(
                                icon:
                                    Icons.inventory_2_outlined,
                                label: 'Accepted',
                                active: accepted,
                                complete: delivered,
                              ),
                              Container(
                                width: 24,
                                height: 1,
                                color: delivered
                                    ? const Color(0xFF147D64)
                                    : const Color(0xFFD8E3EA),
                              ),
                              progressStage(
                                icon:
                                    Icons.local_shipping_outlined,
                                label: 'Delivered',
                                active: delivered,
                                complete: delivered,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        actionButton(
                          label: 'Decline',
                          icon: Icons.close_rounded,
                          onPressed:
                              isBusy ? null : onCancel,
                          primary: false,
                        ),
                        const SizedBox(width: 9),
                        actionButton(
                          label: 'Accept Order',
                          icon: Icons.check_rounded,
                          onPressed:
                              isBusy ? null : onAccept,
                          primary: true,
                        ),
                      ],
                    ),
                  ] else if (accepted) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        actionButton(
                          label: 'Cancel',
                          icon: Icons.close_rounded,
                          onPressed:
                              isBusy ? null : onCancel,
                          primary: false,
                        ),
                        const SizedBox(width: 9),
                        actionButton(
                          label: 'Confirm Delivery',
                          icon: Icons.local_shipping_rounded,
                          onPressed: isBusy
                              ? null
                              : onMarkDelivered,
                          primary: true,
                          color: const Color(0xFF147D64),
                        ),
                      ],
                    ),
                  ],
                  if (isBusy) ...[
                    const SizedBox(height: 11),
                    const LinearProgressIndicator(
                      minHeight: 3,
                      borderRadius: BorderRadius.all(
                        Radius.circular(99),
                      ),
                      color: Color(0xFF146BFF),
                      backgroundColor: Color(0xFFEAF2F7),
                    ),
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
