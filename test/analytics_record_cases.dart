import 'package:isdalink/analytics/analytics_record.dart';
import 'analytics_common_target_cases.dart' show require, close;

Map<String, dynamic> history() => {
  'vendorUid': 'vendor',
  'supplierUid': 'supplier',
  'orderStatus': 'Completed',
  'validationStatus': 'Validated',
  'analyticsEligible': true,
  'transactionDateIso': '2026-09-28',
  'sourceCoverageStartDateIso': '2026-01-01',
  'sourceCoverageEndDateIso': '2026-12-31',
  'productName': 'Tamban',
  'quantityFulfilled': 4,
  'quantityOrdered': 6,
  'quantityUnit': 'icebox',
  'unitPrice': 100,
  'totalAmount': 400,
};
Map<String, dynamic> live() => {
  'vendorId': 'vendor',
  'supplierId': 'supplier',
  'orderStatus': 'Delivered',
  'createdAt': DateTime.utc(2026, 9, 28),
  'productName': 'Tamban',
  'fulfilledQuantity': 4,
  'quantity': 6,
  'quantityUnit': 'icebox',
  'unitPrice': 100,
  'totalAmount': 600,
  'fulfilledTotalAmount': 400,
  'paymentMethod': 'COD',
  'paymentStatus': 'Paid',
};
EligibleAnalyticsRecord? validate(
  Map<String, dynamic> data, {
  bool historical = true,
  bool supplier = false,
}) => eligibleAnalyticsRecord(
  data,
  source: historical ? AnalyticsSource.historical : AnalyticsSource.live,
  supplier: supplier,
  accountUid: supplier ? 'supplier' : 'vendor',
);

