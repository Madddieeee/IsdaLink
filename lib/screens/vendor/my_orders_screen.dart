import 'package:flutter/material.dart';
import 'package:isdalink/data/sample_orders.dart';
import 'package:isdalink/models/order_model.dart';

class MyOrdersScreen
    extends
        StatelessWidget {
  const MyOrdersScreen({
    super.key,
  });

  Color statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(
          0xFFFF7A1A,
        );
      case 'accepted':
        return const Color(
          0xFF146BFF,
        );
      case 'delivered':
        return const Color(
          0xFF2E7D32,
        );
      case 'cancelled':
        return const Color(
          0xFFD32F2F,
        );
      default:
        return const Color(
          0xFF7B8FA3,
        );
    }
  }

  IconData statusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'delivered':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt_long;
    }
  }

  String formatDate(
    DateTime date,
  ) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(
            38,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(
              36,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFFDCE9F5,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
            statusIcon(
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
    final bool isPaid =
        paymentStatus.toLowerCase() ==
        'paid';
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget orderCard(
    OrderModel order,
  ) {
    final color = statusColor(
      order.orderStatus,
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
                    statusIcon(
                      order.orderStatus,
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
                        order.orderId,
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
                        formatDate(
                          order.orderDate,
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
                  order.orderStatus,
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
                  order.productName,
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
                        order.supplierName,
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
                              '${order.quantity} ${order.quantityUnit}',
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
                              '₱${order.totalAmount.toStringAsFixed(0)}',
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
                            order.paymentMethod,
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
                    paymentChip(
                      order.paymentStatus,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Details',
                        style: TextStyle(
                          color: Color(
                            0xFF146BFF,
                          ),
                          fontWeight: FontWeight.w800,
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
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final pendingCount = sampleOrders
        .where(
          (
            order,
          ) =>
              order.orderStatus.toLowerCase() ==
              'pending',
        )
        .length;
    final deliveredCount = sampleOrders
        .where(
          (
            order,
          ) =>
              order.orderStatus.toLowerCase() ==
              'delivered',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              54,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(
                    0xFF102C44,
                  ),
                  Color(
                    0xFF146BFF,
                  ),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(
                  32,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(
                        context,
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                            38,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'My Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Track your COD fish orders and supplier transactions.',
                  style: TextStyle(
                    color: Color(
                      0xFFDCE9F5,
                    ),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Row(
                  children: [
                    statCard(
                      value: '${sampleOrders.length}',
                      label: 'Total',
                      icon: Icons.receipt_long,
                    ),
                    statCard(
                      value: '$pendingCount',
                      label: 'Pending',
                      icon: Icons.schedule,
                    ),
                    statCard(
                      value: '$deliveredCount',
                      label: 'Delivered',
                      icon: Icons.local_shipping,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                20,
              ),
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                const Text(
                  'Sample order records will be connected to the database later.',
                  style: TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                ...sampleOrders.map(
                  orderCard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
