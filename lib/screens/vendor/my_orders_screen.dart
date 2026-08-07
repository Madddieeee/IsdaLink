import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String statusOf(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return OrderHelpers.getStringValue(
      document.data(),
      'orderStatus',
      'Pending',
    );
  }

  bool isCompletedStatus(
    String status,
  ) {
    final value = status.toLowerCase();
    return value == 'completed' || value == 'delivered';
  }

  bool isCancelledStatus(
    String status,
  ) {
    final value = status.toLowerCase();
    return value == 'cancelled' ||
        value == 'rejected' ||
        value == 'returned' ||
        value == 'refunded';
  }

  bool isActiveStatus(
    String status,
  ) {
    final value = status.toLowerCase();
    return value == 'pending' || value == 'accepted';
  }

  int activeOrderCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where(
      (document) => isActiveStatus(
        statusOf(document),
      ),
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

        if (filter == 'active') {
          return isActiveStatus(status);
        }

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
      case 'active':
        return 'Orders currently pending or accepted.';
      case 'pending':
        return 'Orders waiting for supplier confirmation.';
      case 'accepted':
        return 'Orders confirmed by the supplier.';
      case 'completed':
        return 'Completed Cash on Delivery transactions.';
      case 'cancelled':
        return 'Cancelled, rejected, returned, or refunded records.';
      case 'all':
      default:
        return 'All Cash on Delivery orders from your account.';
    }
  }

  void selectFilter(
    String filter,
  ) {
    setState(
      () {
        selectedFilter = filter;
      },
    );
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            22,
            22,
            22,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            22,
            14,
            22,
            4,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            18,
          ),
          title: const Row(
            children: [
              _DialogIcon(
                icon: Icons.cancel_outlined,
                color: Color(0xFFD32F2F),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Cancel this order?',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Cancel your pending order for $productName?\n\n'
            'The deducted quantity will be returned to the supplier stock.',
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
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
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Cancel Order',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
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

  int reviewRatingOf(
    Map<String, dynamic> data,
  ) {
    final value = data['reviewRating'];

    if (value is int) {
      return value.clamp(1, 5);
    }

    if (value is num) {
      return value.toInt().clamp(1, 5);
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed.clamp(1, 5);
      }
    }

    return 0;
  }

  String ratingLabel(
    int rating,
  ) {
    return switch (rating) {
      1 => 'Poor',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Very Good',
      5 => 'Excellent',
      _ => 'Select your rating',
    };
  }

  Future<void> reviewCompletedOrder(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please log in first to manage your review.',
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

    final isEditing = data['reviewSubmitted'] == true;
    final initialRating = isEditing ? reviewRatingOf(data) : 0;
    final initialComment = isEditing
        ? OrderHelpers.getStringValue(
            data,
            'reviewComment',
            '',
          )
        : '';

    final result = await showReviewDialog(
      productName: productName,
      supplierName: supplierName,
      initialRating: initialRating,
      initialComment: initialComment,
      isEditing: isEditing,
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final input = ReviewInput(
        rating: result.rating,
        comment: result.comment,
      );

      if (isEditing) {
        await reviewService.updateOrderReview(
          user: user,
          orderDocument: document,
          input: input,
        );
      } else {
        await reviewService.submitOrderReview(
          user: user,
          orderDocument: document,
          input: input,
        );
      }

      if (!mounted) {
        return;
      }

      showMessage(
        isEditing
            ? 'Your review was updated.'
            : 'Review submitted. Thank you for rating the supplier.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        isEditing
            ? 'Failed to update review: $error'
            : 'Failed to submit review: $error',
        isError: true,
      );
    }
  }

  Future<ReviewDialogResult?> showReviewDialog({
    required String productName,
    required String supplierName,
    required int initialRating,
    required String initialComment,
    required bool isEditing,
  }) async {
    int selectedRating = initialRating;
    String reviewText = initialComment;

    return showModalBottomSheet<ReviewDialogResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(150),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final canSubmit = selectedRating >= 1 && selectedRating <= 5;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBFD),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBED0DC),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0875D1),
                                  Color(0xFF12B6D6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              isEditing
                                  ? Icons.edit_note_rounded
                                  : Icons.star_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing
                                      ? 'Edit Your Review'
                                      : 'Rate Your Supplier',
                                  style: const TextStyle(
                                    color: Color(0xFF102C44),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isEditing
                                      ? 'Update your rating or written feedback.'
                                      : 'Share your experience from this completed COD order.',
                                  style: const TextStyle(
                                    color: Color(0xFF7B8FA3),
                                    fontSize: 10.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF52677A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFEAF7FB),
                              Color(0xFFF1F8FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFD5EAF4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 39,
                              height: 39,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFF0875D1),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplierName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF102C44),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7B8FA3),
                                      fontSize: 9.8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7EF),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  color: Color(0xFF147D64),
                                  fontSize: 7.8,
                                  letterSpacing: 0.45,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'YOUR RATING',
                        style: TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 8.8,
                          letterSpacing: 0.65,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Center(
                        child: Text(
                          ratingLabel(selectedRating),
                          style: TextStyle(
                            color: selectedRating == 0
                                ? const Color(0xFF7B8FA3)
                                : const Color(0xFF102C44),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) {
                            final value = index + 1;
                            final selected = value <= selectedRating;

                            return IconButton(
                              tooltip: '$value star${value == 1 ? '' : 's'}',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setSheetState(
                                  () {
                                    selectedRating = value;
                                  },
                                );
                              },
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  selected
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  key: ValueKey<bool>(selected),
                                  color: const Color(0xFFFFB703),
                                  size: 35,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          selectedRating == 0
                              ? 'Tap a star to continue'
                              : '$selectedRating of 5 stars',
                          style: const TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 9.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'WRITTEN REVIEW',
                        style: TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 8.8,
                          letterSpacing: 0.65,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        initialValue: initialComment,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          reviewText = value;
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Optional: tell other vendors about your experience...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9AAEBC),
                            fontSize: 11,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: Color(0xFFDDEAF2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: Color(0xFF0875D1),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F6FA),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF0875D1),
                              size: 17,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your rating is shown on the supplier profile. You can edit this review later from My Orders.',
                                style: TextStyle(
                                  color: Color(0xFF657C8E),
                                  fontSize: 9.4,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF52677A),
                                side: const BorderSide(
                                  color: Color(0xFFC9D8E2),
                                ),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: canSubmit
                                  ? () {
                                      Navigator.pop(
                                        sheetContext,
                                        ReviewDialogResult(
                                          rating: selectedRating,
                                          comment: reviewText.trim(),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: Icon(
                                isEditing
                                    ? Icons.save_outlined
                                    : Icons.send_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isEditing
                                    ? 'Save Changes'
                                    : selectedRating == 0
                                        ? 'Select a Rating'
                                        : 'Submit Review',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0875D1),
                                disabledBackgroundColor:
                                    const Color(0xFFDCE7EF),
                                foregroundColor: Colors.white,
                                disabledForegroundColor:
                                    const Color(0xFF7B8FA3),
                                elevation: canSubmit ? 3 : 0,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget reviewEditPanel(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rating = reviewRatingOf(data);
    final comment = OrderHelpers.getStringValue(
      data,
      'reviewComment',
      '',
    );

    return Transform.translate(
      offset: const Offset(0, -8),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          5,
          0,
          5,
          8,
        ),
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          10,
          10,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFEAF8F2),
              Color(0xFFF1F8FF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFCFE8DE),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: Color(0xFF147D64),
                size: 19,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Your Review',
                        style: TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 10.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 7),
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFB703),
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      comment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF657C8E),
                        fontSize: 9.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => reviewCompletedOrder(document),
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
              ),
              label: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0875D1),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget header({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) {
    final active = activeOrderCount(documents);
    final completed = completedOrderCount(documents);
    final total = documents.length;
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: const _OrdersWaveTransitionPainter(),
              ),
            ),
          ),
          ClipPath(
            clipper: const _OrdersHeaderClipper(),
            clipBehavior: Clip.hardEdge,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                topPadding + 8,
                14,
                33,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF06355F),
                    Color(0xFF0875D1),
                    Color(0xFF12B6D6),
                  ],
                  stops: [
                    0,
                    0.57,
                    1,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _OrdersHeaderBackdropPainter(),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _HeaderActionButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MY ORDERS',
                                  style: TextStyle(
                                    color: Color(0xFFCBF4F7),
                                    fontSize: 8.2,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.25,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Order Center',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.25,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Track your Cash on Delivery orders.',
                                  style: TextStyle(
                                    color: Color(0xFFDDF5F7),
                                    fontSize: 10.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _CodBadge(),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _OrdersOverviewPanel(
                        active: active,
                        completed: completed,
                        total: total,
                        onActiveTap: () => selectFilter('Active'),
                        onCompletedTap: () => selectFilter('Completed'),
                        onTotalTap: () => selectFilter('All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE0EDF4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C00152A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0875D1),
                  Color(0xFF12B6D6),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
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
                  '$visibleCount result${visibleCount == 1 ? '' : 's'} · '
                  '${filterDescription()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 10.2,
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
      padding: const EdgeInsets.all(24),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF0875D1),
              size: 30,
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
              fontSize: 11.3,
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
              color: Color(0xFF0875D1),
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
          context: context,
          documents: documents,
        ),
        OrderFilterSelector(
          documents: documents,
          selectedFilter: selectedFilter,
          onFilterSelected: selectFilter,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              11,
              16,
              28,
            ),
            children: [
              OrderNotificationPanel(
                vendorId: vendorId,
                service: orderService,
              ),
              listHeading(orders.length),
              const SizedBox(height: 13),
              if (orders.isEmpty)
                emptyOrdersCard()
              else
                ...orders.map(
                  (document) {
                    final reviewSubmitted =
                        document.data()['reviewSubmitted'] == true;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VendorOrderCard(
                          document: document,
                          onCancelPendingOrder: () => cancelPendingOrder(
                            document,
                          ),
                          onReviewOrder: () => reviewCompletedOrder(
                            document,
                          ),
                        ),
                        if (reviewSubmitted)
                          reviewEditPanel(document),
                      ],
                    );
                  },
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
          context: context,
          documents: const [],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              28,
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
          context: context,
          documents: const [],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              28,
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

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withAlpha(28),
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withAlpha(38),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _CodBadge extends StatelessWidget {
  const _CodBadge();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withAlpha(38),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: Color(0xFFE9FDFF),
            size: 14,
          ),
          SizedBox(width: 5),
          Text(
            'COD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersOverviewPanel extends StatelessWidget {
  const _OrdersOverviewPanel({
    required this.active,
    required this.completed,
    required this.total,
    required this.onActiveTap,
    required this.onCompletedTap,
    required this.onTotalTap,
  });

  final int active;
  final int completed;
  final int total;
  final VoidCallback onActiveTap;
  final VoidCallback onCompletedTap;
  final VoidCallback onTotalTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        9,
        10,
        9,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withAlpha(34),
            Colors.white.withAlpha(17),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withAlpha(42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(19),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              SizedBox(
                width: 7,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF8AF0B0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 7),
              Text(
                'ORDER OVERVIEW',
                style: TextStyle(
                  color: Color(0xFFD8F7F5),
                  fontSize: 7.8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
              Spacer(),
              Text(
                'Tap a metric',
                style: TextStyle(
                  color: Color(0xFFBCE8EC),
                  fontSize: 7.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.pending_actions_rounded,
                  value: active,
                  label: 'Active',
                  accentColor: const Color(0xFFFFDEA0),
                  onTap: onActiveTap,
                ),
              ),
              const _OverviewDivider(),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.task_alt_rounded,
                  value: completed,
                  label: 'Completed',
                  accentColor: const Color(0xFFA8F0DC),
                  onTap: onCompletedTap,
                ),
              ),
              const _OverviewDivider(),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.receipt_long_rounded,
                  value: total,
                  label: 'Total',
                  accentColor: const Color(0xFFAEEBFF),
                  onTap: onTotalTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 1,
      height: 35,
      margin: const EdgeInsets.symmetric(
        horizontal: 3,
      ),
      color: Colors.white.withAlpha(39),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.white.withAlpha(23),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(32),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withAlpha(70),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 15,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
                        color: Color(0xFFD8F3F5),
                        fontSize: 7.8,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersHeaderClipper extends CustomClipper<Path> {
  const _OrdersHeaderClipper();

  @override
  Path getClip(
    Size size,
  ) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(
        0,
        size.height - 31,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height - 17,
        size.width * 0.38,
        size.height - 7,
        size.width * 0.56,
        size.height - 11,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height - 15,
        size.width * 0.87,
        size.height - 31,
        size.width + 8,
        size.height - 33,
      )
      ..lineTo(
        size.width + 8,
        0,
      )
      ..close();
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return false;
  }
}

class _OrdersWaveTransitionPainter extends CustomPainter {
  const _OrdersWaveTransitionPainter();

  Path wave(
    Size size,
  ) {
    return Path()
      ..moveTo(
        -8,
        size.height - 31,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height - 17,
        size.width * 0.38,
        size.height - 7,
        size.width * 0.56,
        size.height - 11,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height - 15,
        size.width * 0.87,
        size.height - 31,
        size.width + 10,
        size.height - 33,
      );
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final path = wave(size);

    final shadow = Paint()
      ..color = Colors.black.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    final underglow = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0B76C8),
          Color(0xFF16B8D5),
          Color(0xFF77E6EB),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          size.height - 46,
          size.width,
          32,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final foam = Paint()
      ..color = Colors.white.withAlpha(98)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawPath(path, shadow)
      ..drawPath(path, underglow)
      ..drawPath(path, foam);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

class _OrdersHeaderBackdropPainter extends CustomPainter {
  const _OrdersHeaderBackdropPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final glowCenter = Offset(
      size.width * 0.86,
      size.height * 0.25,
    );

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(22),
          Colors.white.withAlpha(0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: glowCenter,
          radius: size.width * 0.39,
        ),
      );

    canvas.drawCircle(
      glowCenter,
      size.width * 0.39,
      glow,
    );

    final ring = Paint()
      ..color = Colors.white.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas
      ..drawCircle(
        Offset(
          size.width * 0.94,
          size.height * 0.38,
        ),
        size.width * 0.11,
        ring,
      )
      ..drawCircle(
        Offset(
          size.width * 0.94,
          size.height * 0.38,
        ),
        size.width * 0.19,
        ring,
      );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
