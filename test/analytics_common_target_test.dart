import 'package:flutter_test/flutter_test.dart';
import 'analytics_common_target_cases.dart';

void main() {
  for (final entry in analyticsCommonTargetCases.entries) {
    test(entry.key, entry.value);
  }
}
