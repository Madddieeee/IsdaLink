import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.selectedIndex = 0,
    this.onHome,
    required this.onMyOrders,
    required this.onAnalytics,
    required this.onMe,
    this.activeOrderCount = 0,
    this.supplierNotificationCount = 0,
  });

  final int selectedIndex;
  final VoidCallback? onHome;
  final VoidCallback onMyOrders;
  final VoidCallback onAnalytics;
  final VoidCallback onMe;
  final int activeOrderCount;
  final int supplierNotificationCount;

  Widget bottomNavItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 52),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFEDF9FD) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        color: active
                            ? const Color(0xFF087AC0)
                            : const Color(0xFF758B9B),
                        size: 22,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: -9,
                          top: -8,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D4D),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.4,
                              ),
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF087AC0)
                          : const Color(0xFF758B9B),
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7F0F5), width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, -2),
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
              active: selectedIndex == 0,
              onTap: onHome ?? () {},
            ),
            bottomNavItem(
              icon: Icons.receipt_long,
              label: 'Orders',
              active: selectedIndex == 1,
              badgeCount: activeOrderCount,
              onTap: onMyOrders,
            ),
            bottomNavItem(
              icon: Icons.bar_chart,
              label: 'Analytics',
              active: selectedIndex == 2,
              onTap: onAnalytics,
            ),
            bottomNavItem(
              icon: Icons.person,
              label: 'Me',
              active: selectedIndex == 3,
              badgeCount: supplierNotificationCount,
              onTap: onMe,
            ),
          ],
        ),
      ),
    );
  }
}
