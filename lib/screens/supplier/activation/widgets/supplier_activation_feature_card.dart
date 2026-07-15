import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_section_card.dart';

class SupplierActivationFeatureCard
    extends
        StatelessWidget {
  const SupplierActivationFeatureCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SupplierActivationSectionCard(
      title: 'Supplier Features After Approval',
      subtitle: 'Features available after admin approval.',
      icon: Icons.dashboard_customize,
      child: const Column(
        children: [
          SupplierActivationFeatureTile(
            icon: Icons.add_box,
            title: 'Post Fish Stocks',
            subtitle: 'Add available fish products and stock levels.',
          ),
          SupplierActivationFeatureTile(
            icon: Icons.inventory_2,
            title: 'Manage Products',
            subtitle: 'Update price, quantity, and low-stock alerts.',
          ),
          SupplierActivationFeatureTile(
            icon: Icons.receipt_long,
            title: 'Track COD Orders',
            subtitle: 'View vendor orders using cash on delivery.',
          ),
          SupplierActivationFeatureTile(
            icon: Icons.analytics,
            title: 'Sales Analytics',
            subtitle: 'View sales trends and restocking insights.',
          ),
        ],
      ),
    );
  }
}

class SupplierActivationFeatureTile
    extends
        StatelessWidget {
  const SupplierActivationFeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFEAF7FB,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(
              0xFF146BFF,
            ),
            size: 22,
          ),
          const SizedBox(
            width: 12,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Color(
              0xFF2E7D32,
            ),
            size: 21,
          ),
        ],
      ),
    );
  }
}
