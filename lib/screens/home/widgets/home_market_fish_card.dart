import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';

class HomeMarketFishCard extends StatelessWidget {
  const HomeMarketFishCard({
    super.key,
    required this.product,
    required this.supplierName,
    this.supplierImageUrl = '',
    this.isWide = false,
    this.badgeLabel = '',
    this.activityLabel = '',
    required this.onTap,
  });

  final FishProduct product;
  final String supplierName;
  final String supplierImageUrl;
  final String badgeLabel;
  final String activityLabel;
  final bool isWide;
  final VoidCallback onTap;

  String get price => product.price
      .toStringAsFixed(product.price % 1 == 0 ? 0 : 2)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );

  String get cleanPriceUnit {
    final value = product.priceUnit.trim();
    if (value.toLowerCase().startsWith('per ')) {
      return value.substring(4).trim();
    }
    return value.isEmpty ? product.quantityUnit : value;
  }

  String get stockQuantityText {
    final quantity = product.availableQuantity % 1 == 0
        ? product.availableQuantity.toStringAsFixed(0)
        : product.availableQuantity.toStringAsFixed(1);

    if (product.availableQuantity <= 0) {
      return 'Out of stock';
    }

    return '$quantity ${product.quantityUnit} available';
  }

  bool hasNetworkImage(String value) {
    final text = value.trim();
    return text.startsWith('http://') || text.startsWith('https://');
  }

  Widget _arrivalBadge() {
    final label = badgeLabel.trim().toUpperCase();
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final restocked = label == 'RESTOCKED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: restocked ? const Color(0xFF16835F) : const Color(0xFF087AC0),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        restocked ? 'RESTOCKED' : 'NEW',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.8,
          letterSpacing: .2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _stockBadge() {
    final lowStock =
        product.availableQuantity > 0 &&
        product.availableQuantity <= product.lowStockThreshold;
    final outOfStock = product.availableQuantity <= 0;
    final label = outOfStock
        ? 'OUT OF STOCK'
        : lowStock
        ? 'LOW STOCK'
        : 'AVAILABLE';

    final background = outOfStock
        ? const Color(0xFFE45D5D)
        : lowStock
        ? const Color(0xFFF2A33A)
        : const Color(0xFF2DAA7A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.4,
          letterSpacing: .15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _supplierAvatar() {
    final imageUrl = supplierImageUrl.trim();

    return Container(
      width: 20,
      height: 20,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8F5FC),
        border: Border.all(color: const Color(0xFFB8E1EF)),
      ),
      child: hasNetworkImage(imageUrl)
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => const Icon(
                Icons.storefront_outlined,
                color: Color(0xFF087AC0),
                size: 11,
              ),
            )
          : const Icon(
              Icons.storefront_outlined,
              color: Color(0xFF087AC0),
              size: 11,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBE5F0), width: 1.15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18002A43),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 116,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.hasImage)
                      Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => _placeholder(),
                      )
                    else
                      _placeholder(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x10000000),
                            Color(0x6100192B),
                          ],
                          stops: [0.45, 0.72, 1.0],
                        ),
                      ),
                    ),
                    if (badgeLabel.trim().isNotEmpty)
                      Positioned(top: 8, left: 8, child: _arrivalBadge()),
                    Positioned(top: 8, right: 8, child: _stockBadge()),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102D48),
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱$price',
                            style: const TextStyle(
                              color: Color(0xFF007FB5),
                              fontSize: 15.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              '/ $cleanPriceUnit',
                              style: const TextStyle(
                                color: Color(0xFF6D8799),
                                fontSize: 8.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _supplierAvatar(),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              supplierName.trim().isEmpty
                                  ? 'Verified Supplier'
                                  : supplierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF48677B),
                                fontSize: 9.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: product.stockColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stockQuantityText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.8,
                                color: product.stockColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF008DC0),
                            size: 18,
                          ),
                        ],
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

  Widget _placeholder() => Container(
    color: const Color(0xFFDDF3FC),
    alignment: Alignment.center,
    child: Text(product.emoji, style: const TextStyle(fontSize: 38)),
  );
}
