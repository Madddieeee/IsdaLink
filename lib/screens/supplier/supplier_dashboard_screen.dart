import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/analytics/supplier_analytics_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/screens/supplier/post_fish_stock_screen.dart';
import 'package:isdalink/screens/supplier/supplier_cod_orders_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/profile/supplier_profile_screen.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/supplier_dashboard_service.dart';
import 'package:isdalink/services/supplier_notification_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class SupplierDashboardScreen extends StatelessWidget {
  const SupplierDashboardScreen({super.key});

  User? get currentUser => FirebaseAuth.instance.currentUser;

  SupplierDashboardService get dashboardService =>
      const SupplierDashboardService();

  SupplierNotificationService get supplierNotificationService =>
      const SupplierNotificationService();

  double numberValue(Map<String, dynamic> data, String key) =>
      dashboardService.numberValue(data, key);

  String stringValue(Map<String, dynamic> data, String key, String fallback) =>
      dashboardService.stringValue(data, key, fallback);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> sortStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) => dashboardService.sortStocks(documents);

  double thresholdFor(Map<String, dynamic> data) =>
      dashboardService.thresholdFor(data);

  bool isHidden(Map<String, dynamic> data) => dashboardService.isHidden(data);

  bool isOutOfStock(Map<String, dynamic> data) =>
      dashboardService.isOutOfStock(data);

  bool isLowStock(Map<String, dynamic> data) =>
      dashboardService.isLowStock(data);

  bool isAvailable(Map<String, dynamic> data) =>
      dashboardService.isAvailable(data);

  String formatNumber(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String formatPrice(double value) {
    final raw = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
    final parts = raw.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();

    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[index]);
    }

    return parts.length > 1
        ? '${buffer.toString()}.${parts[1]}'
        : buffer.toString();
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

  String profileImageUrl(Map<String, dynamic> data) {
    final value = data['profileImageUrl']?.toString().trim() ?? '';
    return value.startsWith('https://') ? value : '';
  }

  String coverImageUrl(Map<String, dynamic> data) {
    if (data['coverImageSetByOwner'] != true) {
      return '';
    }

    final value = data['coverImageUrl']?.toString().trim() ?? '';
    return value.startsWith('https://') ? value : '';
  }

  String supplierLocation(Map<String, dynamic> data) =>
      dashboardService.supplierLocation(data);

  Supplier supplierFromProfile(Map<String, dynamic> data, User user) {
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
        stringValue(data, 'contactNumber', 'No contact number'),
      ),
      description: stringValue(
        data,
        'description',
        'Registered fish supplier in the IsdaLink platform.',
      ),
      rating: numberValue(data, 'rating'),
      reviews: numberValue(data, 'reviews').round(),
      products: const [],
      profileImageUrl: profileImageUrl(data),
      coverImageUrl: coverImageUrl(data),
      accountCreatedAt: data['accountCreatedAt'] is Timestamp
          ? (data['accountCreatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  void openSupplierProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupplierProfileScreen()),
    );
  }

  Future<void> openOwnStore(BuildContext context) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final profile = await dashboardService.supplierProfile(user.uid);

      if (!context.mounted) {
        return;
      }

      if (!profile.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your supplier profile could not be found yet.'),
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
            AppErrorMessage.from(
              error,
              fallback:
                  'Unable to open your supplier store right now. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget storeManagementCard(
    BuildContext context, {
    required Map<String, dynamic> profileData,
    required int unreadProfileChanges,
  }) {
    final user = currentUser;
    final storeName = user == null
        ? 'Your Supplier Store'
        : stringValue(
            profileData,
            'supplierName',
            stringValue(
              profileData,
              'storeName',
              stringValue(
                profileData,
                'businessName',
                user.displayName ?? 'Your Supplier Store',
              ),
            ),
          );
    final imageUrl = profileImageUrl(profileData);
    final location = supplierLocation(profileData);
    final initial = storeName.trim().isEmpty
        ? 'S'
        : storeName.trim().substring(0, 1).toUpperCase();

    Widget storeImage() {
      if (imageUrl.isEmpty) {
        return Container(
          color: const Color(0xFFE8F6FC),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF0875D1),
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFE8F6FC),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF0875D1),
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDEAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10052C4F),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(width: 66, height: 66, child: storeImage()),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'VERIFIED SUPPLIER',
                          style: TextStyle(
                            color: Color(0xFF6B8496),
                            fontSize: 8.2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.85,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF12976F),
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0E2B45),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF71889A),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF71889A),
                              fontSize: 9.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFE6EEF3)),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _StoreActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'View Store',
                  onTap: () => openOwnStore(context),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _StoreActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit Store',
                  filled: true,
                  showDot: unreadProfileChanges > 0,
                  onTap: () => openSupplierProfile(context),
                ),
              ),
            ],
          ),
        ],
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
      MaterialPageRoute(builder: (_) => const SupplierManageProductsScreen()),
    );
  }

  void openAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupplierAnalyticsScreen()),
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

  Stream<QuerySnapshot<Map<String, dynamic>>> stockStream(String uid) =>
      dashboardService.stockStream(uid);

  Stream<QuerySnapshot<Map<String, dynamic>>> orderStream(String uid) =>
      dashboardService.orderStream(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> supplierProfileStream(
    String uid,
  ) => dashboardService.supplierProfileStream(uid);

  int activeOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) => dashboardService.activeOrders(documents);

  int pendingOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) => dashboardService.pendingOrders(documents);

  Widget dashboardHeaderSliver({
    required BuildContext context,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;
    const expandedHeight = 184.0;
    const toolbarHeight = 52.0;
    final collapsedHeight = topPadding + toolbarHeight;

    return SliverAppBar(
      pinned: false,
      floating: false,
      snap: false,
      stretch: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF073E69),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      expandedHeight: expandedHeight,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF073E69),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final range = expandedHeight - collapsedHeight;
          final progress = range <= 0
              ? 0.0
              : ((constraints.maxHeight - collapsedHeight) / range)
                    .clamp(0.0, 1.0)
                    .toDouble();
          final compactOpacity = (1 - progress * 2.25)
              .clamp(0.0, 1.0)
              .toDouble();
          final expandedOpacity = ((progress - 0.16) / 0.84)
              .clamp(0.0, 1.0)
              .toDouble();
          final navButtonSize = 38.0 + (6.0 * progress);
          final navIconSize = 21.0 + (2.0 * progress);
          final logoWidth = 72.0 + (20.0 * progress);
          final logoHeight = 30.0 + (8.0 * progress);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/home_header_boat.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF06355F),
                        Color(0xFF0875D1),
                        Color(0xFF12A7D1),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF052D4D).withValues(alpha: 0.38),
                      const Color(0xFF073F67).withValues(alpha: 0.50),
                      const Color(0xFF075C89).withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Row(
                      children: [
                        Material(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                          child: InkWell(
                            onTap: () => safeBack(context),
                            borderRadius: BorderRadius.circular(13),
                            child: Container(
                              width: navButtonSize,
                              height: navButtonSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: navIconSize,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Opacity(
                            opacity: compactOpacity,
                            child: const Text(
                              'Supplier Dashboard',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: logoWidth,
                          height: logoHeight,
                          child: Image.asset(
                            'assets/images/isdalink_logo.png',
                            fit: BoxFit.contain,
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                            errorBuilder: (_, _, _) => const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.set_meal_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'IsdaLink',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: IgnorePointer(
                  ignoring: progress < 0.30,
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUPPLIER WORKSPACE',
                          style: TextStyle(
                            color: Color(0xFFD2F4FB),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.55,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Supplier Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.55,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Manage stock, COD orders, and sales insights in one place.',
                          style: TextStyle(
                            color: Color(0xFFE2F4FA),
                            fontSize: 10.5,
                            height: 1.30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget summaryMetricsCard({
    required BuildContext context,
    required int activeListings,
    required int activeCod,
    required int stockAlerts,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0EBF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E052C4F),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: SizedBox(
        height: 70,
        child: Row(
          children: [
            _HeaderMetric(
              icon: Icons.inventory_2_outlined,
              value: '$activeListings',
              label: 'Listings',
              accent: const Color(0xFF0875D1),
              softColor: const Color(0xFFE7F3FF),
              onTap: () => openManageProducts(context),
            ),
            const SizedBox(width: 7),
            _HeaderMetric(
              icon: Icons.receipt_long_outlined,
              value: '$activeCod',
              label: 'Orders',
              accent: const Color(0xFF118B72),
              softColor: const Color(0xFFE6F7F2),
              onTap: () => openOrders(context),
            ),
            const SizedBox(width: 7),
            _HeaderMetric(
              icon: Icons.warning_amber_rounded,
              value: '$stockAlerts',
              label: 'Alerts',
              accent: stockAlerts > 0
                  ? const Color(0xFFD94A3A)
                  : const Color(0xFF6D8293),
              softColor: stockAlerts > 0
                  ? const Color(0xFFFFEAE6)
                  : const Color(0xFFF0F4F6),
              onTap: () => openManageProducts(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileChangeNotificationPanel({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  }) {
    final unread = supplierNotificationService.unreadProfileChangeNotifications(
      notifications,
    );

    if (unread.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = unread.first.data();
    final status = stringValue(latest, 'status', 'approved').toLowerCase();
    final approved = status == 'approved';
    final color = approved ? const Color(0xFF138563) : const Color(0xFFB94B45);
    final background = approved
        ? const Color(0xFFF0FAF6)
        : const Color(0xFFFFF2F0);
    final title = stringValue(
      latest,
      'title',
      approved
          ? 'Supplier profile update approved'
          : 'Supplier profile update needs attention',
    );
    final message = stringValue(
      latest,
      'message',
      approved
          ? 'Your approved business details are now live.'
          : 'Open your supplier profile to review the Admin note.',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        onTap: () => openSupplierProfile(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  approved ? Icons.verified_rounded : Icons.edit_note_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF71889A),
                        fontSize: 9.1,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unread.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${unread.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 8.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget stockNotificationPanel({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  }) {
    final unread = supplierNotificationService.unreadStockNotifications(
      notifications,
    );

    if (unread.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = unread.first.data();
    final title = stringValue(latest, 'title', 'Stock update');
    final message = stringValue(
      latest,
      'message',
      'A published listing reached its stock alert level.',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE1B8)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEDB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFE67A19),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => openManageProducts(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unread.length == 1 ? title : '${unread.length} new stock updates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF71889A),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                supplierNotificationService.markNotificationsRead(unread),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC66A12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Read',
              style: TextStyle(fontSize: 8.8, fontWeight: FontWeight.w900),
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
        stockSubtitle = 'Restock this listing so vendors can order again.';
      } else {
        stockTitle = '$name is running low';
        stockSubtitle =
            '${formatNumber(quantity)} $unit left · Alert level ${formatNumber(threshold)} $unit';
      }
    } else {
      stockTitle = '${alerts.length} listings need stock attention';
      stockSubtitle = '$lowCount low stock · $outCount out of stock';
    }

    return Column(
      children: [
        if (pending > 0)
          _PriorityNoticeCard(
            icon: Icons.local_shipping_outlined,
            accent: const Color(0xFFE5533D),
            softColor: const Color(0xFFFFEEE9),
            title: '$pending pending COD order${pending == 1 ? '' : 's'}',
            subtitle: pending == 1
                ? 'A vendor is waiting for your confirmation.'
                : 'Vendors are waiting for your confirmation.',
            actionLabel: 'Review Orders',
            onTap: () => openOrders(context),
          ),
        if (pending > 0 && alerts.isNotEmpty) const SizedBox(height: 10),
        if (alerts.isNotEmpty)
          _PriorityNoticeCard(
            icon: outCount > 0
                ? Icons.error_outline_rounded
                : Icons.inventory_2_outlined,
            accent: outCount > 0
                ? const Color(0xFFD94135)
                : const Color(0xFFE78A1D),
            softColor: outCount > 0
                ? const Color(0xFFFFEEEE)
                : const Color(0xFFFFF5E5),
            title: stockTitle,
            subtitle: stockSubtitle,
            actionLabel: 'Review Stock',
            onTap: () => openManageProducts(context),
          ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget toolsGrid({
    required BuildContext context,
    required int activeCod,
    required int stockAlerts,
    required bool hasOutOfStock,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
        final cardHeight = 108 + ((textScale - 1) * 36);

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          primary: false,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: cardWidth / cardHeight,
          children: [
            _ToolCard(
              icon: Icons.add_rounded,
              title: 'Post Stock',
              subtitle: 'Add a new fish listing',
              accent: const Color(0xFF0875D1),
              softColor: const Color(0xFFE6F3FF),
              onTap: () => openPostFishStock(context),
            ),
            _ToolCard(
              icon: Icons.inventory_2_outlined,
              title: 'Products',
              subtitle: 'Manage listings and stock',
              accent: const Color(0xFF0D9272),
              softColor: const Color(0xFFE5F7F1),
              badge: stockAlerts,
              badgeColor: hasOutOfStock
                  ? const Color(0xFFD94135)
                  : const Color(0xFFE78A1D),
              onTap: () => openManageProducts(context),
            ),
            _ToolCard(
              icon: Icons.receipt_long_outlined,
              title: 'COD Orders',
              subtitle: 'Review incoming orders',
              accent: const Color(0xFFE05A40),
              softColor: const Color(0xFFFFECE7),
              badge: activeCod,
              badgeColor: const Color(0xFFD94135),
              onTap: () => openOrders(context),
            ),
            _ToolCard(
              icon: Icons.insights_rounded,
              title: 'Analytics',
              subtitle: 'Sales trends and forecasts',
              accent: const Color(0xFF6A5CE7),
              softColor: const Color(0xFFEFECFF),
              onTap: () => openAnalytics(context),
            ),
          ],
        );
      },
    );
  }

  Widget stockCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    BuildContext context,
  ) {
    final data = document.data();
    final quantity = numberValue(data, 'quantity');
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
        : 'In Stock';
    final color = hidden
        ? const Color(0xFF71889A)
        : out
        ? const Color(0xFFD94135)
        : low
        ? const Color(0xFFE78A1D)
        : const Color(0xFF16845C);

    Widget fallbackImage() {
      return Container(
        color: const Color(0xFFEAF8FC),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 27)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => openManageProducts(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EBF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x09052C4F),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 56,
                    height: 56,
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
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 12.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₱${formatPrice(price)} / $unit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0875D1),
                          fontSize: 10.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hidden
                            ? 'Not visible to vendors'
                            : '${formatNumber(quantity)} $unit available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hidden
                              ? const Color(0xFF71889A)
                              : out
                              ? const Color(0xFFD94135)
                              : low
                              ? const Color(0xFFB86A16)
                              : const Color(0xFF607789),
                          fontSize: 9.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontSize: 8.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 32,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF7FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        tooltip: 'Manage stock',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => openManageProducts(context),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF0875D1),
                          size: 17,
                        ),
                      ),
                    ),
                  ],
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
    required Map<String, dynamic> profileData,
  }) {
    final sortedStocks = sortStocks(stocks);
    final activeListings = dashboardService.activeListings(sortedStocks);
    final alerts = dashboardService.stockAlerts(sortedStocks);
    final activeCod = activeOrders(orders);
    final pending = pendingOrders(orders);
    final hasOutOfStock = alerts.any((doc) => isOutOfStock(doc.data()));
    final unreadProfileChanges = supplierNotificationService
        .unreadProfileChangeNotifications(notifications);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        dashboardHeaderSliver(context: context),
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFF0A5B84),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7FAFC),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1800152A),
                    blurRadius: 22,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 54),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summaryMetricsCard(
                    context: context,
                    activeListings: activeListings,
                    activeCod: activeCod,
                    stockAlerts: alerts.length,
                  ),
                  alertPanel(
                    context: context,
                    pending: pending,
                    alerts: alerts,
                  ),
                  profileChangeNotificationPanel(
                    context: context,
                    notifications: notifications,
                  ),
                  storeManagementCard(
                    context,
                    profileData: profileData,
                    unreadProfileChanges: unreadProfileChanges.length,
                  ),
                  const _SectionHeading(
                    title: 'Quick Actions',
                    subtitle: 'Everything you need for today’s supplier work.',
                  ),
                  const SizedBox(height: 11),
                  toolsGrid(
                    context: context,
                    activeCod: activeCod,
                    stockAlerts: alerts.length,
                    hasOutOfStock: hasOutOfStock,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeading(
                    title: 'Current Stock',
                    subtitle: 'See what needs attention before your next sale.',
                    trailing: sortedStocks.length > 4
                        ? 'View all (${sortedStocks.length})'
                        : '${sortedStocks.length} listing${sortedStocks.length == 1 ? '' : 's'}',
                    onTrailingTap: sortedStocks.length > 4
                        ? () => openManageProducts(context)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (sortedStocks.isEmpty)
                    const _EmptyStockCard()
                  else
                    ...sortedStocks.take(4).map(
                          (doc) => stockCard(doc, context),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget loadingBody(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        dashboardHeaderSliver(context: context),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            color: const Color(0xFF0A5B84),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFF7FAFC),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1800152A),
                    blurRadius: 22,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0875D1)),
              ),
            ),
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
        if (!didPop) {
          safeBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stockStream(user.uid),
          builder: (context, stockSnapshot) {
            if (stockSnapshot.hasError) {
              return Container(
                color: const Color(0xFFF7FAFC),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppErrorMessage.from(
                      stockSnapshot.error!,
                      fallback:
                          'Unable to load your supplier dashboard right now. Please try again.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }
            if (!stockSnapshot.hasData) {
              return loadingBody(context);
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: orderStream(user.uid),
              builder: (context, orderSnapshot) {
                final orders =
                    orderSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: supplierNotificationService.notificationsStream(
                    user.uid,
                  ),
                  builder: (context, notificationSnapshot) {
                    final notifications =
                        notificationSnapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                    return StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      stream: supplierProfileStream(user.uid),
                      builder: (context, profileSnapshot) {
                        return dashboardBody(
                          context: context,
                          stocks: stockSnapshot.data!.docs,
                          orders: orders,
                          notifications: notifications,
                          profileData:
                              profileSnapshot.data?.data() ??
                              <String, dynamic>{},
                        );
                      },
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

class _StoreActionButton extends StatelessWidget {
  const _StoreActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0875D1);

    return Material(
      color: filled ? accent : const Color(0xFFF1F8FC),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: filled ? null : Border.all(color: const Color(0xFFD7E9F3)),
          ),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: filled ? Colors.white : accent,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: filled ? Colors.white : accent,
                        fontSize: 9.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDot)
                Positioned(
                  right: 1,
                  top: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD24D),
                      shape: BoxShape.circle,
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

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.softColor,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final Color softColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: softColor,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 17),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 18,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6D8293),
                              fontSize: 8.1,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityNoticeCard extends StatelessWidget {
  const _PriorityNoticeCard({
    required this.icon,
    required this.accent,
    required this.softColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final Color softColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 11.7,
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
                    fontSize: 9.2,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
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
    required this.accent,
    required this.softColor,
    required this.onTap,
    this.badge = 0,
    this.badgeColor = const Color(0xFFFF4D3D),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color softColor;
  final VoidCallback onTap;
  final int badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE1EBF1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09052C4F),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: const Color(0xFF91A4B2),
                        size: 19,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 11.4,
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
                      fontSize: 8.6,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (badge > 0)
                Positioned(
                  right: 18,
                  top: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.3,
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
    this.onTrailingTap,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
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
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8194A4),
                  fontSize: 9.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Material(
            color: onTrailingTap == null
                ? const Color(0xFFF0F6F9)
                : const Color(0xFFE9F6FD),
            borderRadius: BorderRadius.circular(99),
            child: InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailing!,
                      style: TextStyle(
                        color: onTrailingTap == null
                            ? const Color(0xFF71889A)
                            : const Color(0xFF0875D1),
                        fontSize: 8.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (onTrailingTap != null) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF0875D1),
                        size: 13,
                      ),
                    ],
                  ],
                ),
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
