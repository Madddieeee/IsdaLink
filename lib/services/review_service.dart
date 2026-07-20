import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/utils/order_helpers.dart';

class ReviewInput {
  const ReviewInput({
    required this.rating,
    required this.comment,
  });

  final int rating;
  final String comment;
}

class ReviewService {
  const ReviewService();

  int getIntValue(
    Map<String, dynamic> data,
    String key,
    int fallback,
  ) {
    final value = data[key];

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  bool isCompletedStatus(
    String status,
  ) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'delivered' || lowerStatus == 'completed';
  }

  Future<void> submitOrderReview({
    required User user,
    required QueryDocumentSnapshot<Map<String, dynamic>> orderDocument,
    required ReviewInput input,
  }) async {
    if (input.rating < 1 || input.rating > 5) {
      throw Exception('Rating must be between 1 and 5 stars.');
    }

    final orderReference = orderDocument.reference;
    final reviewReference = FirebaseFirestore.instance
        .collection('reviews')
        .doc(orderDocument.id);

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final orderSnapshot = await transaction.get(orderReference);
        final reviewSnapshot = await transaction.get(reviewReference);

        if (!orderSnapshot.exists) {
          throw Exception('This order no longer exists.');
        }

        if (reviewSnapshot.exists) {
          throw Exception('A review has already been submitted for this order.');
        }

        final orderData = orderSnapshot.data() ?? <String, dynamic>{};

        final vendorId = OrderHelpers.getStringValue(
          orderData,
          'vendorId',
          '',
        );

        if (vendorId != user.uid) {
          throw Exception('You can only review your own completed order.');
        }

        final orderStatus = OrderHelpers.getStringValue(
          orderData,
          'orderStatus',
          'Pending',
        );

        if (!isCompletedStatus(orderStatus)) {
          throw Exception('Reviews are allowed only after the order is completed.');
        }

        if (orderData['reviewSubmitted'] == true) {
          throw Exception('A review has already been submitted for this order.');
        }

        final supplierId = OrderHelpers.getStringValue(
          orderData,
          'supplierId',
          '',
        );

        DocumentSnapshot<Map<String, dynamic>>? supplierSnapshot;

        if (supplierId.isNotEmpty) {
          final supplierReference = FirebaseFirestore.instance
              .collection('supplierProfiles')
              .doc(supplierId);
          supplierSnapshot = await transaction.get(supplierReference);
        }

        final productName = OrderHelpers.getStringValue(
          orderData,
          'productName',
          'Fish Product',
        );

        final supplierName = OrderHelpers.getStringValue(
          orderData,
          'supplierName',
          'Supplier',
        );

        final vendorName = OrderHelpers.getStringValue(
          orderData,
          'vendorName',
          user.displayName ?? user.email ?? 'Vendor',
        );

        final reviewText = input.comment.trim();

        transaction.set(
          reviewReference,
          {
            'orderId': orderDocument.id,
            'vendorId': user.uid,
            'vendorName': vendorName,
            'supplierId': supplierId,
            'supplierName': supplierName,
            'productName': productName,
            'rating': input.rating,
            'comment': reviewText,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          orderReference,
          {
            'reviewSubmitted': true,
            'reviewRating': input.rating,
            'reviewComment': reviewText,
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        if (supplierId.isNotEmpty) {
          final supplierReference = FirebaseFirestore.instance
              .collection('supplierProfiles')
              .doc(supplierId);

          final supplierData = supplierSnapshot?.data() ?? <String, dynamic>{};

          final currentReviews = getIntValue(
            supplierData,
            'reviews',
            0,
          );

          final currentRating = OrderHelpers.getDoubleValue(
            supplierData,
            'rating',
          );

          final currentRatingTotal = supplierData.containsKey('ratingTotal')
              ? OrderHelpers.getDoubleValue(
                  supplierData,
                  'ratingTotal',
                )
              : currentRating * currentReviews;

          final newReviews = currentReviews + 1;
          final newRatingTotal = currentRatingTotal + input.rating;
          final newRating = newRatingTotal / newReviews;

          transaction.set(
            supplierReference,
            {
              'rating': newRating,
              'reviews': newReviews,
              'ratingTotal': newRatingTotal,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
        }
      },
    );
  }
}
