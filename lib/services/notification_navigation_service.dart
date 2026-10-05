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

    final destination = destinationFor(data);

    if (destination == null) {
      return false;
    }

    navigator.push(MaterialPageRoute<void>(builder: (_) => destination));
    return true;
  }

  static bool openFromContext({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    final destination = destinationFor(data);

    if (destination == null) {
      return false;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
    return true;
  }

  static Widget? destinationFor(Map<String, dynamic> data) {
    final type = _value(data, 'type').toLowerCase();
    final status = _value(data, 'status').toLowerCase();
    final orderId = _value(data, 'orderId');
    final subjectId = _value(data, 'subjectId');
    final notificationId = _value(data, 'notificationId');
    final unreadCount = int.tryParse(_value(data, 'unreadCount')) ?? 1;
    final grouped =
        _value(data, 'grouped').toLowerCase() == 'true' || unreadCount > 1;

    switch (type) {
      case 'new_order':
        return SupplierCodOrdersScreen(
          initialOrderId: grouped ? '' : orderId,
        );
      case 'order_status':
        return MyOrdersScreen(initialOrderId: grouped ? '' : orderId);
      case 'stock_alert':
        return const SupplierManageProductsScreen();
      case 'admin_supplier_application':
        return const AdminDashboardScreen();
      case 'admin_supplier_change_request':
        return subjectId.isEmpty
            ? const AdminDashboardScreen()
            : SupplierChangeRequestReviewScreen(supplierId: subjectId);
      case 'supplier_profile_change':
        return const SupplierProfileScreen();
      case 'supplier_application_status':
        return status == 'approved'
            ? const SupplierProfileScreen()
            : SupplierActivationScreen(
                rejectionNotificationId: notificationId,
              );
      default:
        return null;
    }
  }

  static String _value(Map<String, dynamic> data, String key) {
    return data[key]?.toString().trim() ?? '';
  }
}
