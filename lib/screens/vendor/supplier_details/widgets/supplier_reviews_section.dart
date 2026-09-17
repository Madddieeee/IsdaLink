import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierReviewsSection extends StatefulWidget {
  const SupplierReviewsSection({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  final String? supplierId;
  final String supplierName;

  @override
  State<SupplierReviewsSection> createState() => _SupplierReviewsSectionState();
}

class _SupplierReviewsSectionState extends State<SupplierReviewsSection> {
  int? selectedRating;

  String? get supplierId => widget.supplierId;
  String get supplierName => widget.supplierName;

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

  String vendorInitial(
    String vendorName,
  ) {
    final value = vendorName.trim();

    if (value.isEmpty) {
      return 'V';
    }

    return value.substring(0, 1).toUpperCase();
  }

  DateTime? dateValue(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return '';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget ratingStars(
    int rating, {
    double size = 15,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          return Icon(
            index < rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: const Color(0xFFFFB703),
            size: size,
          );
        },
      ),
    );
  }

  Widget emptyReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE0EEF5),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.reviews_outlined,
            color: Color(0xFF87A5B8),
            size: 38,
          ),
          SizedBox(height: 10),
          Text(
            'No store reviews yet',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Ratings from completed COD orders will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
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
    ).round().clamp(1, 5);

    final createdAt = dateValue(data['createdAt']);
    final dateLabel = formatDate(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE0EEF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FD),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  vendorInitial(vendorName),
                  style: const TextStyle(
                    color: Color(0xFF087AC0),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ratingStars(rating),
                  ],
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF91A5B3),
                    fontSize: 9.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              productName,
              style: const TextStyle(
                color: Color(0xFF52677A),
                fontSize: 9.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                color: Color(0xFF52677A),
                fontSize: 11.3,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int documentRating(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return OrderHelpers.getDoubleValue(
      document.data(),
      'rating',
    ).round().clamp(1, 5);
  }

  Widget ratingFilterRow(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedReviews,
  ) {
    final counts = <int, int>{
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    for (final document in sortedReviews) {
      final rating = documentRating(document);
      counts[rating] = (counts[rating] ?? 0) + 1;
    }

    final availableRatings = [
      5,
      4,
      3,
      2,
      1,
    ].where((rating) => (counts[rating] ?? 0) > 0).toList();

    Widget filterChip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF087AC0)
                  : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? const Color(0xFF087AC0)
                    : const Color(0xFFDCECF4),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFF52677A),
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 1 + availableRatings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          if (index == 0) {
            return filterChip(
              label: 'All (${sortedReviews.length})',
              selected: selectedRating == null,
              onTap: () {
                setState(() {
                  selectedRating = null;
                });
              },
            );
          }

          final rating = availableRatings[index - 1];
          return filterChip(
            label: '$rating★ (${counts[rating]})',
            selected: selectedRating == rating,
            onTap: () {
              setState(() {
                selectedRating = rating;
              });
            },
          );
        },
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
      0,
      (total, document) {
        return total +
            OrderHelpers.getDoubleValue(
              document.data(),
              'rating',
            );
      },
    );

    final averageRating = totalRating / sortedReviews.length;

    final visibleReviews = selectedRating == null
        ? sortedReviews
        : sortedReviews.where(
            (document) => documentRating(document) == selectedRating,
          ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F9FD),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFFDCECF4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ratingStars(
                      averageRating.round().clamp(1, 5),
                      size: 18,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${sortedReviews.length} verified review'
                      '${sortedReviews.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF52677A),
                        fontSize: 10.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'From completed IsdaLink COD orders',
                      style: TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ratingFilterRow(sortedReviews),
        const SizedBox(height: 16),
        Text(
          selectedRating == null
              ? 'Reviews for $supplierName'
              : '$selectedRating-star reviews',
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Feedback submitted after completed fish orders.',
          style: TextStyle(
            color: Color(0xFF7B8FA3),
            fontSize: 10.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...visibleReviews.take(8).map(reviewTile),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final stream = reviewsStream;

    if (stream == null) {
      return emptyReviews();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: const Color(0xFFFFD7D7),
              ),
            ),
            child: const Text(
              'Unable to load store reviews right now.',
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF087AC0),
              ),
            ),
          );
        }

        return reviewsBody(
          snapshot.data!.docs,
        );
      },
    );
  }
}
