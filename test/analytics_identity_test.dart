import 'package:flutter_test/flutter_test.dart';
import 'analytics_identity_cases.dart';

void main() {
  for (final entry in analyticsIdentityCases.entries) {
    test(entry.key, entry.value);
  }
}
