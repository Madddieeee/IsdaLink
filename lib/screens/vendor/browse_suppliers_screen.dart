import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/data/sample_data.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';

class BrowseSuppliersScreen extends StatelessWidget {
  const BrowseSuppliersScreen({super.key});

  void openSupplierDetails(BuildContext context, Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailsScreen(supplier: supplier),
      ),
    );
  }

  Widget statsCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(36)),
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

  Widget supplierCard(BuildContext context, Supplier supplier) {
    final firstProduct = supplier.products.isNotEmpty
        ? supplier.products.first
        : null;

    return GestureDetector(
      onTap: () => openSupplierDetails(context, supplier),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 96,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF102C44), Color(0xFF146BFF)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -26,
                    top: -28,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(28),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: -28,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7FB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          firstProduct?.emoji ?? '🐟',
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(42),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFB703),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${supplier.rating}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF7B8FA3),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          supplier.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supplier.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7FB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2,
                              color: Color(0xFF146BFF),
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${supplier.products.length} products',
                              style: const TextStyle(
                                color: Color(0xFF146BFF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reviews,
                              color: Color(0xFFFF7A1A),
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${supplier.reviews} reviews',
                              style: const TextStyle(
                                color: Color(0xFFFF7A1A),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF146BFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 19,
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

  @override
  Widget build(BuildContext context) {
    final totalProducts = sampleSuppliers.fold<int>(
      0,
      (sum, supplier) => sum + supplier.products.length,
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
                colors: [Color(0xFF102C44), Color(0xFF146BFF)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
                        'Browse Suppliers',
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
                  'Find trusted fish suppliers and available stocks in Caraga.',
                  style: TextStyle(
                    color: Color(0xFFDCE9F5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFF7B8FA3)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search supplier, fish, or location...',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    statsCard(
                      value: '${sampleSuppliers.length}',
                      label: 'Suppliers',
                      icon: Icons.storefront,
                    ),
                    statsCard(
                      value: '$totalProducts',
                      label: 'Products',
                      icon: Icons.inventory_2,
                    ),
                    statsCard(
                      value: 'COD',
                      label: 'Payment',
                      icon: Icons.payments,
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
                const Text(
                  'Recommended Suppliers',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap a supplier to view details and available fish products.',
                  style: TextStyle(color: Color(0xFF7B8FA3), fontSize: 12),
                ),
                const SizedBox(height: 18),
                ...sampleSuppliers.map(
                  (supplier) => supplierCard(context, supplier),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
