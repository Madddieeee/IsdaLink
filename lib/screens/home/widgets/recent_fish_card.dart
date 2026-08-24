import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';

class RecentFishCard extends StatelessWidget {
  const RecentFishCard({
    super.key,
    required this.product,
    required this.supplierName,
    this.supplierImageUrl = '',
    required this.onTap,
    this.isWide = false,
    this.badgeLabel = '',
    this.activityLabel = '',
    this.showActivityTime = false,
  });

  final FishProduct product;
  final String supplierName;
  final String supplierImageUrl;
  final VoidCallback onTap;
  final bool isWide;
  final String badgeLabel;
  final String activityLabel;
  final bool showActivityTime;

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

  String formatNumber(double value) {
    final rawValue = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final parts = rawValue.split('.');
    final groupedWhole = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );

    if (parts.length == 1) {
      return groupedWhole;
    }

    return '$groupedWhole.${parts.last}';
  }

  bool hasNetworkImage(String value) {
    final text = value.trim();
    return text.startsWith('http://') || text.startsWith('https://');
  }

  String priceUnitLabel() {
    final savedUnit = product.priceUnit.trim();

    if (savedUnit.toLowerCase().startsWith('per ')) {
      return savedUnit.substring(4).trim();
    }

    if (savedUnit.isNotEmpty) {
      return savedUnit;
    }

    return product.quantityUnit;
  }

  String activityTimeText() {
    return activityLabel
        .trim()
        .replaceFirst(RegExp(r'^Posted\s+'), '')
        .replaceFirst(RegExp(r'^Restocked\s+'), '');
  }

  Widget productPhoto() {
    if (product.hasImage && hasNetworkImage(product.imageUrl)) {
      return Image.network(
        product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return FishEmojiFallback(emoji: product.emoji);
        },
      );
    }

    return FishEmojiFallback(emoji: product.emoji);
  }

  Widget arrivalBadge() {
    final badge = badgeLabel.trim().toUpperCase();

    if (badge.isEmpty) {
      return const SizedBox.shrink();
    }

    final isRestocked = badge == 'RESTOCKED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isRestocked
            ? const Color(0xFF16835F)
            : const Color(0xFF0A73D8),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRestocked ? Icons.refresh_rounded : Icons.fiber_new_rounded,
            color: Colors.white,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            isRestocked ? 'RESTOCKED' : 'NEW',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              letterSpacing: 0.25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget photoArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFFE6F9FF)),
        productPhoto(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00000000),
                Color(0x08000000),
                Color(0x28001529),
              ],
              stops: [0.48, 0.72, 1],
            ),
          ),
        ),
        if (badgeLabel.trim().isNotEmpty)
          Positioned(
            left: 9,
            top: 9,
            child: arrivalBadge(),
          ),
      ],
    );
  }

  Widget supplierAvatarFallback() {
    return Container(
      color: const Color(0xFFE8F5FC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.storefront_outlined,
        color: Color(0xFF0A73D8),
        size: 11,
      ),
    );
  }

  Widget supplierAvatar() {
    final imageUrl = supplierImageUrl.trim();

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF9EDCF2),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasNetworkImage(imageUrl)
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return supplierAvatarFallback();
              },
            )
          : supplierAvatarFallback(),
    );
  }

  Widget supplierLine(String displaySupplier) {
    return Row(
      children: [
        supplierAvatar(),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            displaySupplier,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF405E73),
              fontSize: 9.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget stockAndTimeLine() {
    final timeText = activityTimeText();
    final quantity = formatNumber(product.availableQuantity);
    final stockText = product.availableQuantity <= 0
        ? 'Out of stock'
        : product.availableQuantity <= product.lowStockThreshold
            ? 'Only $quantity ${product.quantityUnit} left'
            : '$quantity ${product.quantityUnit} available';

    return Row(
      children: [
        Icon(
          Icons.circle,
          color: product.stockColor,
          size: 7,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            stockText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: product.stockColor,
              fontSize: 8.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (showActivityTime && timeText.isNotEmpty) ...[
          const SizedBox(width: 5),
          Text(
            timeText,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF91A2AF),
              fontSize: 8.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget informationFooter({
    required String displayName,
    required String displaySupplier,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF3FAFE),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF102C44),
                        fontSize: isWide ? 13.4 : 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${formatNumber(product.price)}',
                      style: const TextStyle(
                        color: Color(0xFF0875D1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'per ${priceUnitLabel()}',
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 7.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            supplierLine(displaySupplier),
            const SizedBox(height: 5),
            stockAndTimeLine(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      borderRadius: BorderRadius.circular(19),
      elevation: 2,
      shadowColor: const Color(0x3000355C),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        splashColor: const Color(0x1F0A73D8),
        highlightColor: const Color(0x0F0A73D8),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: const Color(0xFFD6E6EF),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: photoArea()),
              Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0A73D8),
                      Color(0xFF16BBD2),
                    ],
                  ),
                ),
              ),
              informationFooter(
                displayName: displayName,
                displaySupplier: displaySupplier,
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
  Widget build(BuildContext context) {
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
