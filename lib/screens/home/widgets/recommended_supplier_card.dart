import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';

class RecommendedSupplierCard extends StatelessWidget {
  const RecommendedSupplierCard({
    super.key,
    required this.supplier,
    required this.onTap,
  });

  final Supplier supplier;
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

  String get reviewLabel {
    if (supplier.reviews <= 0 || supplier.rating <= 0) {
      return 'No reviews yet';
    }

    return '${supplier.rating.toStringAsFixed(1)} (${supplier.reviews})';
  }

  Widget buildStorePhoto() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FD),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20002842),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
                      width: 17,
                      height: 17,
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
                  return StoreInitial(
                    initial: storeInitial,
                  );
                },
              )
            : StoreInitial(
                initial: storeInitial,
              ),
      ),
    );
  }

  Widget verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withAlpha(28),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: 11,
          ),
          SizedBox(width: 3),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget newSupplierBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7A24B),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2AE8892D),
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
            size: 10,
          ),
          const SizedBox(width: 3),
          Text(
            'NEW • ${supplier.newSupplierDaysRemaining}D',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFDCECF2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12002842),
                  blurRadius: 13,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 69,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(21),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF073B66),
                              Color(0xFF0A73D8),
                              Color(0xFF12B6D6),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -18,
                        top: -27,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(22),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: -20,
                        child: buildStorePhoto(),
                      ),
                      Positioned(
                        right: 9,
                        top: 9,
                        child: verifiedBadge(),
                      ),
                      if (supplier.isNewSupplier)
                        Positioned(
                          left: 9,
                          top: 9,
                          child: newSupplierBadge(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    supplier.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF13354B),
                      fontSize: 13.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Color(0xFF6B8CA3),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          supplier.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B8CA3),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        supplier.reviews > 0
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF7A24B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reviewLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF13354B),
                            fontSize: 10.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8FD),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'COD',
                          style: TextStyle(
                            color: Color(0xFF0A73D8),
                            fontSize: 8.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Container(
                    height: 31,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE8F8FD),
                          Color(0xFFF4FBFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: Color(0xFF0A73D8),
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'View store',
                          style: TextStyle(
                            color: Color(0xFF0A73D8),
                            fontSize: 9.7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF0A73D8),
                          size: 10,
                        ),
                      ],
                    ),
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

class StoreInitial extends StatelessWidget {
  const StoreInitial({
    super.key,
    required this.initial,
  });

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F8FD),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF0A73D8),
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
