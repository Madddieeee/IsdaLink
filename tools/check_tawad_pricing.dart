import 'dart:io';

import 'package:isdalink/utils/tawad_pricing.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  require(
    TawadPricing.validationMessage(
          requested: true,
          listedUnitPrice: 5000,
          offeredUnitPrice: 4500.25,
        ) ==
        null,
    'A valid lower two-decimal offer must pass.',
  );

  for (final price in <double>[0, 5000, 5100, 4500.123]) {
    require(
      TawadPricing.validationMessage(
            requested: true,
            listedUnitPrice: 5000,
            offeredUnitPrice: price,
          ) !=
          null,
      'Invalid price $price must be rejected.',
    );
  }

  require(
    TawadPricing.acceptedUnitPrice(<String, dynamic>{
          'tawadRequested': true,
          'tawadOfferedUnitPrice': 4500,
          'unitPrice': 5000,
        }) ==
        4500,
    'Acceptance must use the exact stored offer.',
  );

  require(
    TawadPricing.acceptedUnitPrice(<String, dynamic>{
          'tawadRequested': false,
          'unitPrice': 5000,
        }) ==
        5000,
    'A regular order must keep its listed price.',
  );

  stdout.writeln('PASS: Tawad price validation and exact acceptance checks.');
}
