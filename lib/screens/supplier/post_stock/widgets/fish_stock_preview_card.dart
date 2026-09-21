import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockPreviewCard extends StatelessWidget {
  const FishStockPreviewCard({
    super.key,
    required this.productName,
    required this.selectedCategory,
    required this.selectedUnit,
    required this.price,
    required this.quantity,
    required this.lowStockLevel,
    this.selectedImage,
    this.uploadedImageUrl = '',
  });

  final String productName;
  final String selectedCategory;
  final String selectedUnit;
  final String price;
  final String quantity;
  final String lowStockLevel;
  final XFile? selectedImage;
  final String uploadedImageUrl;

  String get displayProductName {
    final value = productName.trim();
    return value.isEmpty ? 'Product name not set' : value;
  }

  String? get validPrice {
    final parsed = double.tryParse(price.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2);
  }

  String? get validQuantity {
    final parsed = double.tryParse(quantity.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(1);
  }

  String? get validAlertLevel {
    final parsed = double.tryParse(lowStockLevel.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(1);
  }

  bool get hasLocalImage => selectedImage != null;
  bool get hasUploadedImage => uploadedImageUrl.trim().isNotEmpty;

  Widget productVisual() {
    if (hasLocalImage) {
      return Image.file(File(selectedImage!.path), fit: BoxFit.cover);
    }

    if (hasUploadedImage) {
      return Image.network(
        uploadedImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PhotoPlaceholderVisual(),
      );
    }

    return const _PhotoPlaceholderVisual();
  }

  @override
  Widget build(BuildContext context) {
    final priceText = validPrice == null
        ? 'Price not set'
        : '₱$validPrice / $selectedUnit';
    final stockText = validQuantity == null
        ? 'Stock not set'
        : '$validQuantity $selectedUnit available';

    return PostStockSectionCard(
      title: 'Marketplace Preview',
      subtitle: 'See how the listing will appear to vendors.',
      icon: Icons.visibility_outlined,
      badge: 'FINAL CHECK',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE8EF)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: productVisual(),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayProductName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF102C44),
                            fontSize: 13.2,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            fontStyle: productName.trim().isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              color: Color(0xFF0875D1),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                selectedCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF657C8E),
                                  fontSize: 9.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          priceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: validPrice == null
                                ? const Color(0xFF8BA0B1)
                                : const Color(0xFF0875D1),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stockText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 9.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PreviewMetric(
                    icon: Icons.scale_outlined,
                    label: 'UNIT',
                    value: 'per $selectedUnit',
                    complete: true,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _PreviewMetric(
                    icon: Icons.inventory_2_outlined,
                    label: 'AVAILABLE',
                    value: validQuantity == null
                        ? 'Not set'
                        : '$validQuantity $selectedUnit',
                    complete: validQuantity != null,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _PreviewMetric(
                    icon: Icons.notifications_active_outlined,
                    label: 'ALERT AT',
                    value: validAlertLevel == null
                        ? 'Pending'
                        : '$validAlertLevel $selectedUnit',
                    complete: validAlertLevel != null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholderVisual extends StatelessWidget {
  const _PhotoPlaceholderVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4F5FC), Color(0xFFCDEAF6)],
        ),
      ),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        color: Color(0xFF146BFF),
        size: 34,
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.complete,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: complete ? const Color(0xFF146BFF) : const Color(0xFF9AAEBC),
            size: 16,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF8BA0B1),
              fontSize: 7,
              letterSpacing: 0.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: complete
                  ? const Color(0xFF102C44)
                  : const Color(0xFF8BA0B1),
              fontSize: 8.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
