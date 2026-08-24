import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/services/stock_notification_service.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_state.dart';

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

  StockNotificationService get stockNotificationService =>
      const StockNotificationService();

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
    return StockState.isIntentionallyHidden(data);
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

  Future<double> restockProduct({
    required String documentId,
    required double quantityToAdd,
  }) async {
    if (quantityToAdd <= 0) {
      throw ArgumentError.value(
        quantityToAdd,
        'quantityToAdd',
        'Restock quantity must be greater than zero.',
      );
    }

    final reference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(documentId);

    return FirebaseFirestore.instance.runTransaction<double>(
      (transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw Exception('This fish listing no longer exists.');
        }

        final currentData = snapshot.data() ?? <String, dynamic>{};

        if (isHidden(currentData) || currentData['archived'] == true) {
          throw StateError(
            'Show or restore this listing before restocking it.',
          );
        }

        final currentQuantity = OrderHelpers.getDoubleValue(
          currentData,
          'quantity',
        ).clamp(0, double.infinity).toDouble();
        final nextQuantity = currentQuantity + quantityToAdd;
        var lowStockPercentage = OrderHelpers.getDoubleValue(
          currentData,
          'lowStockPercentage',
        );

        if (lowStockPercentage <= 0) {
          final referenceQuantity = OrderHelpers.getDoubleValue(
            currentData,
            'referenceStockQuantity',
          );
          final savedLowStockLevel = OrderHelpers.getDoubleValue(
            currentData,
            'lowStockLevel',
          );

          lowStockPercentage = referenceQuantity > 0
              ? savedLowStockLevel / referenceQuantity * 100
              : 20;
        }

        final safePercentage =
            lowStockPercentage.clamp(1, 100).toDouble();
        final lowStockLevel = nextQuantity * safePercentage / 100;
        final stockTransition = stockNotificationService.transitionFor(
          stockData: currentData,
          nextQuantity: nextQuantity,
          lowStockLevelOverride: lowStockLevel,
          hiddenOverride: false,
        );
        final stockStatus = StockState.calculatedStockStatus(
          currentData,
          quantityOverride: nextQuantity,
          lowStockLevelOverride: lowStockLevel,
          hiddenOverride: false,
        );

        transaction.update(
          reference,
          {
            'quantity': nextQuantity,
            'referenceStockQuantity': nextQuantity,
            'lowStockPercentage': safePercentage,
            'lowStockLevel': lowStockLevel,
            'status': 'available',
            'isActive': true,
            'stockStatus': stockStatus,
            'restockedAt': FieldValue.serverTimestamp(),
            ...stockTransition.markerFields(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        stockNotificationService.createNotificationInTransaction(
          transaction: transaction,
          stockReference: reference,
          stockData: currentData,
          nextQuantity: nextQuantity,
          transition: stockTransition,
          lowStockLevelOverride: lowStockLevel,
        );

        return nextQuantity;
      },
    );
  }

  Future<void> updateProduct({
    required String documentId,
    required SupplierProductUpdateInput input,
  }) async {
    final reference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(documentId);

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw Exception(
            'This fish listing no longer exists.',
          );
        }

        final currentData =
            snapshot.data() ?? <String, dynamic>{};

        final hidden = isHidden(currentData);
        final lowStockLevel = input.lowStockLevel;

        final stockTransition = stockNotificationService.transitionFor(
          stockData: currentData,
          nextQuantity: input.quantity,
          lowStockLevelOverride: lowStockLevel,
          hiddenOverride: hidden,
        );

        final stockStatus = StockState.calculatedStockStatus(
          currentData,
          quantityOverride: input.quantity,
          lowStockLevelOverride: lowStockLevel,
          hiddenOverride: hidden,
        );
        final previousQuantity = OrderHelpers.getDoubleValue(
          currentData,
          'quantity',
        );
        final wasRestocked = !hidden && input.quantity > previousQuantity;

        transaction.update(
          reference,
          {
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
            'status': hidden ? 'unavailable' : 'available',
            'isActive': !hidden,
            'stockStatus': stockStatus,
            if (wasRestocked)
              'restockedAt': FieldValue.serverTimestamp(),
            ...stockTransition.markerFields(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        stockNotificationService.createNotificationInTransaction(
          transaction: transaction,
          stockReference: reference,
          stockData: currentData,
          nextQuantity: input.quantity,
          transition: stockTransition,
          productNameOverride: input.productName,
          quantityUnitOverride: input.unit,
          lowStockLevelOverride: lowStockLevel,
        );
      },
    );
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
    final makeActive = currentlyHidden;
    final newStatus = makeActive ? 'available' : 'unavailable';

    await reference.update({
      ...StockState.fieldsForVisibility(
        data,
        active: makeActive,
      ),
      if (makeActive && data['archived'] == true) ...{
        'archived': false,
        'restoredFromArchiveAt':
            FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newStatus;
  }

  Future<void> archiveProduct(
    String documentId,
  ) async {
    final reference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(documentId);

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw Exception(
        'This fish listing no longer exists.',
      );
    }

    final data =
        snapshot.data() ?? <String, dynamic>{};

    await reference.update({
      ...StockState.fieldsForVisibility(
        data,
        active: false,
      ),
      'archived': true,
      'archivedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}
