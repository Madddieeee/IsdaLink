import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrdersScreen
    extends
        StatefulWidget {
  const MyOrdersScreen({
    super.key,
  });

  @override
  State<
    MyOrdersScreen
  >
  createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState
    extends
        State<
          MyOrdersScreen
        > {
  String selectedFilter = 'All';

  final List<
    String
  >
  orderFilters = const [
    'All',
    'Pending',
    'Accepted',
    'Delivered',
    'Cancelled',
  ];

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  ordersStream(
    String vendorId,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .where(
          'vendorId',
          isEqualTo: vendorId,
        )
        .snapshots();
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  notificationsStream(
    String vendorId,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'notifications',
        )
        .where(
          'vendorId',
          isEqualTo: vendorId,
        )
        .snapshots();
  }

  int createdAtMillis(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final value = document.data()['createdAt'];

    if (value
        is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  sortDocuments(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final sortedDocuments = [
      ...documents,
    ];

    sortedDocuments.sort(
      (
        a,
        b,
      ) =>
          createdAtMillis(
            b,
          ).compareTo(
            createdAtMillis(
              a,
            ),
          ),
    );

    return sortedDocuments;
  }

  Color statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'all':
        return const Color(
          0xFF102C44,
        );
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
      case 'all':
        return Icons.list_alt;
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

  String filterDescription(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'All COD order records from your account.';
      case 'pending':
        return 'Orders waiting for supplier response.';
      case 'accepted':
        return 'Orders approved by the supplier.';
      case 'delivered':
        return 'Completed COD orders.';
      case 'cancelled':
        return 'Declined or cancelled orders.';
      default:
        return 'Order records.';
    }
  }

  String getStringValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value ==
        null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  double getDoubleValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value.toDouble();
    }

    if (value
        is double) {
      return value;
    }

    if (value
        is String) {
      return double.tryParse(
            value,
          ) ??
          0;
    }

    return 0;
  }

  String formatNumber(
    double value,
  ) {
    if (value %
            1 ==
        0) {
      return value.toStringAsFixed(
        0,
      );
    }

    return value.toStringAsFixed(
      2,
    );
  }

  String formatDateFromData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final value = data['createdAt'];

    if (value
        is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    return 'Just now';
  }

  int countByStatus(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
    String status,
  ) {
    if (status.toLowerCase() ==
        'all') {
      return documents.length;
    }

    return documents.where(
      (
        document,
      ) {
        final orderStatus = getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        );

        return orderStatus.toLowerCase() ==
            status.toLowerCase();
      },
    ).length;
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  filteredOrders(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    if (selectedFilter.toLowerCase() ==
        'all') {
      return documents;
    }

    return documents.where(
      (
        document,
      ) {
        final orderStatus = getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        );

        return orderStatus.toLowerCase() ==
            selectedFilter.toLowerCase();
      },
    ).toList();
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

  Widget orderCard(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final data = document.data();

    final orderId =
        document.id.length >
            8
        ? 'ORD-${document.id.substring(0, 8).toUpperCase()}'
        : 'ORD-${document.id.toUpperCase()}';

    final productName = getStringValue(
      data,
      'productName',
      'Fish Product',
    );

    final supplierName = getStringValue(
      data,
      'supplierName',
      'Supplier',
    );

    final quantity = getDoubleValue(
      data,
      'quantity',
    );

    final quantityUnit = getStringValue(
      data,
      'quantityUnit',
      'kilo',
    );

    final totalAmount = getDoubleValue(
      data,
      'totalAmount',
    );

    final paymentMethod = getStringValue(
      data,
      'paymentMethod',
      'COD',
    );

    final paymentStatus = getStringValue(
      data,
      'paymentStatus',
      'To be paid on delivery',
    );

    final orderStatus = getStringValue(
      data,
      'orderStatus',
      'Pending',
    );

    final color = statusColor(
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
                    statusIcon(
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
                        formatDateFromData(
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
                              '${formatNumber(quantity)} $quantityUnit',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyOrdersCard(
    String filter,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
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
          Icon(
            statusIcon(
              filter,
            ),
            color: statusColor(
              filter,
            ),
            size: 44,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            filter ==
                    'All'
                ? 'No orders yet'
                : 'No $filter orders',
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            filterDescription(
              filter,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'Loading your orders from Firebase...',
              style: TextStyle(
                color: Color(
                  0xFF7B8FA3,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget errorOrdersCard(
    Object error,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: Text(
        'Unable to load your Firebase orders: $error',
        style: const TextStyle(
          color: Color(
            0xFFD32F2F,
          ),
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget header(
    BuildContext context,
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final pendingCount = countByStatus(
      documents,
      'Pending',
    );
    final acceptedCount = countByStatus(
      documents,
      'Accepted',
    );
    final deliveredCount = countByStatus(
      documents,
      'Delivered',
    );
    final cancelledCount = countByStatus(
      documents,
      'Cancelled',
    );

    return Container(
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
            'Track your COD fish orders by status.',
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
                value: '$pendingCount',
                label: 'Pending',
                icon: Icons.schedule,
              ),
              statCard(
                value: '$acceptedCount',
                label: 'Accepted',
                icon: Icons.check_circle,
              ),
              statCard(
                value: '$deliveredCount',
                label: 'Delivered',
                icon: Icons.local_shipping,
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              statCard(
                value: '$cancelledCount',
                label: 'Cancelled',
                icon: Icons.cancel,
              ),
              statCard(
                value: '${documents.length}',
                label: 'Total',
                icon: Icons.receipt_long,
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Future<
    void
  >
  markNotificationsRead(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    notifications,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final notification in notifications) {
      batch.update(
        notification.reference,
        {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  Widget notificationPanel(
    String vendorId,
  ) {
    return StreamBuilder<
      QuerySnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: notificationsStream(
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

            final unreadNotifications = sortDocuments(
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
                        onPressed: () => markNotificationsRead(
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

                      final title = getStringValue(
                        data,
                        'title',
                        'Order Update',
                      );

                      final message = getStringValue(
                        data,
                        'message',
                        'Your order status has changed.',
                      );

                      final status = getStringValue(
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
                              statusIcon(
                                status,
                              ),
                              color: statusColor(
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

  Widget filterOptionTile({
    required BuildContext sheetContext,
    required String filter,
    required int count,
  }) {
    final bool isSelected =
        selectedFilter ==
        filter;
    final color = statusColor(
      filter,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(
        18,
      ),
      onTap: () {
        setState(
          () {
            selectedFilter = filter;
          },
        );

        Navigator.pop(
          sheetContext,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(
                  22,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: isSelected
                ? color.withAlpha(
                    70,
                  )
                : const Color(
                    0xFFE1E9F0,
                  ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: color,
              size: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Icon(
              statusIcon(
                filter,
              ),
              color: color,
              size: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                filter ==
                        'All'
                    ? 'All Orders'
                    : filter,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : const Color(
                          0xFF102C44,
                        ),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: color.withAlpha(
                  22,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showFilterOptions(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            28,
          ),
        ),
      ),
      builder:
          (
            sheetContext,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFD5E0EA,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                const Color(
                                  0xFF146BFF,
                                ).withAlpha(
                                  22,
                                ),
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: const Icon(
                            Icons.filter_list,
                            color: Color(
                              0xFF146BFF,
                            ),
                            size: 21,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Expanded(
                          child: Text(
                            'Filter Orders',
                            style: TextStyle(
                              color: Color(
                                0xFF102C44,
                              ),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    ...orderFilters.map(
                      (
                        filter,
                      ) => filterOptionTile(
                        sheetContext: sheetContext,
                        filter: filter,
                        count: countByStatus(
                          documents,
                          filter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Widget filterButton(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final count = countByStatus(
      documents,
      selectedFilter,
    );

    final color = statusColor(
      selectedFilter,
    );

    return GestureDetector(
      onTap: () => showFilterOptions(
        documents,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          18,
          16,
          18,
          0,
        ),
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x0E000000,
              ),
              blurRadius: 12,
              offset: Offset(
                0,
                6,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(
                  24,
                ),
                borderRadius: BorderRadius.circular(
                  15,
                ),
              ),
              child: Icon(
                statusIcon(
                  selectedFilter,
                ),
                color: color,
                size: 22,
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
                    selectedFilter ==
                            'All'
                        ? 'Showing: All Orders'
                        : 'Showing: $selectedFilter Orders',
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
                    '$count result${count == 1 ? '' : 's'} • Tap to change filter',
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(
                0xFF7B8FA3,
              ),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget ordersList(
    String vendorId,
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final orders = filteredOrders(
      documents,
    );

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          20,
        ),
        children: [
          notificationPanel(
            vendorId,
          ),
          Text(
            selectedFilter ==
                    'All'
                ? 'All Orders'
                : '$selectedFilter Orders',
            style: const TextStyle(
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
          Text(
            filterDescription(
              selectedFilter,
            ),
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          if (orders.isEmpty)
            emptyOrdersCard(
              selectedFilter,
            )
          else
            ...orders.map(
              orderCard,
            ),
        ],
      ),
    );
  }

  Widget bodyContent(
    BuildContext context,
    String vendorId,
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    return Column(
      children: [
        header(
          context,
          documents,
        ),
        filterButton(
          documents,
        ),
        ordersList(
          vendorId,
          documents,
        ),
      ],
    );
  }

  Widget loadingBody(
    BuildContext context,
  ) {
    return Column(
      children: [
        header(
          context,
          const [],
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
                'My Orders',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              loadingOrdersCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorBody(
    BuildContext context,
    Object error,
  ) {
    return Column(
      children: [
        header(
          context,
          const [],
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
                'My Orders',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              errorOrdersCard(
                error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    if (user ==
        null) {
      return Scaffold(
        backgroundColor: const Color(
          0xFFF4F8FB,
        ),
        body: errorBody(
          context,
          'Please log in first to view your orders.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body:
          StreamBuilder<
            QuerySnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: ordersStream(
              user.uid,
            ),
            builder:
                (
                  context,
                  snapshot,
                ) {
                  if (snapshot.hasError) {
                    return errorBody(
                      context,
                      snapshot.error!,
                    );
                  }

                  if (!snapshot.hasData) {
                    return loadingBody(
                      context,
                    );
                  }

                  final documents = sortDocuments(
                    snapshot.data!.docs,
                  );

                  return bodyContent(
                    context,
                    user.uid,
                    documents,
                  );
                },
          ),
    );
  }
}
