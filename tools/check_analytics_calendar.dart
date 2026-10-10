import 'dart:io';

import '../test/analytics_calendar_cases.dart';

void main() {
  for (final entry in analyticsCalendarCases.entries) {
    entry.value();
    stdout.writeln('PASS: ${entry.key}');
  }
  stdout.writeln(
    '${analyticsCalendarCases.length} Analytics calendar checks passed.',
  );
}
