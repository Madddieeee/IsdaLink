import 'package:flutter/material.dart';

class HomeBottomNav
    extends
        StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.onMyOrders,
    required this.onAnalytics,
    required this.onMe,
  });

  final VoidCallback onMyOrders;
  final VoidCallback onAnalytics;
  final VoidCallback onMe;

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

  @override
  Widget build(
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
              onTap: onMyOrders,
            ),
            bottomNavItem(
              icon: Icons.bar_chart,
              label: 'Analytics',
              active: false,
              onTap: onAnalytics,
            ),
            bottomNavItem(
              icon: Icons.person,
              label: 'Me',
              active: false,
              onTap: onMe,
            ),
          ],
        ),
      ),
    );
  }
}
