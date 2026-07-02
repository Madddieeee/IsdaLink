import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';

class FishProduct {
  final String name;
  final String category;
  final String description;
  final double price;
  final String priceUnit;
  final double availableQuantity;
  final String quantityUnit;
  final double lowStockThreshold;
  final String emoji;

  const FishProduct({
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.priceUnit,
    required this.availableQuantity,
    required this.quantityUnit,
    required this.lowStockThreshold,
    required this.emoji,
  });

  String get stockStatus {
    if (availableQuantity <= 0) {
      return 'Out of Stock';
    } else if (availableQuantity <= lowStockThreshold) {
      return 'Low Stock';
    } else {
      return 'Available';
    }
  }

  Color get stockColor {
    if (availableQuantity <= 0) {
      return AppColors.red;
    } else if (availableQuantity <= lowStockThreshold) {
      return AppColors.orange;
    } else {
      return AppColors.green;
    }
  }
}
