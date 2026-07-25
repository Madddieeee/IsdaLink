import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';

class RecentFishCard extends StatelessWidget {
  const RecentFishCard({
    super.key,
    required this.product,
    required this.supplierName,
    required this.onTap,
  });

  final FishProduct product;
  final String supplierName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                child: Container(
                  color: const Color(0xFFE6F9FF),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (product.hasImage)
                        Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return FishEmojiFallback(emoji: product.emoji);
                          },
                        )
                      else
                        FishEmojiFallback(emoji: product.emoji),
                      Positioned(
                        right: 9,
                        bottom: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF087AC0),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '₱${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.priceUnit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF087AC0),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: product.stockColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          product.stockStatus,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: product.stockColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF9AADBC), size: 16),
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

class FishEmojiFallback extends StatelessWidget {
  const FishEmojiFallback({super.key, required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -24,
          top: -20,
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(74),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
      ],
    );
  }
}
