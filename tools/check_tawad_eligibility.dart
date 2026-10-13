import 'dart:io';

import 'package:isdalink/utils/tawad_eligibility.dart';

void main() {
  final cases = <({Map<String, dynamic> order, bool expected})>[
    (
      order: const {'orderStatus': 'Delivered', 'paymentStatus': 'Paid'},
      expected: true,
    ),
    (
      order: const {'orderStatus': 'Completed', 'paymentStatus': 'Paid'},
      expected: true,
    ),
    (
      order: const {'orderStatus': 'Pending', 'paymentStatus': 'Paid'},
      expected: false,
    ),
    (
      order: const {'orderStatus': 'Accepted', 'paymentStatus': 'Paid'},
      expected: false,
    ),
    (
      order: const {'orderStatus': 'Cancelled', 'paymentStatus': 'Paid'},
      expected: false,
    ),
    (
      order: const {
        'orderStatus': 'Delivered',
        'paymentStatus': 'To be paid on delivery',
      },
      expected: false,
    ),
  ];

  for (final item in cases) {
    final actual = TawadEligibility.isQualifyingOrder(item.order);
    if (actual != item.expected) {
      throw StateError(
        'Eligibility mismatch for ${item.order}: expected ${item.expected}, got $actual.',
      );
    }
  }

  stdout.writeln(
    'PASS: ${cases.length} Tawad eligibility cases; no Firestore access or writes.',
  );
}
