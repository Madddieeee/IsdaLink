import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/vendor/my_orders/widgets/order_filter_selector.dart';
import 'package:isdalink/screens/vendor/my_orders/widgets/order_notification_panel.dart';
import 'package:isdalink/screens/vendor/my_orders/widgets/vendor_order_card.dart';
import 'package:isdalink/services/review_service.dart';
import 'package:isdalink/services/vendor_order_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

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
  final VendorOrderService orderService = const VendorOrderService();
  final ReviewService reviewService = const ReviewService();

  String selectedFilter = 'All';

  Future<
    void
  >
  cancelPendingOrder(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user ==
        null) {
      showMessage(
        'Please log in first to cancel an order.',
        isError: true,
      );
      return;
    }

    final data = document.data();

    final currentStatus = OrderHelpers.getStringValue(
      data,
      'orderStatus',
      'Pending',
    );

    if (currentStatus.toLowerCase() !=
        'pending') {
      showMessage(
        'Only pending orders can be cancelled by the vendor.',
        isError: true,
      );
      return;
    }

    final productName = OrderHelpers.getStringValue(
      data,
      'productName',
      'this order',
    );

    final confirmCancel =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                  ),
                  title: const Text(
                    'Cancel Order?',
                    style: TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: Text(
                    'Cancel your pending COD order for $productName?\n\n'
                    'The reserved quantity will be returned to the supplier stock.',
                    style: const TextStyle(
                      color: Color(
                        0xFF52677A,
                      ),
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text(
                        'Keep Order',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFD32F2F,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Cancel Order',
                      ),
                    ),
                  ],
                );
              },
        );

    if (!mounted) {
      return;
    }

    if (confirmCancel !=
        true) {
      return;
    }

    try {
      await orderService.cancelPendingOrder(
        user: user,
        document: document,
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'Order cancelled. Reserved stock has been returned.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to cancel order: $error',
        isError: true,
      );
    }
  }

  Future<
    void
  >
  reviewCompletedOrder(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user ==
        null) {
      showMessage(
        'Please log in first to submit a review.',
        isError: true,
      );
      return;
    }

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

    final result = await showReviewDialog(
      productName: productName,
      supplierName: supplierName,
    );

    if (!mounted) {
      return;
    }

    if (result ==
        null) {
      return;
    }

    try {
      await reviewService.submitOrderReview(
        user: user,
        orderDocument: document,
        input: ReviewInput(
          rating: result.rating,
          comment: result.comment,
        ),
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'Review submitted. Thank you for rating the supplier.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to submit review: $error',
        isError: true,
      );
    }
  }

  Future<
    ReviewDialogResult?
  >
  showReviewDialog({
    required String productName,
    required String supplierName,
  }) async {
    int selectedRating = 5;
    String reviewComment = '';

    return showDialog<
      ReviewDialogResult
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            dialogContext,
          ) {
            return StatefulBuilder(
              builder:
                  (
                    dialogContext,
                    setDialogState,
                  ) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          24,
                        ),
                      ),
                      title: const Text(
                        'Rate Supplier',
                        style: TextStyle(
                          color: Color(
                            0xFF102C44,
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supplierName,
                              style: const TextStyle(
                                color: Color(
                                  0xFF146BFF,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Order item: $productName',
                              style: const TextStyle(
                                color: Color(
                                  0xFF7B8FA3,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (
                                  index,
                                ) {
                                  final starValue =
                                      index +
                                      1;
                                  final isSelected =
                                      starValue <=
                                      selectedRating;

                                  return IconButton(
                                    onPressed: () {
                                      setDialogState(
                                        () {
                                          selectedRating = starValue;
                                        },
                                      );
                                    },
                                    icon: Icon(
                                      isSelected
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: const Color(
                                        0xFFFFB703,
                                      ),
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            TextField(
                              maxLines: 3,
                              onChanged:
                                  (
                                    value,
                                  ) {
                                    reviewComment = value;
                                  },
                              decoration: InputDecoration(
                                labelText: 'Optional written review',
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: const Color(
                                  0xFFF4F8FB,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(
                            dialogContext,
                          ).pop(),
                          child: const Text(
                            'Cancel',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(
                                dialogContext,
                              ).pop(
                                ReviewDialogResult(
                                  rating: selectedRating,
                                  comment: reviewComment,
                                ),
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF146BFF,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Submit Review',
                          ),
                        ),
                      ],
                    );
                  },
            );
          },
    );
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor: isError
            ? const Color(
                0xFFD32F2F,
              )
            : const Color(
                0xFF2E7D32,
              ),
      ),
    );
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
    final pendingCount = OrderHelpers.countByStatus(
      documents,
      'Pending',
    );

    final acceptedCount = OrderHelpers.countByStatus(
      documents,
      'Accepted',
    );

    final deliveredCount = OrderHelpers.countByStatus(
      documents,
      'Delivered',
    );

    final cancelledCount = OrderHelpers.countByStatus(
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
            'Track your COD fish orders by status and review completed orders.',
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
            OrderHelpers.statusIcon(
              filter,
            ),
            color: OrderHelpers.statusColor(
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
            OrderHelpers.filterDescription(
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

  Widget ordersList({
    required String vendorId,
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
    final orders = OrderHelpers.filterOrders(
      documents: documents,
      selectedFilter: selectedFilter,
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
          OrderNotificationPanel(
            vendorId: vendorId,
            service: orderService,
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
            OrderHelpers.filterDescription(
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
              (
                document,
              ) => VendorOrderCard(
                document: document,
                onCancelPendingOrder: () => cancelPendingOrder(
                  document,
                ),
                onReviewOrder: () => reviewCompletedOrder(
                  document,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget bodyContent({
    required BuildContext context,
    required String vendorId,
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
        header(
          context,
          documents,
        ),
        OrderFilterSelector(
          documents: documents,
          selectedFilter: selectedFilter,
          onFilterSelected:
              (
                filter,
              ) {
                setState(
                  () {
                    selectedFilter = filter;
                  },
                );
              },
        ),
        ordersList(
          vendorId: vendorId,
          documents: documents,
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
                    vendorId: user.uid,
                    documents: documents,
                  );
                },
          ),
    );
  }
}

class ReviewDialogResult {
  const ReviewDialogResult({
    required this.rating,
    required this.comment,
  });

  final int rating;
  final String comment;
}
