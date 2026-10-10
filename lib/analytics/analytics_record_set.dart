import 'analytics_calendar.dart';
import 'analytics_identity.dart';
import 'analytics_record.dart';

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
      ))
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
