import 'package:isdalink/analytics/analytics_identity.dart';
import 'package:isdalink/analytics/analytics_record.dart';
import 'package:isdalink/analytics/analytics_record_set.dart';
import 'analytics_record_cases.dart' show history, live, validate;
import 'analytics_common_target_cases.dart' show require, close;

Map<String, void Function()> analyticsRecordSetCases({
  required bool supplier,
  required bool monthly,
}) {
  final now = DateTime.utc(2026, 10, 9);
  AnalyticsIdentityRecord row(
    String id,
    Map<String, dynamic> data, {
    bool historical = true,
  }) => AnalyticsIdentityRecord(
    documentId: id,
    source: historical ? AnalyticsSource.historical : AnalyticsSource.live,
    data: data,
    record: validate(data, historical: historical, supplier: supplier),
  );
  AnalyticsIdentityResult resolve(List<AnalyticsIdentityRecord> records) =>
      closedAnalyticsRecordSet(records, now: now, monthly: monthly);
  return {
    'eligible closed records alone contribute counts and totals': () {
      final result = resolve([
        row('history', history()),
        row('live', live(), historical: false),
        row('flag', history()..['analyticsEligible'] = false),
        row('bad-line', history()..remove('quantityFulfilled')),
        row('pending', live()..['orderStatus'] = 'Pending', historical: false),
        row(
          'other',
          history()..[supplier ? 'supplierUid' : 'vendorUid'] = 'other',
        ),
        row('open-h', history()..['transactionDateIso'] = '2026-10-09'),
        row('open-l', live()..['createdAt'] = now, historical: false),
      ]);
      final totals = AnalyticsRecordTotals(result.records);
      require(
        totals.count == 2 &&
            totals.historicalCount == 1 &&
            totals.liveCount == 1,
        'Eligible closed counts',
      );
      close(totals.knownAmount, 800);
      close(
        result.records.fold(
          0.0,
          (sum, r) =>
              sum + r.record!.lines.fold(0.0, (sum, l) => sum + l.quantity),
        ),
        8,
      );
      require(totals.hasCompleteAmounts, 'Known amounts');
    },
    'linked live order contributes once after eligibility': () {
      final result = resolve([
        row('o', live(), historical: false),
        row('h1', history()..['sourceOrderId'] = 'o'),
        row('h2', history()..['sourceOrderId'] = 'o'),
      ]);
      final totals = AnalyticsRecordTotals(result.records);
      require(
        totals.count == 1 && totals.liveCount == 1,
        'One authoritative live order',
      );
      close(totals.knownAmount, 400);
    },
    'open live authority cannot reappear as closed linked history': () {
      final result = resolve([
        row('o', live()..['createdAt'] = now, historical: false),
        row('h', history()..['sourceOrderId'] = 'o'),
      ]);
      require(result.records.isEmpty, 'Resolve identity before open exclusion');
      close(AnalyticsRecordTotals(result.records).knownAmount, 0);
    },
    'ineligible live order preserves eligible linked historical record': () {
      final result = resolve([
        row('o', live()..['paymentStatus'] = 'Unpaid', historical: false),
        row('h', history()..['sourceOrderId'] = 'o'),
      ]);
      final totals = AnalyticsRecordTotals(result.records);
      require(
        totals.historicalCount == 1 && totals.liveCount == 0,
        'Historical fallback',
      );
      close(totals.knownAmount, 400);
    },
    'unknown amount stays unknown while valid quantity contributes': () {
      final result = resolve([
        row(
          'h',
          history()
            ..remove('unitPrice')
            ..remove('totalAmount'),
        ),
      ]);
      final totals = AnalyticsRecordTotals(result.records);
      require(
        totals.count == 1 && !totals.hasCompleteAmounts,
        'Valid quantity without invented money',
      );
      close(totals.knownAmount, 0);
      close(result.records.single.record!.lines.single.quantity, 4);
    },
    'unlinked product-unit records remain distinct and countable': () {
      final result = resolve([
        row('a', history()..['quantityUnit'] = 'kg'),
        row('b', history()..['quantityUnit'] = 'tab'),
        row('c', history()..['quantityUnit'] = 'icebox'),
      ]);
      require(
        AnalyticsRecordTotals(result.records).count == 3,
        'Three records',
      );
      require(
        result.records.map((r) => r.record!.lines.single.unit).toSet().length ==
            3,
        'Units preserved',
      );
    },
  };
}
