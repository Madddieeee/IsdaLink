import 'dart:io';

import '../test/analytics_common_target_cases.dart';

void main() {
  for (final entry in analyticsCommonTargetCases.entries) {
    entry.value();
    stdout.writeln('PASS: ${entry.key}');
  }
  stdout.writeln(
    '${analyticsCommonTargetCases.length} Analytics S2 checks passed.',
  );
}
