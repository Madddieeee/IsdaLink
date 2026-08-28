import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/utils/stock_state.dart';

void main() {
  group('StockState', () {
    test('marks zero published stock as out of stock, not hidden', () {
      final data = <String, dynamic>{
        'status': 'available',
        'isActive': true,
        'quantity': 0,
        'lowStockLevel': 5,
      };

      expect(StockState.isIntentionallyHidden(data), isFalse);
      expect(StockState.calculatedStockStatus(data), 'outOfStock');
      expect(StockState.isMarketplaceOrderable(data), isFalse);
    });

    test('marks stock at or below threshold as low stock', () {
      final data = <String, dynamic>{
        'status': 'available',
        'isActive': true,
        'quantity': 4,
        'lowStockLevel': 5,
      };

      expect(StockState.calculatedStockStatus(data), 'lowStock');
      expect(StockState.isMarketplaceOrderable(data), isTrue);
    });

    test('keeps intentionally hidden products unorderable', () {
      final data = <String, dynamic>{
        'status': 'unavailable',
        'isActive': false,
        'quantity': 20,
        'lowStockLevel': 5,
      };

      expect(StockState.isIntentionallyHidden(data), isTrue);
      expect(StockState.calculatedStockStatus(data), 'hidden');
      expect(StockState.isMarketplaceOrderable(data), isFalse);
    });

    test('quantity update preserves visibility and recalculates stock status', () {
      final data = <String, dynamic>{
        'status': 'available',
        'isActive': true,
        'quantity': 10,
        'lowStockLevel': 3,
      };

      final fields = StockState.fieldsForQuantity(
        data,
        quantity: 2,
      );

      expect(fields['quantity'], 2);
      expect(fields['status'], 'available');
      expect(fields['isActive'], isTrue);
      expect(fields['stockStatus'], 'lowStock');
    });
  });
}
