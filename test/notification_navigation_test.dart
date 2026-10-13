import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/profile/me_screen.dart';
import 'package:isdalink/screens/supplier/activation/supplier_activation_screen.dart';
import 'package:isdalink/services/notification_navigation_service.dart';

void main() {
  test('approved supplier notification opens Account Center approval flow', () {
    final destination = NotificationNavigationService.destinationFor(
      const <String, dynamic>{
        'type': 'supplier_application_status',
        'status': 'approved',
      },
    );

    expect(destination, isA<MeScreen>());
  });

  test('rejected supplier notification opens activation correction flow', () {
    final destination =
        NotificationNavigationService.destinationFor(const <String, dynamic>{
          'type': 'supplier_application_status',
          'status': 'rejected',
          'notificationId': 'notification-1',
        });

    expect(destination, isA<SupplierActivationScreen>());
  });
}
