import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_order_card.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_orders_header.dart';
import 'package:isdalink/services/supplier_order_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierCodOrdersScreen
    extends
        StatelessWidget {
  const SupplierCodOrdersScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  SupplierOrderService get orderService => const SupplierOrderService();

  Future<
    void
  >
  updateOrderStatus({
    required BuildContext context,
    required String documentId,
    required String newStatus,
    required String paymentStatus,
  }) async {
    try {
      await orderService.updateOrderStatus(
        documentId: documentId,
        newStatus: newStatus,
        paymentStatus: paymentStatus,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            newStatus.toLowerCase() ==
                    'cancelled'
                ? 'Order cancelled. Reserved stock has been returned and the vendor was notified.'
                : 'Order marked as $newStatus. The vendor was notified.',
          ),
          backgroundColor: OrderHelpers.statusColor(
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
            'Vendor COD orders for this supplier account will appear here.',
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

  Widget bodyContent({
    required BuildContext context,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  }) {
    return Column(
      children: [
        SupplierOrdersHeader(
          documents: documents,
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
                'Live vendor COD orders for this supplier account loaded from Firebase Firestore.',
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
                  ) => SupplierOrderCard(
                    document: document,
                    onAccept: () => updateOrderStatus(
                      context: context,
                      documentId: document.id,
                      newStatus: 'Accepted',
                      paymentStatus: 'To be paid on delivery',
                    ),
                    onCancel: () => updateOrderStatus(
                      context: context,
                      documentId: document.id,
                      newStatus: 'Cancelled',
                      paymentStatus: 'Cancelled',
                    ),
                    onMarkDelivered: () => updateOrderStatus(
                      context: context,
                      documentId: document.id,
                      newStatus: 'Delivered',
                      paymentStatus: 'Paid',
                    ),
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
        const SupplierOrdersHeader(
          documents: [],
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
        const SupplierOrdersHeader(
          documents: [],
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

  Widget loggedOutBody() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(
          22,
        ),
        padding: const EdgeInsets.all(
          18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            24,
          ),
        ),
        child: const Text(
          'Please log in first to view incoming COD orders.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(
              0xFFD32F2F,
            ),
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user ==
        null) {
      return Scaffold(
        backgroundColor: const Color(
          0xFFF4F8FB,
        ),
        body: loggedOutBody(),
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
            stream: orderService.ordersStream(
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

                  final documents = OrderHelpers.sortDocuments(
                    snapshot.data!.docs,
                  );

                  return bodyContent(
                    context: context,
                    documents: documents,
                  );
                },
          ),
    );
  }
}
