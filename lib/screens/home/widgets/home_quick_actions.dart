import 'package:flutter/material.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onBrowseSuppliers,
    required this.onMyOrders,
    required this.onAnalytics,
    required this.onMe,
  });

  final VoidCallback onBrowseSuppliers;
  final VoidCallback onMyOrders;
  final VoidCallback onAnalytics;
  final VoidCallback onMe;

  Widget quickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 78,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 23,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 8.7,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          quickActionCard(
            icon: Icons.storefront,
            label: 'Suppliers',
            subtitle: 'Browse',
            color: const Color(0xFF087AC0),
            onTap: onBrowseSuppliers,
          ),
          quickActionCard(
            icon: Icons.receipt_long,
            label: 'Orders',
            subtitle: 'Track COD',
            color: const Color(0xFFFF7A1A),
            onTap: onMyOrders,
          ),
          quickActionCard(
            icon: Icons.analytics,
            label: 'Analytics',
            subtitle: 'Forecast',
            color: const Color(0xFF2E7D32),
            onTap: onAnalytics,
          ),
          quickActionCard(
            icon: Icons.person,
            label: 'Me',
            subtitle: 'Profile',
            color: const Color(0xFF7B61FF),
            onTap: onMe,
          ),
        ],
      ),
    );
  }
}
