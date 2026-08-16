import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/screens/supplier/post_fish_stock_screen.dart';
import 'package:isdalink/screens/supplier/supplier_cod_orders_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/stock_notification_service.dart';
import 'package:isdalink/utils/stock_state.dart';

class SupplierDashboardScreen extends StatelessWidget {
  const SupplierDashboardScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  StockNotificationService get stockNotificationService =>
      const StockNotificationService();

  double numberValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String stringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  int createdAtMillis(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final value = document.data()['createdAt'];
    return value is Timestamp ? value.millisecondsSinceEpoch : 0;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> sortStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final result = [...documents];
    result.sort((a, b) => createdAtMillis(b).compareTo(createdAtMillis(a)));
    return result;
  }

  double thresholdFor(Map<String, dynamic> data) {
    final saved = numberValue(data, 'lowStockLevel');
    if (saved > 0) return saved;

    final reference = numberValue(data, 'referenceStockQuantity') > 0
        ? numberValue(data, 'referenceStockQuantity')
        : numberValue(data, 'quantity');
    final percentage = numberValue(data, 'lowStockPercentage') > 0
        ? numberValue(data, 'lowStockPercentage')
        : 20;
    return reference * percentage / 100;
  }

  bool isHidden(Map<String, dynamic> data) {
    return StockState.isIntentionallyHidden(data);
  }

  bool isOutOfStock(Map<String, dynamic> data) {
    return !isHidden(data) && numberValue(data, 'quantity') <= 0;
  }

  bool isLowStock(Map<String, dynamic> data) {
    final quantity = numberValue(data, 'quantity');
    return !isHidden(data) &&
        quantity > 0 &&
        quantity <= thresholdFor(data);
  }

  bool isAvailable(Map<String, dynamic> data) {
    return !isHidden(data) &&
        numberValue(data, 'quantity') > thresholdFor(data);
  }

  String formatNumber(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String productImageUrl(Map<String, dynamic> data) {
    const keys = <String>[
      'imageUrl',
      'productImageUrl',
      'photoUrl',
      'fishImageUrl',
      'image',
    ];

    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
    }

    return '';
  }

  String profileImageUrl(
    Map<String, dynamic> data,
  ) {
    const keys = <String>[
      'profileImageUrl',
      'storePhotoUrl',
      'photoUrl',
    ];

    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';

      if (value.startsWith('http://') ||
          value.startsWith('https://')) {
        return value;
      }
    }

    final application = data['supplierApplication'];

    if (application is Map<String, dynamic>) {
      final value =
          application['storePhotoUrl']?.toString().trim() ?? '';

      if (value.startsWith('http://') ||
          value.startsWith('https://')) {
        return value;
      }
    }

