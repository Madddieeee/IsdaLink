import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierReviewsSection extends StatelessWidget {
  const SupplierReviewsSection({
    super.key,
    required this.supplierId,
  });

  final String? supplierId;

  Stream<QuerySnapshot<Map<String, dynamic>>>? get reviewsStream {
    final id = supplierId?.trim() ?? '';

    if (id.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('reviews')
        .where('supplierId', isEqualTo: id)
        .snapshots();
  }

  Widget sectionCard({
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        top: 4,
        bottom: 16,
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFB703,
                  ).withAlpha(
                    30,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(
                    0xFFFFB703,
                  ),
                  size: 23,
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
                      'Supplier Reviews',
                      style: TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Reviews from completed vendor orders.',
                      style: TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          child,
        ],
      ),
    );
  }

  Widget ratingStars(
    int rating,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          return Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: const Color(
              0xFFFFB703,
            ),
            size: 15,
          );
        },
      ),
    );
  }

  Widget reviewTile(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final vendorName = OrderHelpers.getStringValue(
      data,
      'vendorName',
      'Vendor',
    );

    final productName = OrderHelpers.getStringValue(
      data,
      'productName',
      'Fish Product',
    );

    final comment = OrderHelpers.getStringValue(
      data,
      'comment',
      '',
    );

    final rating = OrderHelpers.getDoubleValue(
      data,
      'rating',
    ).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF4F8FB,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vendorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ratingStars(
                rating,
              ),
            ],
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
              fontSize: 11,
            ),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              comment,
              style: const TextStyle(
                color: Color(
                  0xFF52677A,
                ),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget emptyReviews() {
    return const Text(
      'No reviews yet. Reviews will appear after vendors rate completed orders.',
      style: TextStyle(
        color: Color(
          0xFF7B8FA3,
        ),
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  Widget reviewsBody(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    if (documents.isEmpty) {
      return emptyReviews();
    }

    final sortedReviews = OrderHelpers.sortDocuments(
      documents,
    );

    final totalRating = sortedReviews.fold<double>(
      0.0,
      (total, document) {
        return total +
            OrderHelpers.getDoubleValue(
              document.data(),
              'rating',
            );
      },
    );

    final averageRating = totalRating / sortedReviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: const Color(
              0xFFFFF7E8,
            ),
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star,
                color: Color(
                  0xFFFFB703,
                ),
                size: 24,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                averageRating.toStringAsFixed(
                  1,
                ),
                style: const TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  '${sortedReviews.length} review${sortedReviews.length == 1 ? '' : 's'}',
                  style: const TextStyle(
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
        ),
        const SizedBox(
          height: 12,
        ),
        ...sortedReviews.take(5).map(
              reviewTile,
            ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final stream = reviewsStream;

    if (stream == null) {
      return sectionCard(
        child: emptyReviews(),
      );
    }

    return sectionCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Unable to load supplier reviews: ${snapshot.error}',
              style: const TextStyle(
                color: Color(
                  0xFFD32F2F,
                ),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(
                  8,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            );
          }

          return reviewsBody(
            snapshot.data!.docs,
          );
        },
      ),
    );
  }
}
