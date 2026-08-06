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

    return value.isEmpty
        ? 'Product name not set'
        : value;
  }

  String? get validPrice {
    final parsed = double.tryParse(price.trim());

    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2);
  }

  String? get validQuantity {
    final parsed = double.tryParse(quantity.trim());

    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(1);
  }

  String? get validAlertLevel {
    final parsed = double.tryParse(
      lowStockLevel.trim(),
    );

    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed % 1 == 0
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(1);
  }

  bool get hasLocalImage => selectedImage != null;
  bool get hasUploadedImage =>
      uploadedImageUrl.trim().isNotEmpty;
  bool get hasImage => hasLocalImage || hasUploadedImage;

  Widget productVisual() {
    if (hasLocalImage) {
      return Image.file(
        File(selectedImage!.path),
        fit: BoxFit.cover,
      );
    }

    if (hasUploadedImage) {
      return Image.network(
        uploadedImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const _PhotoPlaceholderVisual();
        },
      );
    }

    return const _PhotoPlaceholderVisual();
  }

  @override
  Widget build(BuildContext context) {
    return PostStockSectionCard(
      title: 'Marketplace Preview',
      subtitle: 'Confirm how the listing will appear to vendors.',
      icon: Icons.visibility_outlined,
      badge: 'FINAL CHECK',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F7FB),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: const Color(0xFFDDE8EF),
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 146,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    productVisual(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xB0001727),
                          ],
                          stops: [
                            0.48,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13,
                      right: 13,
                      bottom: 12,
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayProductName,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    fontStyle:
                                        productName.trim().isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selectedCategory,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFDDEFFA),
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                              maxWidth: 112,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(99),
                            ),
                            child: Text(
                              validPrice == null
                                  ? 'Price not set'
                                  : '₱$validPrice',
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                color: validPrice == null
                                    ? const Color(0xFF7B8FA3)
                                    : const Color(0xFF0875D1),
                                fontSize: 9.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                13,
                12,
                13,
                13,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _PreviewMetric(
                      icon: Icons.scale_outlined,
                      label: 'SELLING UNIT',
                      value: 'per $selectedUnit',
                      complete: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PreviewMetric(
                      icon: Icons.inventory_2_outlined,
                      label: 'AVAILABLE',
                      value: validQuantity == null
                          ? 'Stock not set'
                          : '$validQuantity $selectedUnit',
                      complete: validQuantity != null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PreviewMetric(
                      icon:
                          Icons.notifications_active_outlined,
                      label: 'ALERT AT',
                      value: validAlertLevel == null
                          ? 'Alert pending'
                          : '$validAlertLevel $selectedUnit',
                      complete: validAlertLevel != null,
                    ),
                  ),
                ],
              ),
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
          colors: [
            Color(0xFFE4F5FC),
            Color(0xFFCDEAF6),
          ],
        ),
      ),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        color: Color(0xFF146BFF),
        size: 44,
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
      padding: const EdgeInsets.fromLTRB(
        7,
        9,
        7,
        9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: complete
                ? const Color(0xFF146BFF)
                : const Color(0xFF9AAEBC),
            size: 17,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8BA0B1),
              fontSize: 7.2,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: complete
                  ? const Color(0xFF102C44)
                  : const Color(0xFF8BA0B1),
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
