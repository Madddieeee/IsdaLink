import 'package:isdalink/analytics/analytics_identity.dart';
import 'package:isdalink/analytics/analytics_record.dart';
import 'analytics_common_target_cases.dart' show require;

AnalyticsIdentityRecord candidate(
  String id,
  AnalyticsSource source, {
  String? link,
  bool eligible = true,
  String vendor = 'v',
  String supplier = 's',
}) => AnalyticsIdentityRecord(
  documentId: id,
  source: source,
  data: source == AnalyticsSource.live
      ? {'vendorId': vendor, 'supplierId': supplier}
      : {'vendorUid': vendor, 'supplierUid': supplier, 'sourceOrderId': link},
  record: eligible
      ? EligibleAnalyticsRecord(date: DateTime.utc(2026, 8), lines: const [])
      : null,
);

final analyticsIdentityCases = <String, void Function()>{
  'unlinked sources remain separate even with equal IDs': () {
    final r = resolveAnalyticsIdentities([
      candidate('same', AnalyticsSource.live),
      candidate('same', AnalyticsSource.historical),
    ]);
    require(r.records.length == 2, 'Collection namespaces are separate');
  },
  'explicit link prefers eligible live once': () {
    final r = resolveAnalyticsIdentities([
      candidate('o', AnalyticsSource.live),
      candidate('h', AnalyticsSource.historical, link: 'o'),
    ]);
    require(
      r.records.length == 1 && r.records.single.source == AnalyticsSource.live,
      'Live precedence',
    );
  },
  'all historical lines linked to one eligible order are suppressed': () {
    final r = resolveAnalyticsIdentities([
      candidate('h1', AnalyticsSource.historical, link: 'o'),
      candidate('h2', AnalyticsSource.historical, link: 'o'),
      candidate('o', AnalyticsSource.live),
    ]);
    require(r.records.length == 1, 'Multi-line order counted once');
  },
  'ineligible live does not suppress valid history': () {
    final r = resolveAnalyticsIdentities([
      candidate('o', AnalyticsSource.live, eligible: false),
      candidate('h', AnalyticsSource.historical, link: 'o'),
    ]);
    require(
      r.records.length == 1 &&
          r.records.single.source == AnalyticsSource.historical,
      'Historical fallback',
    );
  },
  'missing live document preserves historical record': () {
    require(
      resolveAnalyticsIdentities([
            candidate('h', AnalyticsSource.historical, link: 'absent'),
          ]).records.length ==
          1,
      'Unresolved link retains history',
    );
  },
  'conflicting account link excludes group visibly': () {
    final r = resolveAnalyticsIdentities([
      candidate('o', AnalyticsSource.live),
      candidate('h', AnalyticsSource.historical, link: 'o', supplier: 'other'),
    ]);
    require(r.records.isEmpty && r.conflictingRecords == 2, 'Conflict count');
  },
  'missing counterpart account cannot establish link': () {
    final r = resolveAnalyticsIdentities([
      candidate('o', AnalyticsSource.live),
      candidate('h', AnalyticsSource.historical, link: 'o', vendor: ''),
    ]);
    require(r.records.isEmpty && r.conflictingRecords == 2, 'Missing identity');
  },
  'ineligible historical record does not invalidate live': () {
    final r = resolveAnalyticsIdentities([
      candidate('o', AnalyticsSource.live),
      candidate(
        'h',
        AnalyticsSource.historical,
        link: 'o',
        eligible: false,
        supplier: 'other',
      ),
    ]);
    require(
      r.records.length == 1 && r.conflictingRecords == 0,
      'Eligibility first',
    );
  },
  'repeated documents within one source are rejected': () {
    for (final source in AnalyticsSource.values) {
      var rejected = false;
      try {
        resolveAnalyticsIdentities([
          candidate('x', source),
          candidate('x', source),
        ]);
      } on ArgumentError {
        rejected = true;
      }
      require(rejected, 'Duplicate source ID');
    }
  },
};
