import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/utils/tawad_pricing.dart';

void main() {
  group('TawadPricing', () {
    test('accepts a positive price below the listing with two decimals', () {
      expect(
        TawadPricing.validationMessage(
          requested: true,
          listedUnitPrice: 5000,
          offeredUnitPrice: 4500.25,
        ),
        isNull,
      );
    });

    test('rejects zero, equal, higher, and excessive precision', () {
      for (final offer in <double>[0, 5000, 5100, 4500.123]) {
        expect(
          TawadPricing.validationMessage(
            requested: true,
            listedUnitPrice: 5000,
            offeredUnitPrice: offer,
          ),
          isNotNull,
        );
      }
    });

    test('does not require an offer for a regular order', () {
      expect(
        TawadPricing.validationMessage(
          requested: false,
          listedUnitPrice: 5000,
          offeredUnitPrice: null,
        ),
        isNull,
      );
    });

    test('acceptance uses the exact stored offer', () {
      expect(
        TawadPricing.acceptedUnitPrice(<String, dynamic>{
          'tawadRequested': true,
          'tawadOfferedUnitPrice': 4500,
          'unitPrice': 5000,
        }),
        4500,
      );
    });

    test('regular acceptance keeps the listed order price', () {
      expect(
        TawadPricing.acceptedUnitPrice(<String, dynamic>{
          'tawadRequested': false,
          'unitPrice': 5000,
        }),
        5000,
      );
    });
  });
}
