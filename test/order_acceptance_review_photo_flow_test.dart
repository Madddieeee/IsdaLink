import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supplier acceptance no longer exposes quantity adjustment', () {
    final source = File(
      'lib/screens/supplier/supplier_cod_orders_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('FULFILLED QUANTITY')));
    expect(source, isNot(contains('Accept Partial')));
    expect(source, contains("acceptedFulfilledQuantity = requestedQuantity"));
  });

  test('initial review sends selected photos through the review service', () {
    final source = File(
      'lib/screens/vendor/my_orders_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Add fish photos'));
    expect(source, contains('pickMultiImage'));
    expect(source, contains('photoUrls: uploadedUrls'));
    expect(source, contains('ReviewService.maxReviewPhotos'));
  });
}
