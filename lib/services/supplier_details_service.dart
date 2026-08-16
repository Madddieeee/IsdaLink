import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/utils/stock_state.dart';

class SupplierDetailsStats {
  const SupplierDetailsStats({
    required this.totalListings,
    required this.availableListings,
    required this.limitedListings,
  });

  final int totalListings;
  final int availableListings;
  final int limitedListings;
}

class SupplierDetailsService {
  const SupplierDetailsService();

  Stream<QuerySnapshot<Map<String, dynamic>>> get fishStocksStream {
    return FirebaseFirestore.instance
        .collection('fishStocks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String getStringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double getDoubleValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  DateTime? getDateTimeValue(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  String productImageUrl(
    Map<String, dynamic> data,
  ) {
    const keys = [
      'productImageUrl',
      'imageUrl',
      'photoUrl',
      'fishImageUrl',
    ];

    for (final key in keys) {
      final value = getStringValue(data, key, '');

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  bool matchesSelectedSupplier({
    required Map<String, dynamic> data,
    required Supplier supplier,
    required String? supplierId,
  }) {
    final selectedId = supplierId?.trim() ?? '';
    final stockSupplierId = getStringValue(
      data,
      'supplierId',
      '',
    ).trim();

    if (selectedId.isNotEmpty && stockSupplierId == selectedId) {
      return true;
    }

    final stockSupplierName = getStringValue(
      data,
      'supplierName',
      '',
    ).trim().toLowerCase();

    return stockSupplierName == supplier.name.trim().toLowerCase();
  }

  bool isArchivedStock(
    Map<String, dynamic> data,
  ) {
    final status = getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    return status == 'deleted' || status == 'archived';
  }

  bool isOrderableStock(
    Map<String, dynamic> data,
  ) {
    return StockState.isMarketplaceOrderable(data);
  }

  bool isLimitedStock(
    Map<String, dynamic> data,
  ) {
    final quantity = getDoubleValue(data, 'quantity');
    final lowStockLevel = getDoubleValue(data, 'lowStockLevel');

    return quantity > 0 &&
        lowStockLevel > 0 &&
        quantity <= lowStockLevel;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterSupplierStocks({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required Supplier supplier,
    required String? supplierId,
  }) {
    return documents.where(
      (document) {
        final data = document.data();

        return matchesSelectedSupplier(
              data: data,
              supplier: supplier,
              supplierId: supplierId,
            ) &&
            !isArchivedStock(data);
      },
    ).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> orderableStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where(
      (document) => isOrderableStock(document.data()),
    ).toList();
  }

  List<String> availableUnits(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final units = <String>{};

    for (final document in documents) {
      final unit = getStringValue(
        document.data(),
        'quantityUnit',
        'kilo',
      ).trim().toLowerCase();

      if (unit.isNotEmpty) {
        units.add(unit);
      }
    }

    const preferredOrder = [
      'kilo',
      'icebox',
      'tab',
    ];

    final ordered = <String>[];

    for (final preferred in preferredOrder) {
      if (units.remove(preferred)) {
        ordered.add(preferred);
      }
    }

    ordered.addAll(
      units.toList()..sort(),
    );

    return ordered;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterAndSortProducts({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required String query,
    required String selectedUnit,
    required String sortMode,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedUnit = selectedUnit.trim().toLowerCase();

    final filtered = documents.where(
      (document) {
        final data = document.data();

        final productName = getStringValue(
          data,
          'productName',
          '',
        ).toLowerCase();

        final category = getStringValue(
          data,
          'category',
          '',
        ).toLowerCase();

        final description = getStringValue(
          data,
          'description',
          '',
        ).toLowerCase();

        final quantityUnit = getStringValue(
          data,
          'quantityUnit',
          'kilo',
        ).toLowerCase();

        final matchesQuery = normalizedQuery.isEmpty ||
            productName.contains(normalizedQuery) ||
            category.contains(normalizedQuery) ||
            description.contains(normalizedQuery);

        final matchesUnit = normalizedUnit == 'all' ||
            quantityUnit == normalizedUnit;

        return matchesQuery && matchesUnit;
      },
    ).toList();

    filtered.sort(
      (first, second) {
        final firstData = first.data();
        final secondData = second.data();

        switch (sortMode) {
          case 'price_low':
            return getDoubleValue(firstData, 'price').compareTo(
              getDoubleValue(secondData, 'price'),
            );
          case 'price_high':
            return getDoubleValue(secondData, 'price').compareTo(
              getDoubleValue(firstData, 'price'),
            );
          case 'name':
            return getStringValue(
              firstData,
              'productName',
              '',
            ).toLowerCase().compareTo(
                  getStringValue(
                    secondData,
                    'productName',
                    '',
                  ).toLowerCase(),
                );
          case 'latest':
          default:
            final firstDate = getDateTimeValue(firstData['createdAt']);
            final secondDate = getDateTimeValue(secondData['createdAt']);

            if (firstDate == null && secondDate == null) {
              return 0;
            }

            if (firstDate == null) {
              return 1;
            }

            if (secondDate == null) {
              return -1;
            }

            return secondDate.compareTo(firstDate);
        }
      },
    );

    return filtered;
  }

  Color getStockColor({
    required double quantity,
    required double lowStockLevel,
  }) {
    if (quantity <= 0) {
      return const Color(0xFFD32F2F);
    }

    if (lowStockLevel > 0 && quantity <= lowStockLevel) {
      return const Color(0xFFF57C00);
    }

    return const Color(0xFF168A5B);
  }

  String getStockStatus({
    required double quantity,
    required double lowStockLevel,
  }) {
    if (quantity <= 0) {
      return 'Out of stock';
    }

    if (lowStockLevel > 0 && quantity <= lowStockLevel) {
      return 'Limited stock';
    }

    return 'Available';
  }

  FishProduct fishProductFromFirestore(
    Map<String, dynamic> data,
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
        'Fresh fish stock available for COD ordering.',
      ),
      emoji: getStringValue(
        data,
        'emoji',
        '🐟',
      ),
      imageUrl: productImageUrl(data),
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
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final available = documents.where(
      (document) => isOrderableStock(document.data()),
    ).toList();

    final limited = available.where(
      (document) => isLimitedStock(document.data()),
    ).length;

    return SupplierDetailsStats(
      totalListings: documents.length,
      availableListings: available.length,
      limitedListings: limited,
    );
  }
}
