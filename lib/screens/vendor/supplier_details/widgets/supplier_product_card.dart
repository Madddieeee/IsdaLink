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

    return value.startsWith('http://') ||
        value.startsWith('https://');
  }

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
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
      height: 104,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: hasNetworkImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const ProductImagePlaceholder(
                    emoji: '🐟',
                    loading: true,
                  );
                },
                errorBuilder: (_, __, ___) {
                  return ProductImagePlaceholder(
                    emoji: emoji,
                  );
                },
              )
            : ProductImagePlaceholder(
                emoji: emoji,
              ),
      ),
    );
  }

  Widget stockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
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
        stockStatus,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.6,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE0EEF5),
            ),
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
                  Positioned(
                    left: 9,
                    top: 9,
                    child: stockBadge(),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 13.1,
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
                            fontSize: 9.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Text(
                        '₱${formatNumber(price)} / $cleanPriceUnit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF087AC0),
                          fontSize: 13.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: stockColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${formatNumber(quantity)} '
                              '$quantityUnit available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF62798B),
                                fontSize: 8.9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        height: 29,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8FD),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View details',
                              style: TextStyle(
                                color: Color(0xFF087AC0),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF087AC0),
                              size: 13,
                            ),
                          ],
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFEAF7FB),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : Text(
              emoji,
              style: const TextStyle(
                fontSize: 44,
              ),
            ),
    );
  }
}
