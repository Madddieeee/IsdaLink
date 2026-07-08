import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SupplierCodOrdersScreen
    extends
        StatelessWidget {
  const SupplierCodOrdersScreen({
    super.key,
  });

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get ordersStream {
    return FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
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

    return value.toString();
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

  Future<
    void
  >
  updateOrderStatus(
    BuildContext context,
    String documentId,
    String newStatus,
    String paymentStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(
            'orders',
          )
          .doc(
            documentId,
          )
          .update(
            {
              'orderStatus': newStatus,
              'paymentStatus': paymentStatus,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Order marked as $newStatus.',
          ),
          backgroundColor: statusColor(
            newStatus,
          ),
        ),
      );
    } catch (
      error
    ) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order: $error',
          ),
          backgroundColor: const Color(
            0xFFD32F2F,
          ),
        ),
      );
    }
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

  Widget orderCard(
    BuildContext context,
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final data = document.data();

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
    final vendorName = getStringValue(
      data,
      'vendorName',
      'Vendor',
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
                        'Ordered by $vendorName • ${formatDateFromData(data)}',
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
                        onTap: () => updateOrderStatus(
                          context,
                          document.id,
                          'Accepted',
                          'To be paid on delivery',
                        ),
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
                        onTap: () => updateOrderStatus(
                          context,
                          document.id,
                          'Cancelled',
                          'Cancelled',
                        ),
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
                        onTap: () => updateOrderStatus(
                          context,
                          document.id,
                          'Delivered',
                          'Paid',
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

  Widget emptyOrdersCard() {
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
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: Color(
              0xFF146BFF,
            ),
            size: 44,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No incoming COD orders yet',
            style: TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Vendor COD orders from Firebase will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
              'Loading incoming COD orders from Firebase...',
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
        'Unable to load Firebase COD orders: $error',
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
    final pendingCount = documents.where(
      (
        document,
      ) {
        final status = getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        );

        return status.toLowerCase() ==
            'pending';
      },
    ).length;

    final acceptedCount = documents.where(
      (
        document,
      ) {
        final status = getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        );

        return status.toLowerCase() ==
            'accepted';
      },
    ).length;

    final deliveredCount = documents.where(
      (
        document,
      ) {
        final status = getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        );

        return status.toLowerCase() ==
            'delivered';
      },
    ).length;

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
                  'Incoming COD Orders',
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
            'Review vendor orders, accept requests, and mark delivered COD transactions.',
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
                value: '${documents.length}',
                label: 'Total',
                icon: Icons.receipt_long,
              ),
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
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              statCard(
                value: '$deliveredCount',
                label: 'Delivered',
                icon: Icons.local_shipping,
              ),
              const Spacer(),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget bodyContent(
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
    return Column(
      children: [
        header(
          context,
          documents,
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
                'Incoming Orders',
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
                'Live vendor COD orders loaded from Firebase Firestore.',
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
              if (documents.isEmpty)
                emptyOrdersCard()
              else
                ...documents.map(
                  (
                    document,
                  ) => orderCard(
                    context,
                    document,
                  ),
                ),
            ],
          ),
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
                'Incoming Orders',
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
                'Incoming Orders',
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
            stream: ordersStream,
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

                  final documents = snapshot.data!.docs;

                  return bodyContent(
                    context,
                    documents,
                  );
                },
          ),
    );
  }
}
