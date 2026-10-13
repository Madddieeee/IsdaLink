import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'supplier profile keeps actions clear and avoids repeated status UI',
    () {
      final profile = File(
        'lib/screens/profile/supplier_profile_screen.dart',
      ).readAsStringSync();
      final requestFlow = File(
        'lib/screens/profile/supplier_verified_change_request_screen.dart',
      ).readAsStringSync();

      expect(profile, isNot(contains('Protected Account Details')));
      expect(profile, isNot(contains('_HybridPolicyNote')));
      expect(profile, contains('Edit Public Storefront'));
      expect(profile, contains('Verified Business Details'));

      expect(requestFlow, contains('Request submitted for review.'));
      expect(
        requestFlow,
        isNot(contains('Verified change request submitted for Admin review.')),
      );
      expect(profile, contains('Your approved profile stays live'));
    },
  );
}
