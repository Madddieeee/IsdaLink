import 'package:flutter/material.dart';
import 'package:isdalink/services/supplier_product_service.dart';

class ManageProductsHeader
    extends
        StatelessWidget {
  const ManageProductsHeader({
    super.key,
    required this.stats,
    required this.onBack,
  });

  final SupplierProductStats stats;
  final VoidCallback onBack;

  Widget statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 72,
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
                onTap: onBack,
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
                  'Manage Products',
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
            height: 8,
          ),
          const Text(
            'Update posted fish stock, prices, quantities, and availability for this account.',
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
                value: '${stats.totalProducts}',
                label: 'Products',
                icon: Icons.inventory_2,
              ),
              statCard(
                value: '${stats.lowStockCount}',
                label: 'Low Stock',
                icon: Icons.warning_amber,
              ),
              statCard(
                value: '${stats.unavailableCount}',
                label: 'Hidden',
                icon: Icons.visibility_off,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
