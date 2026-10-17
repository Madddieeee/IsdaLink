import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all supplier entry points reject legacy copied cover photos', () {
    final productDetails = File(
      'lib/screens/vendor/product_details_screen.dart',
    ).readAsStringSync();
    final browseService = File(
      'lib/services/supplier_browse_service.dart',
    ).readAsStringSync();
    final supplierDashboard = File(
      'lib/screens/supplier/supplier_dashboard_screen.dart',
    ).readAsStringSync();

    for (final source in [
      productDetails,
      browseService,
      supplierDashboard,
    ]) {
      expect(source, contains("data['coverImageSetByOwner'] != true"));
    }

    expect(
      productDetails,
      isNot(contains(
        "return value.isNotEmpty ? value : supplier.coverImageUrl;",
      )),
    );
  });
}
