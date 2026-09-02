import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';

class SupplierProfileCard extends StatelessWidget {
  const SupplierProfileCard({
    super.key,
    required this.supplier,
    required this.availableListingCount,
    required this.isFavorite,
    required this.favoriteBusy,
    required this.showFavoriteAction,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  final Supplier supplier;
  final int availableListingCount;
  final bool isFavorite;
  final bool favoriteBusy;
  final bool showFavoriteAction;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  bool get hasNetworkImage {
    final imageUrl = supplier.profileImageUrl.trim();
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  String get storeInitial {
    final name = supplier.name.trim();
    return name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase();
  }

  String get compactLocation {
    final raw = supplier.location.trim();
    if (raw.isEmpty) return 'Caraga Region';

    final parts = raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => part.toLowerCase() != 'caraga region')
        .toList();

    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}, ${parts.last}';
    }
    return parts.isEmpty ? raw : parts.last;
  }

  String get reviewLabel {
    if (supplier.reviews <= 0 || supplier.rating <= 0) {
      return 'No reviews yet';
    }
    final word = supplier.reviews == 1 ? 'review' : 'reviews';
    return '${supplier.rating.toStringAsFixed(1)} · ${supplier.reviews} $word';
  }

  Widget _storePhoto() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD5EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10002A47),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: hasNetworkImage
            ? Image.network(
                supplier.profileImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => SupplierInitial(initial: storeInitial),
              )
            : SupplierInitial(initial: storeInitial),
      ),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF11A87A), size: 11),
          SizedBox(width: 3),
          Text(
            'Verified',
            style: TextStyle(
              color: Color(0xFF0B8D68),
              fontSize: 7.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _newBadge() {
    final remaining = supplier.newSupplierDaysRemaining;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE58A1F), size: 10),
          const SizedBox(width: 3),
          Text(
            'NEW · ${remaining}D',
            style: const TextStyle(
              color: Color(0xFFC96A00),
              fontSize: 7.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _favoriteButton() {
    return Tooltip(
      message: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
      child: Material(
        color: isFavorite ? const Color(0xFFFFEEF2) : const Color(0xFFF1F6F9),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: favoriteBusy ? null : onFavoriteToggle,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 34,
            height: 34,
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
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? const Color(0xFFE94C72) : const Color(0xFF7690A2),
                      size: 18,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownStore = !showFavoriteAction;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0EBF1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D002A47),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _storePhoto(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplier.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 13.3,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          _verifiedBadge(),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFF7B8FA3), size: 13),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              compactLocation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6D8294),
                                fontSize: 9.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            supplier.reviews > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                            color: supplier.reviews > 0
                                ? const Color(0xFFFFB703)
                                : const Color(0xFF92A4B1),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              reviewLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF667E90),
                                fontSize: 9.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 7),
                            color: const Color(0xFFDDE7ED),
                          ),
                          const Icon(Icons.inventory_2_outlined, color: Color(0xFF087AC0), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '$availableListingCount listing${availableListingCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Color(0xFF087AC0),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (supplier.isNewSupplier) _newBadge(),
                          if (supplier.isNewSupplier) const SizedBox(width: 6),
                          if (ownStore)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F3),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'YOUR STORE',
                                style: TextStyle(
                                  color: Color(0xFF0B8D68),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            ownStore ? 'Open store' : 'View store',
                            style: const TextStyle(
                              color: Color(0xFF087AC0),
                              fontSize: 9.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF087AC0), size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showFavoriteAction) ...[
                  const SizedBox(width: 8),
                  _favoriteButton(),
                ],
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
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF8FC),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF087AC0),
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
