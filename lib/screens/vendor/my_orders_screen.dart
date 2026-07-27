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

  Widget headerMetricCard({
    required String value,
    required String label,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(
            36,
          ),
          borderRadius: BorderRadius.circular(
            17,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(
              32,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(
                  42,
                ),
                borderRadius: BorderRadius.circular(
                  11,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(
              width: 7,
            ),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFFE6F9FF,
                      ),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusProgressItem({
    required String label,
    required int count,
    required IconData icon,
    required bool highlight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white
              : Colors.white.withAlpha(
                  30,
                ),
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(
              34,
            ),
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: highlight
                      ? const Color(
                          0xFF146BFF,
                        )
                      : Colors.white,
                  size: 20,
                ),
                if (count > 0)
                  Positioned(
                    right: -9,
                    top: -7,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                      ),
                      height: 18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFF4D2D,
                        ),
                        borderRadius: BorderRadius.circular(
                          99,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: highlight
                    ? const Color(
                        0xFF102C44,
                      )
                    : const Color(
                        0xFFE6F9FF,
                      ),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
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
    final toPayCount = OrderHelpers.countByStatus(
      documents,
      'Pending',
    );

    final toShipCount = OrderHelpers.countByStatus(
      documents,
      'Accepted',
    );

    final toReceiveCount = OrderHelpers.countByStatus(
      documents,
      'Delivered',
    );

    final cancelledCount = OrderHelpers.countByStatus(
      documents,
      'Cancelled',
    );

    final toRateCount = documents.where(
      (
        document,
      ) {
        final data = document.data();

        final status = OrderHelpers.getStringValue(
          data,
          'orderStatus',
          'Pending',
        ).toLowerCase();

        final reviewed = data['reviewSubmitted'] == true;

        return (status == 'delivered' || status == 'completed') && !reviewed;
      },
    ).length;

    final activeCount = toPayCount + toShipCount;
    final completedCount = documents.where(
      (
        document,
      ) {
        final status = OrderHelpers.getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        ).toLowerCase();

        return status == 'delivered' || status == 'completed';
      },
    ).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        52,
        20,
        22,
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
            Color(
              0xFF0F7BFF,
            ),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(
            34,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: 6,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(
                  22,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -58,
            bottom: 18,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(
                  15,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(
                      context,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          42,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(
                            35,
                          ),
                        ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Purchases',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Track COD orders from placement to rating.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(
                              0xFFE6F9FF,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(
                        38,
                      ),
                      borderRadius: BorderRadius.circular(
                        99,
                      ),
                      border: Border.all(
                        color: Colors.white.withAlpha(
                          30,
                        ),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          'COD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 18,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(
                    28,
                  ),
                  borderRadius: BorderRadius.circular(
                    23,
                  ),
                  border: Border.all(
                    color: Colors.white.withAlpha(
                      28,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        headerMetricCard(
                          value: '$activeCount',
                          label: 'Active',
                          icon: Icons.local_shipping_outlined,
                          accentColor: const Color(
                            0xFF10B7D4,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        headerMetricCard(
                          value: '$completedCount',
                          label: 'Completed',
                          icon: Icons.check_circle_outline,
                          accentColor: const Color(
                            0xFF2E7D32,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        headerMetricCard(
                          value: '${documents.length}',
                          label: 'Total',
                          icon: Icons.receipt_long,
                          accentColor: const Color(
                            0xFFFFB703,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      children: [
                        statusProgressItem(
                          label: 'To Pay',
                          count: toPayCount,
                          icon: Icons.payments_outlined,
                          highlight: toPayCount > 0,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        statusProgressItem(
                          label: 'To Ship',
                          count: toShipCount,
                          icon: Icons.inventory_2_outlined,
                          highlight: toShipCount > 0,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        statusProgressItem(
                          label: 'To Receive',
                          count: toReceiveCount,
                          icon: Icons.local_shipping_outlined,
                          highlight: toReceiveCount > 0,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        statusProgressItem(
                          label: 'To Rate',
                          count: toRateCount,
                          icon: Icons.star_border,
                          highlight: toRateCount > 0,
                        ),
                      ],
                    ),
                    if (cancelledCount > 0) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(
                              0xFFFFE4B7,
                            ),
                            size: 15,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Expanded(
                            child: Text(
                              '$cancelledCount cancelled order${cancelledCount == 1 ? '' : 's'} kept in history.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(
                                  0xFFFFE4B7,
                                ),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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
          16,
          14,
          16,
          22,
        ),
        children: [
          OrderNotificationPanel(
            vendorId: vendorId,
            service: orderService,
          ),
          Container(
            padding: const EdgeInsets.all(
              14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color: const Color(
                  0xFFE1EEF6,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(
                    0x0D000000,
                  ),
                  blurRadius: 10,
                  offset: Offset(
                    0,
                    5,
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
                    gradient: const LinearGradient(
                      colors: [
                        Color(
                          0xFF087AC0,
                        ),
                        Color(
                          0xFF10B7D4,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: Icon(
                    selectedFilter == 'All'
                        ? Icons.receipt_long
                        : OrderHelpers.statusIcon(
                            selectedFilter,
                          ),
                    color: Colors.white,
                    size: 21,
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
                        selectedFilter == 'All'
                            ? 'All COD Orders'
                            : '$selectedFilter Orders',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(
                            0xFF102C44,
                          ),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '${orders.length} result${orders.length == 1 ? '' : 's'} • ${OrderHelpers.filterDescription(selectedFilter)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(
                            0xFF7B8FA3,
                          ),
                          fontSize: 11.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 14,
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
