import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/utils/tawad_eligibility.dart';

void main() {
  group('TawadEligibility', () {
    test('requires both delivered and paid', () {
      expect(
        TawadEligibility.isQualifyingOrder(const {
          'orderStatus': 'Delivered',
          'paymentStatus': 'Paid',
        }),
        isTrue,
      );
    });

    test('accepts the legacy completed status only when paid', () {
      expect(
        TawadEligibility.isQualifyingOrder(const {
          'orderStatus': 'Completed',
          'paymentStatus': 'Paid',
        }),
        isTrue,
      );
      expect(
        TawadEligibility.isQualifyingOrder(const {
          'orderStatus': 'Completed',
          'paymentStatus': 'To be paid on delivery',
        }),
        isFalse,
      );
    });

    test('pending accepted cancelled and unpaid orders do not qualify', () {
      for (final order in <Map<String, dynamic>>[
        const {'orderStatus': 'Pending', 'paymentStatus': 'Paid'},
        const {'orderStatus': 'Accepted', 'paymentStatus': 'Paid'},
        const {'orderStatus': 'Cancelled', 'paymentStatus': 'Paid'},
        const {
          'orderStatus': 'Delivered',
          'paymentStatus': 'To be paid on delivery',
        },
      ]) {
        expect(TawadEligibility.isQualifyingOrder(order), isFalse);
      }
    });

    test('status matching is case insensitive', () {
      expect(
        TawadEligibility.isQualifyingOrder(const {
          'orderStatus': 'delivered',
          'paymentStatus': 'paid',
        }),
        isTrue,
      );
    });
  });
}
