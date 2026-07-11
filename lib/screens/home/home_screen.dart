import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/data/sample_data.dart';
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

class HomeScreen
    extends
        StatelessWidget {
  const HomeScreen({
    super.key,
  });

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
    Supplier supplier,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => SupplierDetailsScreen(
              supplier: supplier,
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final recommendedSuppliers = sampleSuppliers
        .take(
          3,
        )
        .toList();

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
                SizedBox(
                  height: 210,
                  child: ListView(
                    padding: const EdgeInsets.only(
                      left: 20,
                    ),
                    scrollDirection: Axis.horizontal,
                    children: recommendedSuppliers
                        .map(
                          (
                            supplier,
                          ) => RecommendedSupplierCard(
                            supplier: supplier,
                            onTap: () => openSupplierDetails(
                              context,
                              supplier,
                            ),
                          ),
                        )
                        .toList(),
                  ),
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
