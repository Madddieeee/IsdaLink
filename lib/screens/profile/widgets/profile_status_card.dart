import 'package:flutter/material.dart';

class ProfileStatusCard
    extends
        StatelessWidget {
  const ProfileStatusCard({
    super.key,
    required this.supplierStatus,
  });

  final String supplierStatus;

  @override
  Widget build(
    BuildContext context,
  ) {
    String message;
    IconData icon;
    Color color;

    if (supplierStatus ==
        'approved') {
      message = 'Supplier account approved: Supplier Dashboard is now available for stock posting and COD order management.';
      icon = Icons.verified;
      color = const Color(
        0xFF2E7D32,
      );
    } else if (supplierStatus ==
        'pending') {
      message = 'Supplier application pending: Please wait for admin approval before accessing supplier tools.';
      icon = Icons.hourglass_top;
      color = const Color(
        0xFFFF7A1A,
      );
    } else {
      message = 'Vendor account: You can browse suppliers, place COD orders, and apply as a supplier when needed.';
      icon = Icons.info;
      color = const Color(
        0xFF146BFF,
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(
          22,
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: color.withAlpha(
            45,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(
                  0xFF52677A,
                ),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
