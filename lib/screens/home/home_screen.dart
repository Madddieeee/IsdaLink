import 'package:flutter/material.dart';
import 'package:isdalink/data/sample_data.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import '../analytics/analytics_screen.dart';
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

  void logout(
    BuildContext context,
  ) {
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
    FishProduct product,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => ProductDetailsScreen(
              supplier: supplier,
              product: product,
            ),
      ),
    );
  }

  List<
    Map<
      String,
      dynamic
    >
  >
  getRecentProducts() {
    final List<
      Map<
        String,
        dynamic
      >
    >
    products = [];

    for (final supplier in sampleSuppliers) {
      for (final product in supplier.products) {
        products.add(
          {
            'supplier': supplier,
            'product': product,
          },
        );
      }
    }

    return products
        .take(
          4,
        )
        .toList();
  }

  Widget sectionHeader({
    required String title,
    required IconData icon,
    VoidCallback? onViewAll,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(
            0xFFFF7A1A,
          ),
          size: 20,
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(
                0xFF102C44,
              ),
            ),
          ),
        ),
        if (onViewAll !=
            null)
          GestureDetector(
            onTap: onViewAll,
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(
                0xFF7B8FA3,
              ),
            ),
          ),
      ],
    );
  }

  Widget quickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 74,
          margin: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              20,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x10000000,
                ),
                blurRadius: 14,
                offset: Offset(
                  0,
                  6,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(
                  0xFF146BFF,
                ),
                size: 24,
              ),
              const SizedBox(
                height: 7,
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget recommendedSupplierCard(
    BuildContext context,
    Supplier supplier,
  ) {
    final FishProduct? firstProduct = supplier.products.isNotEmpty
        ? supplier.products.first
        : null;

    return GestureDetector(
      onTap: () => openSupplierDetails(
        context,
        supplier,
      ),
      child: Container(
        width: 185,
        margin: const EdgeInsets.only(
          right: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x14000000,
              ),
              blurRadius: 16,
              offset: Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    22,
                  ),
                ),
                gradient: LinearGradient(
                  colors: [
                    Color(
                      0xFF146BFF,
                    ),
                    Color(
                      0xFF00B4D8,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          31,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: -22,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEAF7FB,
                        ),
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          firstProduct?.emoji ??
                              '🐟',
                          style: const TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          46,
                        ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: const Text(
                        'TOP RATED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 28,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Text(
                supplier.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 13,
                    color: Color(
                      0xFF7B8FA3,
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Expanded(
                    child: Text(
                      supplier.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(
                      0xFFFFB703,
                    ),
                    size: 15,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    '${supplier.rating}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(
                        0xFF102C44,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
                      '(${supplier.reviews} reviews)',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(
                          0xFF7B8FA3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget recentProductCard(
    BuildContext context,
    Supplier supplier,
    FishProduct product,
  ) {
    return GestureDetector(
      onTap: () => openProductDetails(
        context,
        supplier,
        product,
      ),
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(
          right: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x14000000,
              ),
              blurRadius: 16,
              offset: Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 108,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    22,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(
                      0xFFEAF7FB,
                    ),
                    Color(
                      0xFFCBEAF5,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      product.emoji,
                      style: const TextStyle(
                        fontSize: 54,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF146BFF,
                        ),
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Text(
                        '₱${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    product.priceUnit,
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: product.stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          product.stockStatus,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: product.stockColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget bottomNavItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active
                ? const Color(
                    0xFF146BFF,
                  )
                : const Color(
                    0xFF9AAABD,
                  ),
            size: 22,
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? const Color(
                      0xFF146BFF,
                    )
                  : const Color(
                      0xFF9AAABD,
                    ),
              fontSize: 10,
              fontWeight: active
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomNav(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(
              0x14000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              -4,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            bottomNavItem(
              icon: Icons.home,
              label: 'Home',
              active: true,
              onTap: () {},
            ),
            bottomNavItem(
              icon: Icons.receipt_long,
              label: 'Orders',
              active: false,
              onTap: () => openMyOrders(
                context,
              ),
            ),
            bottomNavItem(
              icon: Icons.bar_chart,
              label: 'Analytics',
              active: false,
              onTap: () => openAnalytics(
                context,
              ),
            ),
            bottomNavItem(
              icon: Icons.person,
              label: 'Me',
              active: false,
              onTap: () => openMe(
                context,
              ),
            ),
          ],
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
    final recentProducts = getRecentProducts();

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
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    56,
                    20,
                    24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(
                          0xFF102C44,
                        ),
                        Color(
                          0xFF146BFF,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(
                        32,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ISDALINK',
                            style: TextStyle(
                              color: Color(
                                0xFFBFD1E3,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(
                                41,
                              ),
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  'Caraga Region',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          GestureDetector(
                            onTap: () => logout(
                              context,
                            ),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(
                                  41,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        'Juan Dela Cruz',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text(
                        'Find fresh fish stocks and trusted suppliers.',
                        style: TextStyle(
                          color: Color(
                            0xFFDCE9F5,
                          ),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () => openBrowseSuppliers(
                          context,
                        ),
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              18,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(
                                  0x22000000,
                                ),
                                blurRadius: 12,
                                offset: Offset(
                                  0,
                                  6,
                                ),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Color(
                                  0xFF7B8FA3,
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Search fish, suppliers, or locations...',
                                  style: TextStyle(
                                    color: Color(
                                      0xFF7B8FA3,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  child: Row(
                    children: [
                      quickActionCard(
                        icon: Icons.storefront,
                        label: 'Suppliers',
                        onTap: () => openBrowseSuppliers(
                          context,
                        ),
                      ),
                      quickActionCard(
                        icon: Icons.receipt_long,
                        label: 'Orders',
                        onTap: () => openMyOrders(
                          context,
                        ),
                      ),
                      quickActionCard(
                        icon: Icons.bar_chart,
                        label: 'Analytics',
                        onTap: () => openAnalytics(
                          context,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 26,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: sectionHeader(
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
                          ) => recommendedSupplierCard(
                            context,
                            supplier,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(
                  height: 26,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: sectionHeader(
                    title: 'Recent Fish Posts',
                    icon: Icons.campaign,
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
                    children: recentProducts.map(
                      (
                        item,
                      ) {
                        return recentProductCard(
                          context,
                          item['supplier']
                              as Supplier,
                          item['product']
                              as FishProduct,
                        );
                      },
                    ).toList(),
                  ),
                ),
                const SizedBox(
                  height: 28,
                ),
              ],
            ),
          ),
          bottomNav(
            context,
          ),
        ],
      ),
    );
  }
}
