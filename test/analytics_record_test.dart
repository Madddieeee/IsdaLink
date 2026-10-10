import 'package:flutter_test/flutter_test.dart';
import 'analytics_record_cases.dart';

void main() {
  for (final entry in analyticsRecordCases.entries) {
    test(entry.key, entry.value);
  }
}
