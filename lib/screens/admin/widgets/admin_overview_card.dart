import 'package:flutter/material.dart';

class AdminOverviewCard
    extends
        StatelessWidget {
  const AdminOverviewCard({
    super.key,
    required this.usersCount,
    required this.suppliersCount,
    required this.stocksCount,
    required this.ordersCount,
  });

  final int usersCount;
  final int suppliersCount;
  final int stocksCount;
  final int ordersCount;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
      child: Column(
        children: [
          AdminOverviewRow(
            icon: Icons.people,
            label: 'Registered users',
            value: '$usersCount',
          ),
          AdminOverviewRow(
            icon: Icons.storefront,
            label: 'Supplier profiles',
            value: '$suppliersCount',
          ),
          AdminOverviewRow(
            icon: Icons.inventory_2,
            label: 'Fish stock posts',
            value: '$stocksCount',
          ),
          AdminOverviewRow(
            icon: Icons.receipt_long,
            label: 'COD orders',
            value: '$ordersCount',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class AdminOverviewRow
    extends
        StatelessWidget {
  const AdminOverviewRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(
                0xFF146BFF,
              ),
              size: 21,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(
                    0xFF52677A,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(
                  0xFF102C44,
                ),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (showDivider)
          const Divider(
            height: 22,
          ),
      ],
    );
  }
}
