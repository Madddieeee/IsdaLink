import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';

class RecentFishCard
    extends
        StatelessWidget {
  const RecentFishCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final FishProduct product;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
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
              height: 108,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    22,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(
                      0xFFEAF7FB,
                    ),
                    Color(
                      0xFFCBEAF5,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      product.emoji,
                      style: const TextStyle(
                        fontSize: 54,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF146BFF,
                        ),
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Text(
                        '₱${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    product.priceUnit,
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: product.stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          product.stockStatus,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: product.stockColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
