import 'package:flutter_test/flutter_test.dart';
import 'forecast_display_cases.dart';

void main() {
  for (final entry in forecastDisplayCases.entries) {
    test(entry.key, entry.value);
  }
}
