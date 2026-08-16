import 'package:isdalink/utils/order_helpers.dart';

class StockState {
  const StockState._();

  static String normalizedStatus(
    Map<String, dynamic> data,
  ) {
    return OrderHelpers.getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();
  }

  static double quantity(
    Map<String, dynamic> data,
  ) {
    return OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );
  }

  static double lowStockLevel(
    Map<String, dynamic> data,
  ) {
    return OrderHelpers.getDoubleValue(
      data,
      'lowStockLevel',
    );
  }

  static bool isIntentionallyHidden(
    Map<String, dynamic> data,
  ) {
    final status = normalizedStatus(data);
    final isActive = data['isActive'];
    final savedStockStatus = OrderHelpers.getStringValue(
      data,
      'stockStatus',
      '',
    ).toLowerCase();

    if (status == 'archived' || status == 'deleted' || status == 'hidden') {
      return true;
    }

    if (isActive == false) {
      return true;
    }

    if (savedStockStatus == 'hidden') {
      return true;
    }

    // Legacy compatibility:
    // Older IsdaLink orders used status=unavailable when quantity reached 0,
    // while intentionally hidden products also used unavailable. When
    // isActive=true, treat the listing as published even if that legacy
    // status remains. If isActive is absent, positive unavailable stock is
    // most safely interpreted as an intentionally hidden legacy listing.
    if (status == 'unavailable' && isActive != true) {
      return quantity(data) > 0;
    }

    return false;
  }

  static String calculatedStockStatus(
    Map<String, dynamic> data, {
    double? quantityOverride,
    double? lowStockLevelOverride,
    bool? hiddenOverride,
  }) {
    final hidden = hiddenOverride ?? isIntentionallyHidden(data);

    if (hidden) {
      return 'hidden';
    }

    final currentQuantity = quantityOverride ?? quantity(data);
    final threshold = lowStockLevelOverride ?? lowStockLevel(data);

    if (currentQuantity <= 0) {
      return 'outOfStock';
    }

    if (threshold > 0 && currentQuantity <= threshold) {
      return 'lowStock';
    }

    return 'available';
  }

  static bool isMarketplaceOrderable(
    Map<String, dynamic> data,
  ) {
    return !isIntentionallyHidden(data) && quantity(data) > 0;
  }

  static Map<String, dynamic> fieldsForQuantity(
    Map<String, dynamic> data, {
    required double quantity,
  }) {
    final hidden = isIntentionallyHidden(data);

    return {
      'quantity': quantity,
      // status/isActive represent supplier visibility. Stock depletion is
      // represented separately by stockStatus, so reaching zero never hides
      // an otherwise published listing.
      'status': hidden ? 'unavailable' : 'available',
      'isActive': !hidden,
      'stockStatus': calculatedStockStatus(
        data,
        quantityOverride: quantity,
        hiddenOverride: hidden,
      ),
    };
  }

  static Map<String, dynamic> fieldsForVisibility(
    Map<String, dynamic> data, {
    required bool active,
  }) {
    return {
      'status': active ? 'available' : 'unavailable',
      'isActive': active,
      'stockStatus': calculatedStockStatus(
        data,
        hiddenOverride: !active,
      ),
    };
  }
}
