import 'package:flutter_test/flutter_test.dart';
import 'analytics_calendar_cases.dart';

void main() {
  for (final entry in analyticsCalendarCases.entries) {
    test(entry.key, entry.value);
  }
}
