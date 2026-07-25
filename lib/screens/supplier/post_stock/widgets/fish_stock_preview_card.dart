import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockPreviewCard extends StatelessWidget {
  const FishStockPreviewCard({
    super.key,
    required this.productName,
    required this.selectedCategory,
    required this.price,
    required this.selectedUnit,
    required this.productImageUrl,
  });

  final String productName;
  final String selectedCategory;
  final String price;
  final String selectedUnit;
  final String productImageUrl;

  bool get hasImage {
    return productImageUrl.trim().isNotEmpty &&
        (productImageUrl.startsWith('http://') ||
            productImageUrl.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final displayProductName =
        productName.trim().isEmpty ? 'Fish Product' : productName.trim();

    final displayPrice = price.trim().isEmpty ? '0' : price.trim();

    return PostStockSectionCard(
      title: 'Post Preview',
      subtitle: 'Preview of the fish stock card shown to vendors.',
      icon: Icons.visibility,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF146BFF).withAlpha(38),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 56,
                height: 56,
                color: Colors.white,
                child: hasImage
                    ? Image.network(
                        productImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const PreviewImagePlaceholder();
                        },
                      )
                    : const PreviewImagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedCategory,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱$displayPrice per $selectedUnit',
                    style: const TextStyle(
                      color: Color(0xFF146BFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF146BFF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewImagePlaceholder extends StatelessWidget {
  const PreviewImagePlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        color: Color(0xFF146BFF),
        size: 28,
      ),
    );
  }
}
