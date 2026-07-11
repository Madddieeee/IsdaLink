import 'package:flutter/material.dart';

class SupplierDashboardActions
    extends
        StatelessWidget {
  const SupplierDashboardActions({
    super.key,
    required this.onPostFishStock,
    required this.onManageProducts,
    required this.onOrders,
    required this.onAnalytics,
  });

  final VoidCallback onPostFishStock;
  final VoidCallback onManageProducts;
  final VoidCallback onOrders;
  final VoidCallback onAnalytics;

  Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(
      0xFF146BFF,
    ),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
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
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(
                  24,
                ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(
                0xFF9AAABD,
              ),
              size: 16,
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
    return Column(
      children: [
        actionTile(
          icon: Icons.add_box,
          title: 'Post Fish Stock',
          subtitle: 'Add fish products, price, quantity, and unit type.',
          onTap: onPostFishStock,
        ),
        actionTile(
          icon: Icons.inventory,
          title: 'Manage Products',
          subtitle: 'Update your own stock levels, price, and low-stock alerts.',
          color: const Color(
            0xFF00A6A6,
          ),
          onTap: onManageProducts,
        ),
        actionTile(
          icon: Icons.receipt_long,
          title: 'COD Orders',
          subtitle: 'View incoming vendor orders and payment status.',
          color: const Color(
            0xFFFF7A1A,
          ),
          onTap: onOrders,
        ),
        actionTile(
          icon: Icons.analytics,
          title: 'Sales Analytics',
          subtitle: 'View moving average forecasts and restocking insights.',
          color: const Color(
            0xFF7B61FF,
          ),
          onTap: onAnalytics,
        ),
      ],
    );
  }
}
