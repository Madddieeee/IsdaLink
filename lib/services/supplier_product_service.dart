import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierProductStats {
  const SupplierProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.stockAlertCount,
    required this.hiddenCount,
  });

  final int totalProducts;
  final int activeProducts;
  final int stockAlertCount;
  final int hiddenCount;
}

class SupplierProductUpdateInput {
  const SupplierProductUpdateInput({
    required this.productName,
    required this.description,
    required this.category,
    required this.unit,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.lowStockPercentage,
  });

  final String productName;
  final String description;
  final String category;
  final String unit;
  final String imageUrl;
  final double price;
  final double quantity;
  final double lowStockPercentage;

  double get lowStockLevel {
    final safePercentage =
        lowStockPercentage.clamp(1, 100).toDouble();

    return quantity * safePercentage / 100;
  }
}

class SupplierProductService {
  const SupplierProductService();

  Stream<QuerySnapshot<Map<String, dynamic>>> fishStocksStream(
    String supplierId,
  ) {
    return FirebaseFirestore.instance
        .collection('fishStocks')
        .where(
          'supplierId',
          isEqualTo: supplierId,
        )
        .snapshots();
  }

  bool isHidden(
    Map<String, dynamic> data,
  ) {
    final status = OrderHelpers.getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    final isActive = data['isActive'];

    return status == 'unavailable' || isActive == false;
  }

  String calculatedStockStatus(
    Map<String, dynamic> data,
  ) {
    if (isHidden(data)) {
      return 'hidden';
    }

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );
    final lowStockLevel = OrderHelpers.getDoubleValue(
      data,
      'lowStockLevel',
    );

    if (quantity <= 0) {
      return 'outOfStock';
    }

    if (quantity <= lowStockLevel) {
      return 'lowStock';
    }

    return 'available';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> sortStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final sortedDocuments = [
      ...documents,
    ];

    sortedDocuments.sort(
      (
        first,
        second,
      ) {
        final firstData = first.data();
        final secondData = second.data();

        final firstHidden = isHidden(firstData);
        final secondHidden = isHidden(secondData);

        if (firstHidden != secondHidden) {
          return firstHidden ? 1 : -1;
        }

        final firstStatus = calculatedStockStatus(firstData);
        final secondStatus = calculatedStockStatus(secondData);

        final firstPriority = switch (firstStatus) {
          'outOfStock' => 0,
          'lowStock' => 1,
          'available' => 2,
          _ => 3,
        };

        final secondPriority = switch (secondStatus) {
          'outOfStock' => 0,
          'lowStock' => 1,
          'available' => 2,
          _ => 3,
        };

        if (firstPriority != secondPriority) {
          return firstPriority.compareTo(secondPriority);
        }

        return OrderHelpers.createdAtMillis(
          second,
        ).compareTo(
          OrderHelpers.createdAtMillis(first),
        );
      },
    );

    return sortedDocuments;
  }

  SupplierProductStats calculateStats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    var activeProducts = 0;
    var stockAlertCount = 0;
    var hiddenCount = 0;

    for (final document in documents) {
      final data = document.data();
      final stockStatus = calculatedStockStatus(data);

      if (stockStatus == 'hidden') {
        hiddenCount++;
        continue;
      }

      activeProducts++;

      if (stockStatus == 'lowStock' ||
          stockStatus == 'outOfStock') {
        stockAlertCount++;
      }
    }

    return SupplierProductStats(
      totalProducts: documents.length,
      activeProducts: activeProducts,
      stockAlertCount: stockAlertCount,
      hiddenCount: hiddenCount,
    );
  }

  Future<void> updateProduct({
    required String documentId,
    required SupplierProductUpdateInput input,
  }) async {
    final reference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(documentId);

    final snapshot = await reference.get();
    final currentData = snapshot.data() ?? <String, dynamic>{};

    final hidden = isHidden(currentData);
    final lowStockLevel = input.lowStockLevel;

    final stockStatus = hidden
        ? 'hidden'
        : input.quantity <= 0
            ? 'outOfStock'
            : input.quantity <= lowStockLevel
                ? 'lowStock'
                : 'available';

    await reference.update({
      'productName': input.productName.trim(),
      'description': input.description.trim(),
      'category': input.category,
      'imageUrl': input.imageUrl,
      'productImageUrl': input.imageUrl,
      'price': input.price,
      'priceUnit': 'per ${input.unit}',
      'quantity': input.quantity,
      'quantityUnit': input.unit,
      'referenceStockQuantity': input.quantity,
      'lowStockPercentage':
          input.lowStockPercentage.clamp(1, 100).toDouble(),
      'lowStockLevel': lowStockLevel,
      'lowStockAlertEnabled': true,
      'lowStockNotificationEnabled': true,
      'stockStatus': stockStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> toggleAvailability({
    required String documentId,
  }) async {
    final reference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(documentId);

    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};

    final currentlyHidden = isHidden(data);
    final newStatus =
        currentlyHidden ? 'available' : 'unavailable';

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );
    final lowStockLevel = OrderHelpers.getDoubleValue(
      data,
      'lowStockLevel',
    );

    final stockStatus = newStatus == 'unavailable'
        ? 'hidden'
        : quantity <= 0
            ? 'outOfStock'
            : quantity <= lowStockLevel
                ? 'lowStock'
                : 'available';

    await reference.update({
      'status': newStatus,
      'isActive': newStatus == 'available',
      'stockStatus': stockStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newStatus;
  }

  Future<void> deleteProduct(
    String documentId,
  ) async {
    await FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(documentId)
        .delete();
  }
}
