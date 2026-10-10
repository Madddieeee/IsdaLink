import 'dart:io';
import 'package:isdalink/analytics/forecast_engine.dart';
import '../test/analytics_calendar_cases.dart';
import '../test/analytics_common_target_cases.dart';
import '../test/analytics_record_cases.dart';
import '../test/analytics_identity_cases.dart';
import '../test/analytics_target_cases.dart';
import '../test/analytics_parameter_cases.dart';
import '../test/analytics_metrics_cases.dart';
import '../test/analytics_ranking_cases.dart';
import '../test/forecast_display_cases.dart';
import '../test/analytics_engine_regression_cases.dart';
import '../test/analytics_record_set_cases.dart';
import '../test/analytics_missing_period_cases.dart';

/// Read-only synthetic Method Contract checks; no Firebase initialization.
void main() {
  var count = 0;
  void run(String scope, Map<String, void Function()> cases) {
    for (final entry in cases.entries) {
      entry.value();
      count++;
      stdout.writeln('PASS: $scope: ${entry.key}');
    }
  }

  run('analytics_calendar', analyticsCalendarCases);
  run('analytics_common_target', analyticsCommonTargetCases);
  run('analytics_record', analyticsRecordCases);
  run('analytics_identity', analyticsIdentityCases);
  run('analytics_target', analyticsTargetCases);
  run('analytics_parameter', analyticsParameterCases);
  run('analytics_metrics', analyticsMetricsCases);
  run('analytics_ranking', analyticsRankingCases);
  run('forecast_display', forecastDisplayCases);
  for (final monthly in [false, true]) {
    run('engine monthly=$monthly', analyticsEngineRegressionCases(monthly));
    final engine = AnalyticsForecastCalculator(forecastMonthly: monthly);
    final target = DateTime.utc(2026, 10, 5);
    run(
      'missing monthly=$monthly',
      analyticsMissingPeriodCases(
        engine: engine,
        target: target,
        monthly: monthly,
        history: (count, quantity) => List<PeriodPoint>.generate(
          count,
          (i) => PeriodPoint(
            date: engine.shiftAnalyticsPeriod(target, i - count),
            quantity: quantity,
            amount: 0,
          ),
        ),
      ),
    );
    for (final supplier in [false, true]) {
      run(
        'record set supplier=$supplier monthly=$monthly',
        analyticsRecordSetCases(supplier: supplier, monthly: monthly),
      );
    }
  }
  stdout.writeln(
    'PASS: $count synthetic Analytics contract cases. No Firestore access or writes.',
  );
}
