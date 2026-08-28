import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';

class SupplierProfileCard extends StatelessWidget {
  const SupplierProfileCard({
    super.key,
    required this.supplier,
    required this.paymentMethod,
    required this.status,
    required this.isFavorite,
    required this.favoriteBusy,
    required this.showFavoriteAction,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  final Supplier supplier;
  final String paymentMethod;
  final String status;
  final bool isFavorite;
  final bool favoriteBusy;
  final bool showFavoriteAction;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  bool get hasNetworkImage {
    final imageUrl = supplier.profileImageUrl.trim();

    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  String get storeInitial {
    final name = supplier.name.trim();

    if (name.isEmpty) {
      return 'S';
    }

    return name.substring(0, 1).toUpperCase();
  }

  String get ratingLabel {
    if (supplier.reviews <= 0 || supplier.rating <= 0) {
      return 'No reviews yet';
    }

    final reviewWord = supplier.reviews == 1 ? 'review' : 'reviews';

    return '${supplier.rating.toStringAsFixed(1)} • '
        '${supplier.reviews} $reviewWord';
  }

  String get paymentLabel {
    return 'COD only';
  }

  Widget storePhoto() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD8EDF6),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: hasNetworkImage
            ? Image.network(
                supplier.profileImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return SupplierInitial(
                    initial: storeInitial,
                  );
                },
              )
            : SupplierInitial(
                initial: storeInitial,
              ),
      ),
    );
  }

  Widget verifiedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: Color(0xFF11A87A),
            size: 11,
          ),
          SizedBox(width: 3),
          Text(
            'Verified',
            style: TextStyle(
              color: Color(0xFF0B8D68),
              fontSize: 8.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget newSupplierChip() {
    final remaining = supplier.newSupplierDaysRemaining;
    final dayWord = remaining == 1 ? 'day' : 'days';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9F1C),
            Color(0xFFFFC857),
          ],
        ),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26E78600),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            'New • $remaining $dayWord left',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget ratingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            supplier.reviews > 0
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: supplier.reviews > 0
                ? const Color(0xFFFFB703)
                : const Color(0xFF8B9DAA),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            ratingLabel,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 9.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget codChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FD),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payments_outlined,
            color: Color(0xFF087AC0),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            paymentLabel,
            style: const TextStyle(
              color: Color(0xFF087AC0),
              fontSize: 9.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }


  Widget favoriteButton() {
    return Tooltip(
      message: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
      child: Material(
        color: isFavorite
            ? const Color(0xFFFFEEF2)
            : const Color(0xFFF2F7FA),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: favoriteBusy ? null : onFavoriteToggle,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: favoriteBusy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Color(0xFF087AC0),
                      ),
                    )
                  : Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE94C72)
                          : const Color(0xFF6F8799),
                      size: 18,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: supplier.isNewSupplier
                    ? const Color(0xFFFFD486)
                    : const Color(0xFFE0EEF5),
                width: supplier.isNewSupplier ? 1.3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: supplier.isNewSupplier
                      ? const Color(0x18FFA000)
                      : const Color(0x10000000),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                storePhoto(),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              supplier.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 15.3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          verifiedChip(),
                          if (showFavoriteAction) ...[
                            const SizedBox(width: 6),
                            favoriteButton(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF7B8FA3),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              supplier.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6D8294),
                                fontSize: 11.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        supplier.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF52677A),
                          fontSize: 10.8,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (supplier.isNewSupplier) newSupplierChip(),
                          ratingChip(),
                          codChip(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 31,
                  height: 31,
                  margin: const EdgeInsets.only(top: 39),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8FD),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF087AC0),
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SupplierInitial extends StatelessWidget {
  const SupplierInitial({
    super.key,
    required this.initial,
  });

  final String initial;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFEAF8FC),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF087AC0),
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
