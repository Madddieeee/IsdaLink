import 'package:flutter/material.dart';
import 'package:isdalink/data/sample_data.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  List<FishProduct> get allProducts {
    return sampleSuppliers.expand((supplier) => supplier.products).toList();
  }

  int get totalProducts => allProducts.length;

  int get lowStockCount {
    return allProducts
        .where(
          (product) =>
              product.availableQuantity > 0 &&
              product.availableQuantity <= product.lowStockThreshold,
        )
        .length;
  }

  int get outOfStockCount {
    return allProducts
        .where((product) => product.availableQuantity <= 0)
        .length;
  }

  double get inventoryValue {
    return allProducts.fold<double>(
      0,
      (sum, product) => sum + (product.price * product.availableQuantity),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(36),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 5),
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
                color: Color(0xFFDCE9F5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF146BFF).withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF146BFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget forecastMethodCard({
    required String title,
    required String description,
    required String useCase,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1E9F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF146BFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    useCase,
                    style: const TextStyle(
                      color: Color(0xFF146BFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget metricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withAlpha(56),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget suggestionTile({
    required FishProduct product,
    required Supplier supplier,
  }) {
    final bool isOutOfStock = product.availableQuantity <= 0;
    final Color color =
        isOutOfStock ? const Color(0xFFD32F2F) : const Color(0xFFFF7A1A);
    final String status = isOutOfStock ? 'Out of Stock' : 'Low Stock';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FB),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(
                product.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  supplier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${product.availableQuantity} ${product.quantityUnit} left',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget topProductTile({
    required int rank,
    required FishProduct product,
    required Supplier supplier,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF146BFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            product.emoji,
            style: const TextStyle(fontSize: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  supplier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₱${product.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF146BFF),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<Supplier, FishProduct>> supplierProductPairs() {
    final pairs = <MapEntry<Supplier, FishProduct>>[];

    for (final supplier in sampleSuppliers) {
      for (final product in supplier.products) {
        pairs.add(MapEntry(supplier, product));
      }
    }

    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    final pairs = supplierProductPairs();

    final restockSuggestions = pairs
        .where(
          (entry) =>
              entry.value.availableQuantity <= entry.value.lowStockThreshold,
        )
        .toList();

    final topProducts = [...pairs];
    topProducts.sort(
      (a, b) => b.value.price.compareTo(a.value.price),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF102C44),
                  Color(0xFF146BFF),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sales Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sample analytics for demand trends, restocking suggestions, and sales-time insights.',
                  style: TextStyle(
                    color: Color(0xFFDCE9F5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    statCard(
                      value: '$totalProducts',
                      label: 'Products',
                      icon: Icons.inventory_2,
                    ),
                    statCard(
                      value: '$lowStockCount',
                      label: 'Low Stock',
                      icon: Icons.warning_amber,
                    ),
                    statCard(
                      value: '₱${inventoryValue.toStringAsFixed(0)}',
                      label: 'Inventory',
                      icon: Icons.analytics,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              children: [
                sectionCard(
                  title: 'Forecasting Methods',
                  subtitle:
                      'These are analytics components under the Sales Analytics and Restocking Suggestion feature.',
                  icon: Icons.trending_up,
                  child: Column(
                    children: [
                      forecastMethodCard(
                        title: 'Simple Moving Average',
                        description:
                            'Uses recent sales records to estimate short-term demand trends for fish products.',
                        useCase: 'Best for general demand movement',
                        icon: Icons.show_chart,
                      ),
                      forecastMethodCard(
                        title: 'Seasonal Moving Average',
                        description:
                            'Uses recurring weekly or monthly sales patterns to support seasonal restocking suggestions.',
                        useCase: 'Best for repeated demand patterns',
                        icon: Icons.calendar_month,
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Forecast Evaluation',
                  subtitle:
                      'MAPE and MAE will validate forecast accuracy when real sales records are connected.',
                  icon: Icons.fact_check,
                  child: Row(
                    children: [
                      metricTile(
                        label: 'MAPE',
                        value: '--',
                        subtitle: 'Percentage error',
                        color: const Color(0xFF146BFF),
                      ),
                      const SizedBox(width: 12),
                      metricTile(
                        label: 'MAE',
                        value: '--',
                        subtitle: 'Average absolute error',
                        color: const Color(0xFFFF7A1A),
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Restocking Suggestions',
                  subtitle:
                      'Products below the low-stock threshold are flagged for restocking.',
                  icon: Icons.notification_important,
                  child: restockSuggestions.isEmpty
                      ? const Text(
                          'No restocking alerts found in the sample data.',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 13,
                          ),
                        )
                      : Column(
                          children: restockSuggestions
                              .map(
                                (entry) => suggestionTile(
                                  supplier: entry.key,
                                  product: entry.value,
                                ),
                              )
                              .toList(),
                        ),
                ),
                sectionCard(
                  title: 'Top Product Insights',
                  subtitle:
                      'Sample ranking based on current product value. Real ranking will use sales records later.',
                  icon: Icons.emoji_events,
                  child: Column(
                    children: topProducts
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (entry) => topProductTile(
                            rank: entry.key + 1,
                            supplier: entry.value.key,
                            product: entry.value.value,
                          ),
                        )
                        .toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FB),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF146BFF).withAlpha(42),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info,
                        color: Color(0xFF146BFF),
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline/sample mode: These analytics are placeholders. Real forecasting will be computed after sales and order data are stored in the database.',
                          style: TextStyle(
                            color: Color(0xFF52677A),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
