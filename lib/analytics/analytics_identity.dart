import 'analytics_record.dart';

/// A historical sourceOrderId explicitly names an orders document. Similar
/// dates, names, quantities and document IDs across collections are not links.
class AnalyticsIdentityRecord {
  const AnalyticsIdentityRecord({
    required this.documentId,
    required this.source,
    required this.data,
    required this.record,
  });
  final String documentId;
  final AnalyticsSource source;
  final Map<String, dynamic> data;
  final EligibleAnalyticsRecord? record;
}

class AnalyticsIdentityResult {
  const AnalyticsIdentityResult(this.records, this.conflictingRecords);
  final List<AnalyticsIdentityRecord> records;
  final int conflictingRecords;
}

String? _id(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

AnalyticsIdentityResult resolveAnalyticsIdentities(
  List<AnalyticsIdentityRecord> inputs,
) {
  final live = <String, AnalyticsIdentityRecord>{};
  for (final input in inputs) {
    if (input.source == AnalyticsSource.live) {
      if (live.containsKey(input.documentId)) {
        throw ArgumentError('Duplicate live document ID');
      }
      live[input.documentId] = input;
    }
  }
  final conflicts = <String>{};
  for (final input in inputs) {
    if (input.source != AnalyticsSource.historical || input.record == null) {
      continue;
    }
    final link = _id(input.data['sourceOrderId']);
    final order = live[link];
    if (order == null) continue;
    // Both parties must be known and agree before a cross-source link is used.
    final vendor = _id(input.data['vendorUid']);
    final supplier = _id(input.data['supplierUid']);
    if (vendor == null ||
        supplier == null ||
        vendor != _id(order.data['vendorId']) ||
        supplier != _id(order.data['supplierId'])) {
      conflicts.add(link!);
    }
  }
  final selected = <AnalyticsIdentityRecord>[];
  var rejected = 0;
  final historicalIds = <String>{};
  for (final input in inputs) {
    if (input.source == AnalyticsSource.historical &&
        !historicalIds.add(input.documentId)) {
      throw ArgumentError('Duplicate historical document ID');
    }
    if (input.record == null) continue;
    final link = input.source == AnalyticsSource.live
        ? input.documentId
        : _id(input.data['sourceOrderId']);
    if (conflicts.contains(link)) {
      rejected++;
      continue;
    }
    if (input.source == AnalyticsSource.historical &&
        live[link]?.record != null) {
      continue; // Eligible live order is authoritative for all linked CSV lines.
    }
    selected.add(input);
  }
  return AnalyticsIdentityResult(selected, rejected);
}
