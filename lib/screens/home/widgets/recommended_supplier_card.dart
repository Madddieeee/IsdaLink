import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class RecommendedSupplierCard extends StatelessWidget {
  const RecommendedSupplierCard({
    super.key,
    required this.supplier,
    required this.onTap,
  });

  final Supplier supplier;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final FishProduct? firstProduct =
        supplier.products.isNotEmpty ? supplier.products.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 166,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 13,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(21),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF087AC0),
                    Color(0xFF10B7D4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: -26,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(34),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: -22,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          firstProduct?.emoji ?? '🐟',
                          style: const TextStyle(
                            fontSize: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(48),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                supplier.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 13.5,
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
                    Icons.location_on,
                    size: 13,
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFB703),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${supplier.rating}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      color: Color(0xFF102C44),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '(${supplier.reviews})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7B8FA3),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 17,
                    color: Color(0xFF9AADBC),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }
}
