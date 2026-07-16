import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class SupplierDetailsStats {
  const SupplierDetailsStats({
    required this.totalProducts,
    required this.availableProducts,
    required this.lowStockProducts,
    required this.firstEmoji,
  });

  final int totalProducts;
  final int availableProducts;
  final int lowStockProducts;
  final String firstEmoji;
}

class SupplierDetailsService {
  const SupplierDetailsService();

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get fishStocksStream {
    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  String getStringValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value ==
        null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  double getDoubleValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value.toDouble();
    }

    if (value
        is double) {
      return value;
    }

    if (value
        is String) {
      return double.tryParse(
            value,
          ) ??
          0;
    }

    return 0;
  }

  bool matchesSelectedSupplier({
    required Map<
      String,
      dynamic
    >
    data,
    required Supplier supplier,
    required String? supplierId,
  }) {
    final stockSupplierId = getStringValue(
      data,
      'supplierId',
      '',
    );

    final stockSupplierName = getStringValue(
      data,
      'supplierName',
      '',
    ).toLowerCase();

    final selectedSupplierName = supplier.name.toLowerCase();

    final hasMatchingId =
        supplierId !=
            null &&
        supplierId.trim().isNotEmpty &&
        stockSupplierId ==
            supplierId;

    final hasMatchingName =
        stockSupplierName ==
        selectedSupplierName;

    return hasMatchingId ||
        hasMatchingName;
  }

  bool isVisibleStock(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final status = getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    return status ==
            'available' ||
        status ==
            'active';
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  filterSupplierStocks({
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
    required Supplier supplier,
    required String? supplierId,
  }) {
    return documents.where(
      (
        document,
      ) {
        final data = document.data();

        return matchesSelectedSupplier(
              data: data,
              supplier: supplier,
              supplierId: supplierId,
            ) &&
            isVisibleStock(
              data,
            );
      },
    ).toList();
  }

  Color getStockColor({
    required double quantity,
    required double lowStockLevel,
  }) {
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

  String getStockStatus({
    required double quantity,
    required double lowStockLevel,
  }) {
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

  FishProduct fishProductFromFirestore(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return FishProduct(
      name: getStringValue(
        data,
        'productName',
        'Fish Product',
      ),
      category: getStringValue(
        data,
        'category',
        'Fresh Fish',
      ),
      description: getStringValue(
        data,
        'description',
        'Fresh fish stock available for vendor orders.',
      ),
      emoji: getStringValue(
        data,
        'emoji',
        '🐟',
      ),
      price: getDoubleValue(
        data,
        'price',
      ),
      priceUnit: getStringValue(
        data,
        'priceUnit',
        'per kilo',
      ),
      availableQuantity: getDoubleValue(
        data,
        'quantity',
      ),
      quantityUnit: getStringValue(
        data,
        'quantityUnit',
        'kilo',
      ),
      lowStockThreshold: getDoubleValue(
        data,
        'lowStockLevel',
      ),
    );
  }

  SupplierDetailsStats calculateStats(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final availableProducts = documents.where(
      (
        document,
      ) {
        final quantity = getDoubleValue(
          document.data(),
          'quantity',
        );

        return quantity >
            0;
      },
    ).length;

    final lowStockProducts = documents.where(
      (
        document,
      ) {
        final data = document.data();

        final quantity = getDoubleValue(
          data,
          'quantity',
        );

        final lowStockLevel = getDoubleValue(
          data,
          'lowStockLevel',
        );

        return quantity >
                0 &&
            quantity <=
                lowStockLevel;
      },
    ).length;

    final firstEmoji = documents.isNotEmpty
        ? getStringValue(
            documents.first.data(),
            'emoji',
            '🐟',
          )
        : '🐟';

    return SupplierDetailsStats(
      totalProducts: documents.length,
      availableProducts: availableProducts,
      lowStockProducts: lowStockProducts,
      firstEmoji: firstEmoji,
    );
  }
}
