import 'package:flutter/material.dart';
import 'package:isdalink/screens/admin/admin_dashboard_screen.dart';
import 'package:isdalink/screens/admin/supplier_change_request_review_screen.dart';
import 'package:isdalink/screens/profile/supplier_profile_screen.dart';
import 'package:isdalink/screens/supplier/activation/supplier_activation_screen.dart';
import 'package:isdalink/screens/supplier/supplier_cod_orders_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';

class NotificationNavigationService {
  const NotificationNavigationService._();

  static bool open({
    required GlobalKey<NavigatorState> navigatorKey,
    required Map<String, dynamic> data,
  }) {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      return false;
    }

    final type = _value(data, 'type').toLowerCase();
    final status = _value(data, 'status').toLowerCase();
    final orderId = _value(data, 'orderId');
    final subjectId = _value(data, 'subjectId');
    final notificationId = _value(data, 'notificationId');
    final unreadCount = int.tryParse(_value(data, 'unreadCount')) ?? 1;
    final grouped = _value(data, 'grouped').toLowerCase() == 'true' ||
        unreadCount > 1;

    Widget? destination;

    switch (type) {
      case 'new_order':
        destination = SupplierCodOrdersScreen(
          initialOrderId: grouped ? '' : orderId,
        );
        break;
      case 'order_status':
        destination = MyOrdersScreen(
          initialOrderId: grouped ? '' : orderId,
        );
        break;
      case 'stock_alert':
        destination = const SupplierManageProductsScreen();
        break;
      case 'admin_supplier_application':
        destination = const AdminDashboardScreen();
        break;
      case 'admin_supplier_change_request':
        destination = subjectId.isEmpty
            ? const AdminDashboardScreen()
            : SupplierChangeRequestReviewScreen(
                supplierId: subjectId,
              );
        break;
      case 'supplier_profile_change':
        destination = const SupplierProfileScreen();
        break;
      case 'supplier_application_status':
        destination = status == 'approved'
            ? const SupplierProfileScreen()
            : SupplierActivationScreen(
                rejectionNotificationId: notificationId,
              );
        break;
    }

    if (destination == null) {
      return false;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => destination!,
      ),
    );

    return true;
  }

  static String _value(
    Map<String, dynamic> data,
    String key,
  ) {
    return data[key]?.toString().trim() ?? '';
  }
}
