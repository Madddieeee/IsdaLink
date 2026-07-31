import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/vendor/my_orders/widgets/order_filter_selector.dart';
import 'package:isdalink/screens/vendor/my_orders/widgets/order_notification_panel.dart';
import 'package:isdalink/screens/vendor/my_orders/widgets/vendor_order_card.dart';
import 'package:isdalink/services/review_service.dart';
import 'package:isdalink/services/vendor_order_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({
    super.key,
  });

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final VendorOrderService orderService = const VendorOrderService();
  final ReviewService reviewService = const ReviewService();

  String selectedFilter = 'All';

  bool isCompletedStatus(
    String status,
  ) {
    final value = status.toLowerCase();
    return value == 'delivered' || value == 'completed';
  }

  bool isCancelledStatus(
    String status,
  ) {
    final value = status.toLowerCase();
    return value == 'cancelled' || value == 'rejected';
  }

  String statusOf(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return OrderHelpers.getStringValue(
      document.data(),
      'orderStatus',
      'Pending',
    );
  }

  int activeOrderCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where(
      (document) {
        final status = statusOf(document).toLowerCase();
        return status == 'pending' || status == 'accepted';
      },
    ).length;
  }

  int completedOrderCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where(
      (document) => isCompletedStatus(
        statusOf(document),
      ),
    ).length;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final filter = selectedFilter.toLowerCase();

    if (filter == 'all') {
      return documents;
    }

    return documents.where(
      (document) {
        final status = statusOf(document);

        if (filter == 'completed') {
          return isCompletedStatus(status);
        }

        if (filter == 'cancelled') {
          return isCancelledStatus(status);
        }

        return status.toLowerCase() == filter;
      },
    ).toList();
  }

  String filterDescription() {
    switch (selectedFilter.toLowerCase()) {
      case 'pending':
        return 'Orders waiting for supplier confirmation.';
      case 'accepted':
        return 'Orders confirmed by the supplier.';
      case 'completed':
        return 'Completed Cash on Delivery transactions.';
      case 'cancelled':
        return 'Cancelled or rejected order records.';
      case 'all':
      default:
        return 'All Cash on Delivery orders from your account.';
    }
  }

  Future<void> cancelPendingOrder(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

    if (currentStatus.toLowerCase() != 'pending') {
      showMessage(
        'Only pending orders can be cancelled.',
        isError: true,
      );
      return;
    }

    final productName = OrderHelpers.getStringValue(
      data,
      'productName',
      'this order',
    );

    final confirmCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Cancel this order?',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Cancel your pending order for $productName?\n\n'
            'The deducted quantity will be returned to the supplier stock.',
            style: const TextStyle(
              color: Color(0xFF52677A),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmCancel != true) {
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
        'Order cancelled. The deducted stock was restored.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to cancel order: $error',
        isError: true,
      );
    }
  }

  Future<void> reviewCompletedOrder(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

    if (!mounted || result == null) {
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to submit review: $error',
        isError: true,
      );
    }
  }

  Future<ReviewDialogResult?> showReviewDialog({
    required String productName,
    required String supplierName,
  }) async {
    int selectedRating = 5;
    final reviewController = TextEditingController();

    final result = await showDialog<ReviewDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Rate Supplier',
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplierName,
                    style: const TextStyle(
                      color: Color(0xFF0A73D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order item: $productName',
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) {
                        final starValue = index + 1;
                        final selected = starValue <= selectedRating;

                        return IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                selectedRating = starValue;
                              },
                            );
                          },
                          icon: Icon(
                            selected
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB703),
                            size: 31,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Optional written review',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: const Color(0xFFF4F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    ReviewDialogResult(
                      rating: selectedRating,
                      comment: reviewController.text,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A73D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );

    reviewController.dispose();
    return result;
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget summaryCard({
    required int value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(34),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(24),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFDCEEFF),
                      fontSize: 9.2,
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

  Widget header(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final activeCount = activeOrderCount(documents);
    final completedCount = completedOrderCount(documents);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        topPadding + 12,
        18,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF073B66),
            Color(0xFF0A73D8),
            Color(0xFF12B6D6),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -44,
            top: -42,
            child: Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 92,
            bottom: -74,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withAlpha(28),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Orders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Track your Cash on Delivery orders.',
                          style: TextStyle(
                            color: Color(0xFFDCEEFF),
                            fontSize: 11.5,
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
                      color: Colors.white.withAlpha(24),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withAlpha(30),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'COD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  summaryCard(
                    value: activeCount,
                    label: 'Active',
                    icon: Icons.pending_actions_rounded,
                  ),
                  const SizedBox(width: 9),
                  summaryCard(
                    value: completedCount,
                    label: 'Completed',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(width: 9),
                  summaryCard(
                    value: documents.length,
                    label: 'Total',
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget listHeading(
    int visibleCount,
  ) {
    final title = selectedFilter == 'All'
        ? 'All COD Orders'
        : '$selectedFilter Orders';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE0EDF4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A73D8),
                  Color(0xFF12B6D6),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$visibleCount result${visibleCount == 1 ? '' : 's'} · ${filterDescription()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 10.4,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE0EDF4),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF0A73D8),
              size: 29,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            selectedFilter == 'All'
                ? 'No orders yet'
                : 'No $selectedFilter orders',
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            filterDescription(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0A73D8),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading your orders...',
              style: TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget errorCard(
    Object error,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD6D6),
        ),
      ),
      child: Text(
        'Unable to load your orders: $error',
        style: const TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget loadedBody({
    required String vendorId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) {
    final orders = filteredOrders(documents);

    return Column(
      children: [
        header(
          context,
          documents,
        ),
        OrderFilterSelector(
          documents: documents,
          selectedFilter: selectedFilter,
          onFilterSelected: (filter) {
            setState(
              () {
                selectedFilter = filter;
              },
            );
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24,
            ),
            children: [
              OrderNotificationPanel(
                vendorId: vendorId,
                service: orderService,
              ),
              listHeading(orders.length),
              const SizedBox(height: 14),
              if (orders.isEmpty)
                emptyOrdersCard()
              else
                ...orders.map(
                  (document) => VendorOrderCard(
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
        ),
      ],
    );
  }

  Widget loadingBody() {
    return Column(
      children: [
        header(
          context,
          const [],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              24,
            ),
            children: [
              loadingCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorBody(
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
              16,
              18,
              16,
              24,
            ),
            children: [
              errorCard(error),
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

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: errorBody(
          'Please log in first to view your orders.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: orderService.ordersStream(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return errorBody(
              snapshot.error!,
            );
          }

          if (!snapshot.hasData) {
            return loadingBody();
          }

          final documents = OrderHelpers.sortDocuments(
            snapshot.data!.docs,
          );

          return loadedBody(
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