    return '';
  }

  String supplierLocation(
    Map<String, dynamic> data,
  ) {
    final savedLocation = stringValue(
      data,
      'location',
      '',
    );

    if (savedLocation.isNotEmpty) {
      return savedLocation;
    }

    final parts = <String>[
      stringValue(data, 'storeAddress', ''),
      stringValue(data, 'storeCityMunicipality', ''),
      stringValue(data, 'storeProvince', ''),
      'Caraga Region',
    ].where((value) => value.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Caraga Region' : parts.join(', ');
  }

  Supplier supplierFromProfile(
    Map<String, dynamic> data,
    User user,
  ) {
    final supplierName = stringValue(
      data,
      'supplierName',
      stringValue(
        data,
        'storeName',
        stringValue(
          data,
          'businessName',
          user.displayName ?? 'Registered Supplier',
        ),
      ),
    );

    return Supplier(
      name: supplierName,
      location: supplierLocation(data),
      contactNumber: stringValue(
        data,
        'phone',
        stringValue(
          data,
          'contactNumber',
          'No contact number',
        ),
      ),
      description: stringValue(
        data,
        'description',
        'Registered fish supplier in the IsdaLink platform.',
      ),
      rating: numberValue(
        data,
        'rating',
      ),
      reviews: numberValue(
        data,
        'reviews',
      ).round(),
      products: const [],
      profileImageUrl: profileImageUrl(data),
    );
  }

  Future<void> openOwnStore(
    BuildContext context,
  ) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(user.uid)
          .get();

      if (!context.mounted) {
        return;
      }

      if (!profile.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your supplier profile could not be found yet.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final supplier = supplierFromProfile(
        profile.data() ?? <String, dynamic>{},
        user,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupplierDetailsScreen(
            supplier: supplier,
            supplierId: user.uid,
            isOwnerView: true,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open your store: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget viewStoreCard(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFE9F8FD),
            Color(0xFFF2F8FF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFCFE8F3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => openOwnStore(context),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              13,
              12,
              13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0875D1),
                        Color(0xFF12B6D6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'View Store',
                            style: TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 7),
                          _OwnerStoreBadge(),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        'See your public supplier profile exactly as vendors see it.',
                        style: TextStyle(
                          color: Color(0xFF657C8E),
                          fontSize: 9.6,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF0875D1),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void openPostFishStock(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostFishStockScreen()),
    );
  }

  void openManageProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupplierManageProductsScreen(),
      ),
    );
  }

  void openAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnalyticsScreen(
          mode: AnalyticsMode.supplier,
        ),
      ),
    );
  }

  void openOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupplierCodOrdersScreen()),
    );
  }

  void safeBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> stockStream(String uid) {
    return FirebaseFirestore.instance
        .collection('fishStocks')
        .where('supplierId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> orderStream(String uid) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('supplierId', isEqualTo: uid)
        .snapshots();
  }

  int activeOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final status = stringValue(
        document.data(),
        'orderStatus',
        'pending',
      ).toLowerCase();
      return status == 'pending' || status == 'accepted';
    }).length;
  }

  int pendingOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      return stringValue(
            document.data(),
            'orderStatus',
            'pending',
          ).toLowerCase() ==
          'pending';
    }).length;
  }

  Widget header({
    required BuildContext context,
    required int activeListings,
    required int activeCod,
    required int stockAlerts,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06355F),
              Color(0xFF0875D1),
              Color(0xFF176CFF),
            ],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -44,
              top: -38,
              child: _HeaderDecoration(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withAlpha(32),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => safeBack(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUPPLIER CENTER',
                            style: TextStyle(
                              color: Color(0xFFCCF4FF),
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.15,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Supplier Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Manage fish stock, COD orders, and supplier analytics from one place.',
                  style: TextStyle(
                    color: Color(0xFFDDEFFC),
                    fontSize: 11.3,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withAlpha(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      _HeaderMetric(
                        icon: Icons.inventory_2_outlined,
                        value: '$activeListings',
                        label: 'Active Listings',
                      ),
                      const _HeaderDivider(),
                      _HeaderMetric(
                        icon: Icons.receipt_long_outlined,
                        value: '$activeCod',
                        label: 'Active COD',
                      ),
                      const _HeaderDivider(),
                      _HeaderMetric(
                        icon: Icons.notifications_active_outlined,
                        value: '$stockAlerts',
                        label: 'Stock Alerts',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget stockNotificationPanel({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  }) {
    final unread =
        stockNotificationService.unreadStockNotifications(
      notifications,
    );

    if (unread.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = unread.take(2).toList();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBF4),
            Color(0xFFF4FAFF),
          ],
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: const Color(0xFFFFE2B8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E00152A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE1),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFFF7A1A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Notifications',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'New automatic alerts from your published listings.',
                      style: TextStyle(
                        color: Color(0xFF71889A),
                        fontSize: 9.3,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9D5),
                  borderRadius: BorderRadius.circular(
                    99,
                  ),
                ),
                child: Text(
                  unread.length > 9
                      ? '9+ NEW'
                      : '${unread.length} NEW',
                  style: const TextStyle(
                    color: Color(0xFFC45C00),
                    fontSize: 7.8,
                    letterSpacing: 0.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(
            height: 1,
            color: Color(0xFFE8EEF2),
          ),
          ...visible.map(
            (notification) {
              final data = notification.data();
              final title = stringValue(
                data,
                'title',
                'Stock Alert',
              );
              final message = stringValue(
                data,
                'message',
                'A fish listing reached its stock alert level.',
              );
              final stockStatus = stringValue(
                data,
                'stockStatus',
                'lowStock',
              ).toLowerCase();
              final critical =
                  stockStatus == 'outofstock';

              return Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                ),
                child: _AlertRow(
                  icon: critical
                      ? Icons.error_outline_rounded
                      : Icons.inventory_2_outlined,
                  color: critical
                      ? const Color(0xFFD94135)
                      : const Color(0xFFFF7A1A),
                  title: title,
                  subtitle: message,
                  actionLabel: 'Review Stock',
                  onTap: () => openManageProducts(
                    context,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () =>
                  stockNotificationService.markNotificationsRead(
                unread,
              ),
              icon: const Icon(
                Icons.done_all_rounded,
                size: 17,
              ),
              label: const Text(
                'Mark Stock Notifications as Read',
                style: TextStyle(
                  fontSize: 10.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0875D1),
                backgroundColor: const Color(0xFFEAF7FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget alertPanel({
    required BuildContext context,
    required int pending,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> alerts,
  }) {
    if (pending == 0 && alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final outCount = alerts.where((doc) => isOutOfStock(doc.data())).length;
    final lowCount = alerts.length - outCount;

    String stockTitle;
    String stockSubtitle;

    if (alerts.length == 1) {
      final data = alerts.first.data();
      final name = stringValue(data, 'productName', 'Fish Product');
      final quantity = numberValue(data, 'quantity');
      final threshold = thresholdFor(data);
      final unit = stringValue(data, 'quantityUnit', 'kilo');

      if (isOutOfStock(data)) {
        stockTitle = '$name is out of stock';
        stockSubtitle = '0 $unit remaining · Restock this listing.';
      } else {
        stockTitle = '$name reached its stock alert';
        stockSubtitle = '${formatNumber(quantity)} $unit remaining · Alert level: ${formatNumber(threshold)} $unit';
      }
    } else {
      stockTitle = '${alerts.length} stock alerts';
      stockSubtitle = '$lowCount low stock · $outCount out of stock';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E00152A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (pending > 0)
            _AlertRow(
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFD94135),
              title: '$pending pending COD order${pending == 1 ? '' : 's'}',
              subtitle: 'Review and respond to new vendor orders.',
              actionLabel: 'Review Orders',
              onTap: () => openOrders(context),
            ),
          if (pending > 0 && alerts.isNotEmpty)
            const Divider(height: 20, color: Color(0xFFE5EDF2)),
          if (alerts.isNotEmpty)
            _AlertRow(
              icon: Icons.inventory_2_outlined,
              color: outCount > 0
                  ? const Color(0xFFD94135)
                  : const Color(0xFFFF7A1A),
              title: stockTitle,
              subtitle: stockSubtitle,
              actionLabel: 'Review Stock',
              onTap: () => openManageProducts(context),
            ),
        ],
      ),
    );
  }

  Widget toolsGrid({
    required BuildContext context,
    required int activeCod,
    required int stockAlerts,
    required bool hasOutOfStock,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 11,
      mainAxisSpacing: 11,
      childAspectRatio: 1.52,
      children: [
        _ToolCard(
          icon: Icons.add_box_outlined,
          title: 'Post Stock',
          subtitle: 'Create a new fish listing.',
          onTap: () => openPostFishStock(context),
        ),
        _ToolCard(
          icon: Icons.inventory_2_outlined,
          title: 'Products',
          subtitle: 'Manage stock and alert levels.',
          badge: stockAlerts,
          badgeColor: hasOutOfStock
              ? const Color(0xFFD94135)
              : const Color(0xFFFF8A24),
          onTap: () => openManageProducts(context),
        ),
        _ToolCard(
          icon: Icons.receipt_long_outlined,
          title: 'COD Orders',
          subtitle: 'Review incoming vendor orders.',
          badge: activeCod,
          badgeColor: const Color(0xFFD94135),
          onTap: () => openOrders(context),
        ),
        _ToolCard(
          icon: Icons.bar_chart_rounded,
          title: 'Supplier Analytics',
          subtitle: 'Forecasts and stock insights.',
          onTap: () => openAnalytics(context),
        ),
      ],
    );
  }

  Widget stockCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    BuildContext context,
  ) {
    final data = document.data();
    final quantity = numberValue(data, 'quantity');
    final threshold = thresholdFor(data);
    final unit = stringValue(data, 'quantityUnit', 'kilo');
    final name = stringValue(data, 'productName', 'Fish Product');
    final emoji = stringValue(data, 'emoji', '🐟');
    final imageUrl = productImageUrl(data);
    final price = numberValue(data, 'price');
    final hidden = isHidden(data);
    final out = isOutOfStock(data);
    final low = isLowStock(data);
    final status = hidden
        ? 'Hidden'
        : out
            ? 'Out of Stock'
            : low
                ? 'Low Stock'
                : 'Available';
    final color = hidden
        ? const Color(0xFF71889A)
        : out
            ? const Color(0xFFD94135)
            : low
                ? const Color(0xFFFF7A1A)
                : const Color(0xFF2E7D32);

    Widget fallbackImage() {
      return Container(
        color: const Color(0xFFEAF8FC),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 27),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => openManageProducts(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE1ECF2)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: imageUrl.isEmpty
                        ? fallbackImage()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => fallbackImage(),
                          ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 13.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontSize: 8.6,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${formatNumber(price)} per $unit',
                        style: const TextStyle(
                          color: Color(0xFF0875D1),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${formatNumber(quantity)} $unit remaining',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF526B7F),
                          fontSize: 9.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Alert level: ${formatNumber(threshold)} $unit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8194A4),
                          fontSize: 8.9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  tooltip: 'Manage stock',
                  onPressed: () => openManageProducts(context),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0875D1),
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dashboardBody({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  }) {
    final sortedStocks = sortStocks(stocks);
    final activeListings = sortedStocks.where((doc) {
      final data = doc.data();
      return !isHidden(data) && numberValue(data, 'quantity') > 0;
    }).length;
    final alerts = sortedStocks.where((doc) {
      return isLowStock(doc.data()) || isOutOfStock(doc.data());
    }).toList();
    final activeCod = activeOrders(orders);
    final pending = pendingOrders(orders);
    final hasOutOfStock = alerts.any((doc) => isOutOfStock(doc.data()));

    return Column(
      children: [
        header(
          context: context,
          activeListings: activeListings,
          activeCod: activeCod,
          stockAlerts: alerts.length,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              stockNotificationPanel(
                context: context,
                notifications: notifications,
              ),
              alertPanel(
                context: context,
                pending: pending,
                alerts: alerts,
              ),
              viewStoreCard(context),
              const _SectionHeading(
                title: 'Supplier Tools',
                subtitle: 'Quick access to daily supplier operations.',
              ),
              const SizedBox(height: 8),
              toolsGrid(
                context: context,
                activeCod: activeCod,
                stockAlerts: alerts.length,
                hasOutOfStock: hasOutOfStock,
              ),
              const SizedBox(height: 18),
              _SectionHeading(
                title: 'Current Stock Posts',
                subtitle: 'Listings managed by this supplier account.',
                trailing: '${sortedStocks.length} listing${sortedStocks.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 10),
              if (sortedStocks.isEmpty)
                const _EmptyStockCard()
              else
                ...sortedStocks.map((doc) => stockCard(doc, context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingBody(BuildContext context) {
    return Column(
      children: [
        header(
          context: context,
          activeListings: 0,
          activeCod: 0,
          stockAlerts: 0,
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF0875D1)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8FB),
        body: Center(
          child: Text('Please log in first to view the Supplier Dashboard.'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) safeBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stockStream(user.uid),
          builder: (context, stockSnapshot) {
            if (stockSnapshot.hasError) {
              return Center(child: Text('Unable to load stock: ${stockSnapshot.error}'));
            }
            if (!stockSnapshot.hasData) {
              return loadingBody(context);
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: orderStream(user.uid),
              builder: (context, orderSnapshot) {
                final orders = orderSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: stockNotificationService.notificationsStream(
                    user.uid,
                  ),
                  builder: (
                    context,
                    notificationSnapshot,
                  ) {
                    final notifications =
                        notificationSnapshot.data?.docs ??
                            <QueryDocumentSnapshot<
                                Map<String, dynamic>>>[];

                    return dashboardBody(
                      context: context,
                      stocks: stockSnapshot.data!.docs,
                      orders: orders,
                      notifications: notifications,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OwnerStoreBadge extends StatelessWidget {
  const _OwnerStoreBadge();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F6EE),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'YOUR STORE',
        style: TextStyle(
          color: Color(0xFF147D64),
          fontSize: 7.2,
          letterSpacing: 0.45,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderDecoration extends StatelessWidget {
  const _HeaderDecoration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Center(
        child: Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(18)),
          ),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDDEFFC),
              fontSize: 8.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 43,
      color: Colors.white.withAlpha(28),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.actionLabel,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF71889A),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withAlpha(16),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: color,
                  fontSize: 8.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Icon(Icons.arrow_forward_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
    this.badgeColor = const Color(0xFFFF4D3D),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1ECF2)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8FD),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: const Color(0xFF0875D1), size: 19),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 11.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF71889A),
                      fontSize: 8.7,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (badge > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8194A4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FD),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: Color(0xFF0875D1),
                fontSize: 9.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyStockCard extends StatelessWidget {
  const _EmptyStockCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECF2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Color(0xFF0875D1), size: 30),
          SizedBox(height: 10),
          Text(
            'No stock posts yet',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Post fish stock to start receiving vendor COD orders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF71889A),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
