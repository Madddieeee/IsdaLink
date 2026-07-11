import 'package:flutter/material.dart';

class StockHelpers {
  const StockHelpers._();

  static Color getStockColor({
    required double quantity,
    required double lowStockLevel,
    required String status,
  }) {
    if (status.toLowerCase() ==
        'unavailable') {
      return const Color(
        0xFF7B8FA3,
      );
    }

    if (quantity <=
        0) {
      return const Color(
        0xFFD32F2F,
      );
    }

    if (quantity <=
        lowStockLevel) {
      return const Color(
        0xFFF57C00,
      );
    }

    return const Color(
      0xFF2E7D32,
    );
  }

  static String getStockStatus({
    required double quantity,
    required double lowStockLevel,
    required String status,
  }) {
    if (status.toLowerCase() ==
        'unavailable') {
      return 'Hidden';
    }

    if (quantity <=
        0) {
      return 'Out of Stock';
    }

    if (quantity <=
        lowStockLevel) {
      return 'Low Stock';
    }

    return 'Available';
  }
}
