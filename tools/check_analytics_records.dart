import 'dart:io';

import '../test/analytics_record_cases.dart';

void main() {
  for (final entry in analyticsRecordCases.entries) {
    entry.value();
    stdout.writeln('PASS: ${entry.key}');
  }
  stdout.writeln(
    '${analyticsRecordCases.length} Analytics eligibility checks passed.',
  );
}
