import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'package:isdalink/screens/home/widgets/home_bottom_nav.dart';
import 'package:isdalink/screens/home/widgets/home_header.dart';
import 'package:isdalink/screens/home/widgets/home_section_header.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_posts.dart';
import 'package:isdalink/screens/home/widgets/recommended_supplier_card.dart';
import 'package:isdalink/screens/home/widgets/top_selling_fish_strip.dart';
import 'package:isdalink/screens/profile/me_screen.dart';
import 'package:isdalink/screens/vendor/browse_suppliers_screen.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/supplier_browse_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  SupplierBrowseService get supplierService => const SupplierBrowseService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> logout(
    BuildContext context,
  ) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  void openAnalytics(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnalyticsScreen(),
      ),
    );
  }

  void openBrowseSuppliers(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BrowseSuppliersScreen(),
      ),
    );
  }

  void openMyOrders(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyOrdersScreen(),
      ),
    );
  }

  void openMe(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MeScreen(),
      ),
    );
  }

  void openSupplierDetails(
    BuildContext context,
    Supplier supplier, {
    String? supplierId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailsScreen(
          supplier: supplier,
          supplierId: supplierId,
        ),
      ),
    );
  }

  void openProductDetails(
    BuildContext context,
    Supplier supplier,
    FishProduct product, {
    String stockId = '',
    String supplierId = '',
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          supplier: supplier,
          product: product,
          stockId: stockId,
          supplierId: supplierId,
        ),
      ),
    );
  }

  Widget recommendedSuppliersList(
    BuildContext context,
  ) {
    return SizedBox(
      height: 166,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: supplierService.suppliersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.only(left: 14),
              scrollDirection: Axis.horizontal,
              children: [
                homeSupplierMessageCard(
                  icon: Icons.error_outline,
                  title: 'Unable to load suppliers',
                  subtitle: '${snapshot.error}',
                  isError: true,
                ),
              ],
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            );
          }

          final approvedSuppliers = supplierService
              .approvedSuppliers(
                snapshot.data!.docs,
              )
              .take(5)
              .toList();

          if (approvedSuppliers.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(left: 14),
              scrollDirection: Axis.horizontal,
              children: [
                homeSupplierMessageCard(
                  icon: Icons.storefront_outlined,
                  title: 'No approved suppliers yet',
                  subtitle:
                      'Approved supplier profiles from Firebase will appear here.',
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.only(left: 14),
            scrollDirection: Axis.horizontal,
            children: approvedSuppliers.map(
              (document) {
                final data = document.data();
                final supplier = supplierService.supplierFromProfile(data);

                return RecommendedSupplierCard(
                  supplier: supplier,
                  onTap: () => openSupplierDetails(
                    context,
                    supplier,
                    supplierId: document.id,
                  ),
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }

  Widget homeSupplierMessageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isError ? const Color(0xFFD32F2F) : const Color(0xFF087AC0),
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget todayOverview(
    BuildContext context,
  ) {
    final uid = currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: OverviewCountCard(
              title: 'Suppliers',
              icon: Icons.storefront,
              stream:
                  FirebaseFirestore.instance.collection('supplierProfiles').snapshots(),
              countBuilder: (docs) {
                return docs.where(
                  (doc) {
                    final data = doc.data();

                    final status =
                        (data['status'] ?? '').toString().toLowerCase();

                    final verificationStatus =
                        (data['verificationStatus'] ?? '')
                            .toString()
                            .toLowerCase();

                    return status == 'approved' ||
                        verificationStatus == 'approved';
                  },
                ).length;
              },
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: OverviewCountCard(
              title: 'Fish Posts',
              icon: Icons.set_meal,
              stream: FirebaseFirestore.instance.collection('fishStocks').snapshots(),
              countBuilder: (docs) {
                return docs.where(
                  (doc) {
                    final data = doc.data();

                    final status = (data['status'] ?? 'available')
                        .toString()
                        .toLowerCase();

                    final quantity = double.tryParse(
                          (data['quantity'] ?? 0).toString(),
                        ) ??
                        0;

                    return status != 'unavailable' && quantity > 0;
                  },
                ).length;
              },
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: uid == null
                ? const StaticOverviewCard(
                    title: 'Active Orders',
                    value: '0',
                    icon: Icons.receipt_long,
                  )
                : OverviewCountCard(
                    title: 'Active Orders',
                    icon: Icons.receipt_long,
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('vendorId', isEqualTo: uid)
                        .snapshots(),
                    countBuilder: (docs) {
                      return docs.where(
                        (doc) {
                          final status = (doc.data()['orderStatus'] ?? '')
                              .toString()
                              .toLowerCase();

                          return status == 'pending' || status == 'accepted';
                        },
                      ).length;
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HomeHeader(
                  onLogout: () => logout(context),
                  onSearchTap: () => openBrowseSuppliers(context),
                  onProfileTap: () => openMe(context),
                ),
                const SizedBox(height: 12),
                todayOverview(context),
                const SizedBox(height: 12),
                TopSellingFishStrip(
                  onProductTap: (
                    supplier,
                    product,
                    stockId,
                    supplierId,
                  ) {
                    openProductDetails(
                      context,
                      supplier,
                      product,
                      stockId: stockId,
                      supplierId: supplierId,
                    );
                  },
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: HomeSectionHeader(
                    title: 'Top Recommended Suppliers',
                    icon: Icons.verified,
                    actionLabel: 'View all suppliers',
                    onViewAll: () => openBrowseSuppliers(context),
                  ),
                ),
                const SizedBox(height: 10),
                recommendedSuppliersList(context),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: HomeSectionHeader(
                    title: 'Recent Fish Posts',
                    icon: Icons.set_meal,
                  ),
                ),
                const SizedBox(height: 10),
                RecentFishPosts(
                  onProductTap: (
                    supplier,
                    product,
                    stockId,
                    supplierId,
                  ) {
                    openProductDetails(
                      context,
                      supplier,
                      product,
                      stockId: stockId,
                      supplierId: supplierId,
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          HomeBottomNav(
            onMyOrders: () => openMyOrders(context),
            onAnalytics: () => openAnalytics(context),
            onMe: () => openMe(context),
          ),
        ],
      ),
    );
  }
}

class OverviewCountCard extends StatelessWidget {
  const OverviewCountCard({
    super.key,
    required this.title,
    required this.icon,
    required this.stream,
    required this.countBuilder,
  });

  final String title;
  final IconData icon;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final int Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs)
      countBuilder;

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final value =
            snapshot.hasData ? '${countBuilder(snapshot.data!.docs)}' : '--';

        return StaticOverviewCard(
          title: title,
          value: value,
          icon: icon,
        );
      },
    );
  }
}

class StaticOverviewCard extends StatelessWidget {
  const StaticOverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0F1F7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF087AC0),
            size: 19,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 9.2,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
