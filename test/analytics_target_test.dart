import 'package:flutter_test/flutter_test.dart';
import 'analytics_target_cases.dart';

void main() {
  for (final entry in analyticsTargetCases.entries) {
    test(entry.key, entry.value);
  }
}
