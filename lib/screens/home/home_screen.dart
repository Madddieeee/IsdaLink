import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'package:isdalink/screens/home/widgets/home_bottom_nav.dart';
import 'package:isdalink/screens/home/widgets/home_header.dart';
import 'package:isdalink/screens/home/widgets/home_quick_actions.dart';
import 'package:isdalink/screens/home/widgets/home_section_header.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_posts.dart';
import 'package:isdalink/screens/home/widgets/recommended_supplier_card.dart';
import 'package:isdalink/screens/profile/me_screen.dart';
import 'package:isdalink/screens/vendor/browse_suppliers_screen.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/supplier_browse_service.dart';

class HomeScreen
    extends
        StatelessWidget {
  const HomeScreen({
    super.key,
  });

  SupplierBrowseService get supplierService => const SupplierBrowseService();

  Future<
    void
  >
  logout(
    BuildContext context,
  ) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const WelcomeScreen(),
      ),
      (
        route,
      ) => false,
    );
  }

  void openAnalytics(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const AnalyticsScreen(),
      ),
    );
  }

  void openBrowseSuppliers(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const BrowseSuppliersScreen(),
      ),
    );
  }

  void openMyOrders(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const MyOrdersScreen(),
      ),
    );
  }

  void openMe(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const MeScreen(),
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
        builder:
            (
              _,
            ) => SupplierDetailsScreen(
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
        builder:
            (
              _,
            ) => ProductDetailsScreen(
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
      height: 210,
      child:
          StreamBuilder<
            QuerySnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: supplierService.suppliersStream,
            builder:
                (
                  context,
                  snapshot,
                ) {
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.only(
                        left: 20,
                      ),
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
                      .take(
                        3,
                      )
                      .toList();

                  if (approvedSuppliers.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.only(
                        left: 20,
                      ),
                      scrollDirection: Axis.horizontal,
                      children: [
                        homeSupplierMessageCard(
                          icon: Icons.storefront_outlined,
                          title: 'No approved suppliers yet',
                          subtitle: 'Approved supplier profiles from Firebase will appear here.',
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(
                      left: 20,
                    ),
                    scrollDirection: Axis.horizontal,
                    children: approvedSuppliers.map(
                      (
                        document,
                      ) {
                        final data = document.data();
                        final supplier = supplierService.supplierFromProfile(
                          data,
                        );

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
      width: 280,
      margin: const EdgeInsets.only(
        right: 14,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isError
                ? const Color(
                    0xFFD32F2F,
                  )
                : const Color(
                    0xFF146BFF,
                  ),
            size: 38,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.4,
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
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HomeHeader(
                  onLogout: () => logout(
                    context,
                  ),
                  onSearchTap: () => openBrowseSuppliers(
                    context,
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                HomeQuickActions(
                  onBrowseSuppliers: () => openBrowseSuppliers(
                    context,
                  ),
                  onMyOrders: () => openMyOrders(
                    context,
                  ),
                  onAnalytics: () => openAnalytics(
                    context,
                  ),
                ),
                const SizedBox(
                  height: 26,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: HomeSectionHeader(
                    title: 'Top Recommended Suppliers',
                    icon: Icons.local_fire_department,
                    onViewAll: () => openBrowseSuppliers(
                      context,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                recommendedSuppliersList(
                  context,
                ),
                const SizedBox(
                  height: 26,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: HomeSectionHeader(
                    title: 'Recent Fish Posts',
                    icon: Icons.campaign,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                SizedBox(
                  height: 210,
                  child: RecentFishPosts(
                    onProductTap:
                        (
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
                ),
                const SizedBox(
                  height: 28,
                ),
              ],
            ),
          ),
          HomeBottomNav(
            onMyOrders: () => openMyOrders(
              context,
            ),
            onAnalytics: () => openAnalytics(
              context,
            ),
            onMe: () => openMe(
              context,
            ),
          ),
        ],
      ),
    );
  }
}
