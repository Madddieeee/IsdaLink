import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'delivered notification asks the vendor to review without duplication',
    () {
      final service = File(
        'lib/services/supplier_order_service.dart',
      ).readAsStringSync();
      final panel = File(
        'lib/screens/vendor/my_orders/widgets/order_notification_panel.dart',
      ).readAsStringSync();

      expect(service, contains("return 'Review Your Order';"));
      expect(service, contains('Tap to rate your order'));
      expect(panel, contains('onNotificationTap'));
      expect(panel, contains('Icons.rate_review_rounded'));
    },
  );
}
