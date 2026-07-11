import 'package:flutter/material.dart';

class HomeQuickActions
    extends
        StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onBrowseSuppliers,
    required this.onMyOrders,
    required this.onAnalytics,
  });

  final VoidCallback onBrowseSuppliers;
  final VoidCallback onMyOrders;
  final VoidCallback onAnalytics;

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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          quickActionCard(
            icon: Icons.storefront,
            label: 'Suppliers',
            onTap: onBrowseSuppliers,
          ),
          quickActionCard(
            icon: Icons.receipt_long,
            label: 'Orders',
            onTap: onMyOrders,
          ),
          quickActionCard(
            icon: Icons.bar_chart,
            label: 'Analytics',
            onTap: onAnalytics,
          ),
        ],
      ),
    );
  }
}
