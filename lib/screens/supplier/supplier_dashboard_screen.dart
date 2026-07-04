import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/fish_product.dart';
import '../analytics/analytics_screen.dart';
import '../vendor/my_orders_screen.dart';
import 'post_fish_stock_screen.dart';

class SupplierDashboardScreen
    extends
        StatelessWidget {
  const SupplierDashboardScreen({
    super.key,
  });

  List<
    FishProduct
  >
  get supplierProducts {
    if (sampleSuppliers.isEmpty) {
      return [];
    }

    return sampleSuppliers.first.products;
  }

  double get totalStocks {
    return supplierProducts.fold<
      double
    >(
      0,
      (
        sum,
        product,
      ) =>
          sum +
          product.availableQuantity,
    );
  }

  int get lowStockCount {
    return supplierProducts
        .where(
          (
            product,
          ) =>
              product.availableQuantity >
                  0 &&
              product.availableQuantity <=
                  product.lowStockThreshold,
        )
        .length;
  }

  void openPostFishStock(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const PostFishStockScreen(),
      ),
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

  void openOrders(
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

  void showComingSoon(
    BuildContext context,
    String feature,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon',
        ),
      ),
    );
  }

  Widget statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 76,
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(
            38,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(
              36,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFFDCE9F5,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(
      0xFF146BFF,
    ),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(
          16,
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
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(
                  24,
                ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(
                0xFF9AAABD,
              ),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget productStockCard(
    BuildContext context,
    FishProduct product,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0F000000,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(
                0xFFEAF7FB,
              ),
              borderRadius: BorderRadius.circular(
                17,
              ),
            ),
            child: Center(
              child: Text(
                product.emoji,
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 7,
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
                        '${product.stockStatus} • ${product.availableQuantity} ${product.quantityUnit}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: product.stockColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showComingSoon(
              context,
              'Edit Product',
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFEAF7FB,
                ),
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Color(
                  0xFF146BFF,
                ),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.35,
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
    final productsToShow = supplierProducts
        .take(
          4,
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              54,
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
                    GestureDetector(
                      onTap: () => Navigator.pop(
                        context,
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                            38,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'Supplier Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 18,
                ),
                const Text(
                  'Manage fish stock posts, COD orders, and supplier analytics.',
                  style: TextStyle(
                    color: Color(
                      0xFFDCE9F5,
                    ),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Row(
                  children: [
                    statCard(
                      value: '${supplierProducts.length}',
                      label: 'Products',
                      icon: Icons.inventory_2,
                    ),
                    statCard(
                      value: totalStocks.toStringAsFixed(
                        0,
                      ),
                      label: 'Stocks',
                      icon: Icons.scale,
                    ),
                    statCard(
                      value: '$lowStockCount',
                      label: 'Low Stock',
                      icon: Icons.warning_amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                20,
              ),
              children: [
                sectionTitle(
                  'Supplier Tools',
                  'These tools support supplier stock visibility and vendor coordination.',
                ),
                actionTile(
                  icon: Icons.add_box,
                  title: 'Post Fish Stock',
                  subtitle: 'Add fish products, price, quantity, and unit type.',
                  onTap: () => openPostFishStock(
                    context,
                  ),
                ),
                actionTile(
                  icon: Icons.inventory,
                  title: 'Manage Products',
                  subtitle: 'Update stock levels, price, and low-stock alerts.',
                  color: const Color(
                    0xFF00A6A6,
                  ),
                  onTap: () => showComingSoon(
                    context,
                    'Manage Products',
                  ),
                ),
                actionTile(
                  icon: Icons.receipt_long,
                  title: 'COD Orders',
                  subtitle: 'View incoming vendor orders and payment status.',
                  color: const Color(
                    0xFFFF7A1A,
                  ),
                  onTap: () => openOrders(
                    context,
                  ),
                ),
                actionTile(
                  icon: Icons.analytics,
                  title: 'Sales Analytics',
                  subtitle: 'View moving average forecasts and restocking insights.',
                  color: const Color(
                    0xFF7B61FF,
                  ),
                  onTap: () => openAnalytics(
                    context,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                sectionTitle(
                  'Current Stock Posts',
                  'Sample supplier products. Real posts will come from the database later.',
                ),
                ...productsToShow.map(
                  (
                    product,
                  ) => productStockCard(
                    context,
                    product,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
