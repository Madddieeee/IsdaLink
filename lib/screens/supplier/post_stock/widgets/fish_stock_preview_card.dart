import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockPreviewCard extends StatelessWidget {
  const FishStockPreviewCard({
    super.key,
    required this.productName,
    required this.selectedCategory,
    required this.selectedUnit,
    this.selectedEmoji = '🐟',
    this.price = '',
    this.priceText = '',
  });

  final String productName;
  final String selectedCategory;
  final String selectedUnit;
  final String selectedEmoji;

  // Supports both constructor names used by earlier IsdaLink versions.
  final String price;
  final String priceText;

  String get displayPrice {
    final currentPrice = price.trim();

    if (currentPrice.isNotEmpty) {
      return currentPrice;
    }

    final legacyPrice = priceText.trim();

    if (legacyPrice.isNotEmpty) {
      return legacyPrice;
    }

    return '0';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayProductName = productName.trim().isEmpty
        ? 'Fish Product'
        : productName.trim();

    final emoji = selectedEmoji.trim().isEmpty
        ? '🐟'
        : selectedEmoji;

    return PostStockSectionCard(
      title: 'Post Preview',
      subtitle: 'Preview how vendors may see this fish stock.',
      icon: Icons.visibility_outlined,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF146BFF).withAlpha(42),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C00152A),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayProductName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedCategory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '₱$displayPrice per $selectedUnit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF146BFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF146BFF),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}
