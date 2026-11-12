import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'analytics fish atlas is bundled and all dataset products are mapped',
    () async {
      final atlas = await rootBundle.load(
        'assets/images/fish_species_atlas.png',
      );
      expect(atlas.lengthInBytes, greaterThan(0));

      final source = File(
        'lib/screens/analytics/analytics_screen.dart',
      ).readAsStringSync();
      for (final product in <String>[
        'tilapia',
        'bangus',
        'pijanga',
        'tamban',
        'panit',
        'pirit',
        'bodloy',
        'pasayan',
        'yellowfintuna',
        'barilis',
        'malasugi',
        'pawayan',
      ]) {
        expect(source, contains("'$product'"));
      }
    },
  );
}
