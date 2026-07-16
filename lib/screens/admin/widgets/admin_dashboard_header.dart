import 'package:flutter/material.dart';

class AdminDashboardHeader
    extends
        StatelessWidget {
  const AdminDashboardHeader({
    super.key,
    required this.usersCount,
    required this.suppliersCount,
    required this.pendingCount,
    required this.ordersCount,
    required this.onLogout,
  });

  final int usersCount;
  final int suppliersCount;
  final int pendingCount;
  final int ordersCount;
  final VoidCallback onLogout;

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
                fontSize: 17,
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(
                    38,
                  ),
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onLogout,
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
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Monitor users, supplier applications, stocks, and COD orders.',
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
                value: '$usersCount',
                label: 'Users',
                icon: Icons.people,
              ),
              statCard(
                value: '$suppliersCount',
                label: 'Suppliers',
                icon: Icons.storefront,
              ),
              statCard(
                value: '$pendingCount',
                label: 'Pending',
                icon: Icons.hourglass_top,
              ),
              statCard(
                value: '$ordersCount',
                label: 'Orders',
                icon: Icons.receipt_long,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
