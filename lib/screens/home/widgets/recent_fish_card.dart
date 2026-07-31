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

  String cleanText({
    required String value,
    required String fallback,
  }) {
    final text = value.trim();

    if (text.isEmpty) {
      return fallback;
    }

    final lowerText = text.toLowerCase();

    if (lowerText == 'test' ||
        lowerText == 'testing' ||
        lowerText == 'asdw' ||
        lowerText == 'asdf') {
      return fallback;
    }

    return text;
  }

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayName = cleanText(
      value: product.name,
      fallback: 'Fresh Fish Stock',
    );

    final displaySupplier = cleanText(
      value: supplierName,
      fallback: 'Verified Supplier',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE1EEF6),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (product.hasImage)
                Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return FishEmojiFallback(
                      emoji: product.emoji,
                    );
                  },
                )
              else
                FishEmojiFallback(
                  emoji: product.emoji,
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(2),
                      Colors.black.withAlpha(120),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 9,
                top: 9,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 116,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(205),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 9,
                bottom: 9,
                right: 82,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(185),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withAlpha(70),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        color: Color(0xFF087AC0),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displaySupplier,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 9.7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 9,
                bottom: 9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF087AC0),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '₱${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: product.stockColor,
                            size: 7,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${formatNumber(product.availableQuantity)} ${product.quantityUnit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: product.stockColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FishEmojiFallback extends StatelessWidget {
  const FishEmojiFallback({
    super.key,
    required this.emoji,
  });

  final String emoji;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: const Color(0xFFE6F9FF),
        ),
        Positioned(
          right: -24,
          top: -22,
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(78),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Center(
          child: Text(
            emoji.trim().isEmpty ? '🐟' : emoji,
            style: const TextStyle(
              fontSize: 48,
            ),
          ),
        ),
      ],
    );
  }
}
