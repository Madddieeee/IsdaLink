import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class RecommendedSupplierCard
    extends
        StatelessWidget {
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
    final FishProduct? firstProduct = supplier.products.isNotEmpty
        ? supplier.products.first
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 185,
        margin: const EdgeInsets.only(
          right: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x14000000,
              ),
              blurRadius: 16,
              offset: Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    22,
                  ),
                ),
                gradient: LinearGradient(
                  colors: [
                    Color(
                      0xFF146BFF,
                    ),
                    Color(
                      0xFF00B4D8,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          31,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: -22,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEAF7FB,
                        ),
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          firstProduct?.emoji ??
                              '🐟',
                          style: const TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          46,
                        ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: const Text(
                        'TOP RATED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 28,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Text(
                supplier.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 13,
                    color: Color(
                      0xFF7B8FA3,
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Expanded(
                    child: Text(
                      supplier.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(
                      0xFFFFB703,
                    ),
                    size: 15,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    '${supplier.rating}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(
                        0xFF102C44,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
                      '(${supplier.reviews} reviews)',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(
                          0xFF7B8FA3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 14,
            ),
          ],
        ),
      ),
    );
  }
}
