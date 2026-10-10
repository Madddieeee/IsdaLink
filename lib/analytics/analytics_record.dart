import 'analytics_calendar.dart';

enum AnalyticsSource { historical, live }

class EligibleAnalyticsLine {
  const EligibleAnalyticsLine({
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.amount,
    required this.emoji,
  });
  final String productName;
  final String unit;
  final double quantity;
  final double? amount;
  final String emoji;
}

class EligibleAnalyticsRecord {
  const EligibleAnalyticsRecord({required this.date, required this.lines});
  final DateTime date;
  final List<EligibleAnalyticsLine> lines;
  bool get hasCompleteAmounts => lines.every((line) => line.amount != null);
  double get knownAmount =>
      lines.fold(0.0, (sum, line) => sum + (line.amount ?? 0));
}

Object? _value(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key) && data[key] != null) return data[key];
  }
  return null;
}

String? _text(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

double? _number(Object? value) {
  final parsed = value is num
      ? value.toDouble()
      : value is String
      ? double.tryParse(value.trim())
      : null;
  return parsed != null && parsed.isFinite ? parsed : null;
}

String? analyticsQuantityUnit(Object? value) {
  final text = _text(value)
      ?.toLowerCase()
      .replaceAll(RegExp(r'[_-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (const [
    'kg',
    'kgs',
    'kilo',
    'kilos',
    'kilogram',
    'kilograms',
  ].contains(text)) {
    return 'kilogram';
  }
  if (text == 'tab' || text == 'tabs') return 'tab';
  if (const ['icebox', 'iceboxes', 'ice box', 'ice boxes'].contains(text)) {
    return 'icebox';
  }
  return null;
}

/// Date-only text is a business calendar date. Timestamp values are instants.
/// No missing date, invalid calendar date or unzoned datetime is guessed.
DateTime? analyticsRecordDate(Object? value) {
  if (value is DateTime) return analyticsBusinessDate(value);
  final text = _text(value);
  if (text == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(.*)$').firstMatch(text);
  if (match == null) return null;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) return null;
  final calendar = DateTime.utc(year, month, day);
  if (calendar.year != year || calendar.month != month || calendar.day != day) {
    return null;
  }
  if (match[4]!.isEmpty) return calendar;
  final time = RegExp(
    r'^T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,6})?)?(Z|[+-]\d{2}:\d{2})$',
  ).firstMatch(match[4]!);
  if (time == null ||
      int.parse(time[1]!) > 23 ||
      int.parse(time[2]!) > 59 ||
      int.parse(time[3] ?? '0') > 59) {
    return null;
  }
  final zone = time[4]!;
  if (zone != 'Z' &&
      (int.parse(zone.substring(1, 3)) > 14 ||
          int.parse(zone.substring(4)) > 59 ||
          (int.parse(zone.substring(1, 3)) == 14 &&
              zone.substring(4) != '00'))) {
    return null;
  }
  final instant = DateTime.tryParse(text);
  return instant == null ? null : analyticsBusinessDate(instant);
}

double? _lineAmount(
  Map<String, dynamic> data,
  double quantity, {
  required bool historical,
}) {
  final explicit = _number(
    _value(
      data,
      historical
          ? ['totalAmount', 'totalAmountPhp', 'total_amount_php']
          : ['validatedTotalAmount', 'fulfilledTotalAmount'],
    ),
  );
  if (explicit != null) return explicit >= 0 ? explicit : null;
  final price = _number(
    _value(data, [
      'unitPrice',
      'unit_price_php',
      'unitPricePhp',
      'price',
      'pricePerUnit',
    ]),
  );
  if (price != null && price >= 0) {
    final amount = price * quantity;
    return amount.isFinite ? amount : null;
  }
  // A live requested total is usable only when requested == fulfilled.
  final requested = _number(data['quantity']);
  if (!historical && requested == quantity) {
    final total = _number(
      _value(data, ['lineTotal', 'subtotal', 'totalAmount', 'grandTotal']),
    );
    if (total != null && total >= 0) return total;
  }
  return null;
}

EligibleAnalyticsLine? _line(
  Map<String, dynamic> data, {
  required bool historical,
}) {
  final name = _text(
    _value(
      data,
      historical
          ? ['productName', 'fishProduct', 'fish_product']
          : ['productName', 'fishName', 'name'],
    ),
  );
  final unit = analyticsQuantityUnit(
    _value(
      data,
      historical
          ? ['quantityUnit', 'quantity_unit']
          : ['quantityUnit', 'unit', 'unitType'],
    ),
  );
  final quantity = _number(
    _value(
      data,
      historical
          ? ['quantityFulfilled', 'quantity_fulfilled']
          : ['validatedFulfilledQuantity', 'fulfilledQuantity'],
    ),
  );
  if (name == null || unit == null || quantity == null || quantity <= 0) {
    return null;
  }
  final requested = _number(
    _value(
      data,
      historical ? ['quantityOrdered', 'quantity_ordered'] : ['quantity'],
    ),
  );
  if (requested != null && (requested <= 0 || quantity > requested)) {
    return null;
  }
  return EligibleAnalyticsLine(
    productName: name,
    unit: unit,
    quantity: quantity,
    amount: _lineAmount(data, quantity, historical: historical),
    emoji: _text(_value(data, ['productEmoji', 'emoji'])) ?? '🐟',
  );
}

EligibleAnalyticsRecord? eligibleAnalyticsRecord(
  Map<String, dynamic> data, {
  required AnalyticsSource source,
  required bool supplier,
  required String accountUid,
}) {
  if (accountUid.trim().isEmpty) return null;
  final historical = source == AnalyticsSource.historical;
  final ownerKey = historical
      ? (supplier ? 'supplierUid' : 'vendorUid')
      : (supplier ? 'supplierId' : 'vendorId');
  if (_text(data[ownerKey]) != accountUid) return null;
  final status = _text(
    _value(data, ['orderStatus', 'order_status', 'status']),
  )?.toLowerCase();
  if (historical) {
    if (status != 'completed' ||
        data['analyticsEligible'] != true ||
        _text(
              _value(data, ['validationStatus', 'validation_status']),
            )?.toLowerCase() !=
            'validated') {
      return null;
    }
  } else {
    if (status != 'delivered' && status != 'completed') return null;
    final payment = _text(data['paymentStatus'])?.toLowerCase();
    final method = _text(data['paymentMethod'])?.toLowerCase();
    if (data.containsKey('paymentStatus') && payment != 'paid') return null;
    if (data.containsKey('paymentMethod') &&
        method != 'cod' &&
        method != 'cash on delivery') {
      return null;
    }
    // Legacy Completed support requires explicit paid COD evidence, not just
    // a terminal-looking status. No payment value is invented.
    if (status == 'completed' &&
        (payment != 'paid' ||
            (method != 'cod' && method != 'cash on delivery'))) {
      return null;
    }
  }
  final date = analyticsRecordDate(
    _value(
      data,
      historical
          ? ['transactionDateIso', 'transactionDate', 'transaction_date']
          : ['transactionDate', 'orderDate', 'createdAt'],
    ),
  );
  if (date == null) return null;
  final rawItems = historical ? null : _value(data, ['items', 'orderItems']);
  final lines = <EligibleAnalyticsLine>[];
  if (rawItems != null) {
    if (rawItems is! List || rawItems.isEmpty) return null;
    for (final item in rawItems) {
      if (item is! Map<String, dynamic>) return null;
      final line = _line(item, historical: false);
      if (line == null) return null; // Never count a partially valid order.
      lines.add(line);
    }
  } else {
    final line = _line(data, historical: historical);
    if (line == null) return null;
    lines.add(line);
  }
  return EligibleAnalyticsRecord(date: date, lines: lines);
}
