import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockPreviewCard
    extends
        StatelessWidget {
  const FishStockPreviewCard({
    super.key,
    required this.selectedEmoji,
    required this.productName,
    required this.selectedCategory,
    required this.price,
    required this.selectedUnit,
  });

  final String selectedEmoji;
  final String productName;
  final String selectedCategory;
  final String price;
  final String selectedUnit;

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayProductName = productName.trim().isEmpty
        ? 'Fish Product'
        : productName.trim();

    final displayPrice = price.trim().isEmpty
        ? '0'
        : price.trim();

    return PostStockSectionCard(
      title: 'Post Preview',
      subtitle: 'Sample preview of how vendors may see this stock.',
      icon: Icons.visibility,
      child: Container(
        padding: const EdgeInsets.all(
          15,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFEAF7FB,
          ),
          borderRadius: BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color:
                const Color(
                  0xFF146BFF,
                ).withAlpha(
                  42,
                ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: Center(
                child: Text(
                  selectedEmoji,
                  style: const TextStyle(
                    fontSize: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 13,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayProductName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    selectedCategory,
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  Text(
                    '₱$displayPrice per $selectedUnit',
                    style: const TextStyle(
                      color: Color(
                        0xFF146BFF,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.visibility,
              color: Color(
                0xFF146BFF,
              ),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
