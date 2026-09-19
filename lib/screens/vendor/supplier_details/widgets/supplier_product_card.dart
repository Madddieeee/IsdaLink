import 'package:flutter/material.dart';

class SupplierProductCard extends StatelessWidget {
  const SupplierProductCard({
    super.key,
    required this.productName,
    required this.category,
    required this.emoji,
    required this.imageUrl,
    required this.price,
    required this.priceUnit,
    required this.quantity,
    required this.quantityUnit,
    required this.stockColor,
    required this.stockStatus,
    required this.onTap,
  });

  final String productName;
  final String category;
  final String emoji;
  final String imageUrl;
  final double price;
  final String priceUnit;
  final double quantity;
  final String quantityUnit;
  final Color stockColor;
  final String stockStatus;
  final VoidCallback onTap;

  bool get hasNetworkImage {
    final value = imageUrl.trim();

    return value.startsWith('http://') || value.startsWith('https://');
  }

  String formatNumber(double value) {
    final raw = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final parts = raw.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return parts.length == 2
        ? '${buffer.toString()}.${parts[1]}'
        : buffer.toString();
  }

  String get cleanPriceUnit {
    final value = priceUnit.trim().toLowerCase();

    if (value.startsWith('per ')) {
      return value.substring(4);
    }

    return value.isEmpty ? quantityUnit : value;
  }

  bool get showCategory {
    final value = category.trim().toLowerCase();
    return value.isNotEmpty && value != 'fresh fish';
  }

  Widget productImage() {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
        child: hasNetworkImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const ProductImagePlaceholder(
                    emoji: '🐟',
                    loading: true,
                  );
                },
                errorBuilder: (_, _, _) {
                  return ProductImagePlaceholder(emoji: emoji);
                },
              )
            : ProductImagePlaceholder(emoji: emoji),
      ),
    );
  }

  Widget stockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: stockColor.withAlpha(236),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        stockStatus.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE0EEF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  productImage(),
                  Positioned(right: 9, top: 9, child: stockBadge()),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 7, 8, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 12.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (showCategory) ...[
                              const SizedBox(height: 2),
                              Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF7B8FA3),
                                  fontSize: 8.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '₱${formatNumber(price)} / $cleanPriceUnit',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF087AC0),
                                fontSize: 12.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: stockColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${formatNumber(quantity)} $quantityUnit available',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF52677A),
                                      fontSize: 8.4,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5FBFE),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDCECF4)),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF087AC0),
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
    required this.emoji,
    this.loading = false,
  });

  final String emoji;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF7FB),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(emoji, style: const TextStyle(fontSize: 44)),
    );
  }
}
