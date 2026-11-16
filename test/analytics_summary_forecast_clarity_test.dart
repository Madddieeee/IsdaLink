import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('historical summary forecast explains the estimate in plain language', () {
    final source = File(
      'lib/screens/analytics/analytics_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('Estimated \$activityNoun for the next \$periodNoun'),
    );
    expect(source, contains('Using earlier completed sales'));
    expect(source, contains('Using earlier completed purchases'));
    expect(source, contains('you would purchase'));
    expect(source, contains("'sales' : 'purchases'"));
    expect(source, contains("'sales' : 'purchase'"));
    expect(source, contains("'stock recommendation'"));
    expect(source, contains("'restocking recommendation'"));
    expect(source, contains('past estimate for review'));
    expect(source, contains('stock recommendation'));
    expect(source, contains('_FishSpeciesImage('));
    expect(source, contains('productName: product.productName'));
    expect(
      source,
      isNot(
        contains(
          'Estimate after the selected historical period; not current planning advice.',
        ),
      ),
    );
  });
}
