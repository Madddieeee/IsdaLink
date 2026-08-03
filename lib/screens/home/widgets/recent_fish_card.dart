import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';

class RecentFishCard extends StatelessWidget {
  const RecentFishCard({
    super.key,
    required this.product,
    required this.supplierName,
    required this.onTap,
    this.isWide = false,
  });

  final FishProduct product;
  final String supplierName;
  final VoidCallback onTap;
  final bool isWide;

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

  bool hasNetworkImage(
    String value,
  ) {
    final text = value.trim();

    return text.startsWith('http://') ||
        text.startsWith('https://');
  }

  Widget productPhoto() {
    if (product.hasImage &&
        hasNetworkImage(product.imageUrl)) {
      return Image.network(
        product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return FishEmojiFallback(
            emoji: product.emoji,
          );
        },
      );
    }

    return FishEmojiFallback(
      emoji: product.emoji,
    );
  }

  Widget productNamePill(
    String displayName,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isWide ? 190 : 118,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(226),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF102C44),
          fontSize: 10.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget pricePill() {
    return Container(
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
          fontSize: 10.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget supplierPill(
    String displaySupplier,
  ) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(224),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: Color(0xFF0A73D8),
              size: 11,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displaySupplier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF52677A),
                  fontSize: 8.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget stockPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(224),
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
          const SizedBox(width: 4),
          Text(
            '${formatNumber(product.availableQuantity)} '
            '${product.quantityUnit}',
            style: TextStyle(
              color: product.stockColor,
              fontSize: 8.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget imageCard({
    required String displayName,
    required String displaySupplier,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: const Color(0xFFE6F9FF),
        ),
        productPhoto(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00000000),
                Color(0x12000000),
                Color(0x52001529),
              ],
              stops: [
                0.35,
                0.66,
                1,
              ],
            ),
          ),
        ),
        Positioned(
          left: 9,
          top: 9,
          child: productNamePill(
            displayName,
          ),
        ),
        Positioned(
          right: 9,
          top: 9,
          child: pricePill(),
        ),
        Positioned(
          left: 9,
          right: 9,
          bottom: 9,
          child: Row(
            children: [
              supplierPill(
                displaySupplier,
              ),
              const SizedBox(width: 6),
              stockPill(),
            ],
          ),
        ),
      ],
    );
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

    return Material(
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
              color: const Color(0xFFE1EEF6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 13,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: imageCard(
              displayName: displayName,
              displaySupplier: displaySupplier,
            ),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6F9FF),
            Color(0xFFBFEAF5),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji.trim().isEmpty ? '🐟' : emoji,
        style: TextStyle(
          fontSize: 48,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(24),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}
