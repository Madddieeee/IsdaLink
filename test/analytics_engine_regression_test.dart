import 'package:flutter_test/flutter_test.dart';
import 'analytics_engine_regression_cases.dart';
import 'analytics_record_set_cases.dart';

void main() {
  for (final monthly in [false, true]) {
    for (final entry in analyticsEngineRegressionCases(monthly).entries) {
      test('${monthly ? "Monthly" : "Weekly"}: ${entry.key}', entry.value);
    }
    for (final supplier in [false, true]) {
      for (final entry in analyticsRecordSetCases(
        supplier: supplier,
        monthly: monthly,
      ).entries) {
        test(
          '${supplier ? "Supplier" : "Vendor"} ${monthly ? "Monthly" : "Weekly"}: ${entry.key}',
          entry.value,
        );
      }
    }
  }
}
