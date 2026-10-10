import 'package:flutter_test/flutter_test.dart';

import 'analytics_selection_message_cases.dart';

void main() {
  for (final entry in analyticsSelectionMessageCases.entries) {
    test(entry.key, entry.value);
  }
}
