import 'package:flutter/material.dart';
import 'package:isdalink/services/supplier_product_service.dart';

class ManageProductsHeader extends StatelessWidget {
  const ManageProductsHeader({
    super.key,
    required this.stats,
    required this.onBack,
  });

  final SupplierProductStats stats;
  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 244,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xFF075FAE),
      foregroundColor: Colors.white,
      leadingWidth: 58,
      leading: Padding(
        padding: const EdgeInsets.only(
          left: 14,
          top: 8,
          bottom: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(99),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(32),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(27),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 8,
      title: const Text(
        'Manage Products',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.5,
          letterSpacing: -0.15,
          fontWeight: FontWeight.w900,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF063B66),
                Color(0xFF075FAE),
                Color(0xFF146BFF),
              ],
              stops: [
                0.0,
                0.55,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -58,
                right: -52,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(9),
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 65,
                right: 24,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.paddingOf(context).top + 75,
                  18,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUPPLIER CENTER · INVENTORY CONTROL',
                      style: TextStyle(
                        color: Color(0xFFBCE8FF),
                        fontSize: 8.6,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Update product details, available stock, automatic alerts, and marketplace visibility.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFDDEFFF),
                        fontSize: 10.7,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _HeaderMetric(
                          icon: Icons.inventory_2_outlined,
                          value: '${stats.activeProducts}',
                          label: 'Active',
                        ),
                        const SizedBox(width: 9),
                        _HeaderMetric(
                          icon:
                              Icons.notifications_active_outlined,
                          value: '${stats.stockAlertCount}',
                          label: 'Stock Alerts',
                        ),
                        const SizedBox(width: 9),
                        _HeaderMetric(
                          icon: Icons.visibility_off_outlined,
                          value: '${stats.hiddenCount}',
                          label: 'Hidden',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 59,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha(32),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFDCEFFA),
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
