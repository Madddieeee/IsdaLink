import 'analytics_calendar.dart';
import 'analytics_identity.dart';
import 'analytics_record.dart';

bool _hasCompleteHistoricalCoverage(
  AnalyticsIdentityRecord input, {
  required bool monthly,
}) {
  if (input.source != AnalyticsSource.historical) return true;

  final coverageStart = analyticsRecordDate(
    input.data['sourceCoverageStartDateIso'],
  );
  final coverageEnd = analyticsRecordDate(
    input.data['sourceCoverageEndDateIso'],
  );
  final record = input.record;

  // Historical rows without explicit source coverage cannot prove that their
  // boundary week/month is complete, so they are not analytics-eligible.
  if (coverageStart == null || coverageEnd == null || record == null) {
    return false;
  }
  if (coverageStart.isAfter(coverageEnd) ||
      record.date.isBefore(coverageStart) ||
      record.date.isAfter(coverageEnd)) {
    return false;
  }

  final start = analyticsPeriodStart(record.date, monthly: monthly);
  final nextStart = monthly
      ? DateTime.utc(start.year, start.month + 1)
      : start.add(const Duration(days: 7));
  final end = nextStart.subtract(const Duration(days: 1));

  return !start.isBefore(coverageStart) && !end.isAfter(coverageEnd);
}

/// Resolve identity before excluding open periods: an authoritative open live
/// order must not re-enter history through an older linked historical record.
AnalyticsIdentityResult closedAnalyticsRecordSet(
  List<AnalyticsIdentityRecord> inputs, {
  required DateTime now,
  required bool monthly,
}) {
  final resolved = resolveAnalyticsIdentities(inputs);
  return AnalyticsIdentityResult([
    for (final input in resolved.records)
      if (isClosedAnalyticsPeriod(
            input.record!.date,
            now: now,
            monthly: monthly,
          ) &&
          _hasCompleteHistoricalCoverage(input, monthly: monthly))
        input,
  ], resolved.conflictingRecords);
}

class AnalyticsRecordTotals {
  AnalyticsRecordTotals(List<AnalyticsIdentityRecord> records)
    : liveCount = records.where((r) => r.source == AnalyticsSource.live).length,
      historicalCount = records
          .where((r) => r.source == AnalyticsSource.historical)
          .length,
      knownAmount = records.fold(0.0, (sum, r) => sum + r.record!.knownAmount),
      hasCompleteAmounts = records.every((r) => r.record!.hasCompleteAmounts);

  final int liveCount;
  final int historicalCount;
  int get count => liveCount + historicalCount;
  final double knownAmount;
  final bool hasCompleteAmounts;
}