final analyticsRecordCases = <String, void Function()>{
  'valid imported and delivered records pass for both roles': () {
    for (final supplier in [false, true]) {
      require(
        validate(history(), supplier: supplier) != null,
        'Valid historical',
      );
      require(
        validate(live(), historical: false, supplier: supplier) != null,
        'Valid live',
      );
    }
  },
  'historical eligibility requires boolean true and both statuses': () {
    for (final flag in [null, false, 'true', 1]) {
      final row = history()..['analyticsEligible'] = flag;
      require(validate(row) == null, 'Invalid flag $flag');
    }
    require(
      validate(history()..remove('analyticsEligible')) == null,
      'Missing flag',
    );
    require(
      validate(history()..['orderStatus'] = 'Pending') == null,
      'Historical pending',
    );
    require(
      validate(history()..['validationStatus'] = 'Unvalidated') == null,
      'Unvalidated',
    );
  },
  'ownership is checked again after query scope': () {
    require(
      validate(history()..['vendorUid'] = 'other') == null,
      'Wrong historical owner',
    );
    require(
      validate(
            live()..['supplierId'] = 'other',
            historical: false,
            supplier: true,
          ) ==
          null,
      'Wrong live owner',
    );
  },
  'missing and malformed dates never become today': () {
    for (final value in [
      null,
      '',
      '2026-02-30',
      '2026-13-01',
      'invalid',
      '2026-09-28T12:00:00',
      '2026-09-28T25:00:00Z',
    ]) {
      require(
        validate(history()..['transactionDateIso'] = value) == null,
        'Invalid date $value',
      );
    }
    final row = live()
      ..remove('createdAt')
      ..['completedAt'] = DateTime.utc(2026, 9, 28);
    require(
      validate(row, historical: false) == null,
      'Completion is not order date',
    );
  },
  'date-only calendar labels and zoned instants are distinguished': () {
    require(
      analyticsRecordDate('2026-09-28') == DateTime.utc(2026, 9, 28),
      'Date only',
    );
    require(
      analyticsRecordDate('2026-09-27T16:00:00Z') == DateTime.utc(2026, 9, 28),
      'Zoned instant',
    );
    require(
      analyticsRecordDate('2026-09-28T00:00:00+08:00') ==
          DateTime.utc(2026, 9, 28),
      'Equivalent business instant',
    );
    require(
      analyticsRecordDate('2024-02-29') != null &&
          analyticsRecordDate('2026-02-29') == null,
      'Leap date validity',
    );
  },
  'missing product and unit cannot receive guessed names or kilograms': () {
    for (final value in [null, '', '  ', 7]) {
      require(
        validate(history()..['productName'] = value) == null,
        'Invalid product',
      );
      require(
        validate(history()..['quantityUnit'] = value) == null,
        'Invalid unit',
      );
    }
    require(
      validate(history()..['quantityUnit'] = 'bucket') == null,
      'Unsupported unit',
    );
  },
  'supported unit aliases normalize without combining units': () {
    require(analyticsQuantityUnit('kg') == 'kilogram', 'Kilogram alias');
    require(analyticsQuantityUnit('tabs') == 'tab', 'Tab alias');
    require(analyticsQuantityUnit('ice boxes') == 'icebox', 'Icebox alias');
  },
  'fulfilled quantity must be finite positive and not exceed requested': () {
    for (final value in [null, 0, -1, double.nan, double.infinity, 'bad', 7]) {
      require(
        validate(history()..['quantityFulfilled'] = value) == null,
        'Invalid fulfilled $value',
      );
    }
  },
  'live requested quantity is never a fulfillment fallback': () {
    final row = live()..remove('fulfilledQuantity');
    require(validate(row, historical: false) == null, 'No requested fallback');
    close(validate(live(), historical: false)!.lines.single.quantity, 4);
  },
  'partial fulfillment uses fulfilled money rather than requested total': () {
    final row = live()..remove('fulfilledTotalAmount');
    close(validate(row, historical: false)!.knownAmount, 400);
    row.remove('unitPrice');
    final result = validate(row, historical: false)!;
    require(
      !result.hasCompleteAmounts && result.lines.single.amount == null,
      'Unknown partial amount is unavailable, not requested total or known zero',
    );
  },
  'valid zero amount is distinct from unavailable amount': () {
    final row = history()..['totalAmount'] = 0;
    final result = validate(row)!;
    require(result.hasCompleteAmounts, 'Zero is a valid monetary value');
    close(result.knownAmount, 0);
  },
  'live terminal and payment contradictions are rejected': () {
    for (final status in ['Pending', 'Accepted', 'Cancelled']) {
      require(
        validate(live()..['orderStatus'] = status, historical: false) == null,
        'Nonterminal status',
      );
    }
    for (final payment in ['Cancelled', 'To be paid on delivery', null, '']) {
      require(
        validate(live()..['paymentStatus'] = payment, historical: false) ==
            null,
        'Impossible payment',
      );
    }
    require(
      validate(live()..['paymentMethod'] = 'online', historical: false) == null,
      'Unsupported payment method',
    );
  },
  'missing Delivered payment is not fabricated, legacy Completed needs evidence':
      () {
        final row = live()..remove('paymentStatus');
        require(
          validate(row, historical: false) != null,
          'Missing payment allowed when absent',
        );
        row['orderStatus'] = 'Completed';
        require(
          validate(row, historical: false) == null,
          'Legacy requires explicit Paid COD',
        );
        row['paymentStatus'] = 'Paid';
        require(
          validate(row, historical: false) != null,
          'Supported paid COD legacy',
        );
      },
  'multi-line order is counted only when every line is valid': () {
    final row = live()
      ..['items'] = [
        {
          'productName': 'Tamban',
          'fulfilledQuantity': 2,
          'quantityUnit': 'kg',
          'unitPrice': 10,
        },
        {
          'productName': 'Bangus',
          'fulfilledQuantity': 3,
          'quantityUnit': 'tab',
          'unitPrice': 20,
        },
      ];
    final result = validate(row, historical: false)!;
    require(result.lines.length == 2, 'Two distinct unit-safe lines');
    close(result.knownAmount, 80);
    (row['items'] as List)[1] = {'productName': 'Bangus', 'quantity': 3};
    require(
      validate(row, historical: false) == null,
      'Do not count partial malformed order',
    );
  },
};
