import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierOrderCard
    extends
        StatelessWidget {
  const SupplierOrderCard({
    super.key,
    required this.document,
    required this.onAccept,
    required this.onCancel,
    required this.onMarkDelivered,
  });

  final QueryDocumentSnapshot<
    Map<
      String,
      dynamic
    >
  >
  document;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onMarkDelivered;

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

  Widget orderActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: SizedBox(
        height: 40,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            icon,
            size: 16,
          ),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
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

    final vendorName = OrderHelpers.getStringValue(
      data,
      'vendorName',
      'Vendor',
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
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(
                            0xFF102C44,
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Ordered by $vendorName • ${OrderHelpers.formatDateFromData(data)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              children: [
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
                      child: Text(
                        paymentMethod,
                        style: const TextStyle(
                          color: Color(
                            0xFF146BFF,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
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
                  height: 12,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Payment: $paymentStatus',
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                if (orderStatus.toLowerCase() ==
                    'pending')
                  Row(
                    children: [
                      orderActionButton(
                        label: 'Accept',
                        icon: Icons.check_circle,
                        color: const Color(
                          0xFF146BFF,
                        ),
                        onTap: onAccept,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      orderActionButton(
                        label: 'Cancel',
                        icon: Icons.cancel,
                        color: const Color(
                          0xFFD32F2F,
                        ),
                        onTap: onCancel,
                      ),
                    ],
                  )
                else if (orderStatus.toLowerCase() ==
                    'accepted')
                  Row(
                    children: [
                      orderActionButton(
                        label: 'Mark Delivered',
                        icon: Icons.local_shipping,
                        color: const Color(
                          0xFF2E7D32,
                        ),
                        onTap: onMarkDelivered,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
