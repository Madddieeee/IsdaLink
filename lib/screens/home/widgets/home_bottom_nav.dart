import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE6F9FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active
                    ? const Color(0xFF087AC0)
                    : const Color(0xFF9AAABD),
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF087AC0)
                      : const Color(0xFF9AAABD),
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
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
