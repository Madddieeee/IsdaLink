import 'package:flutter/material.dart';

class AdminStatusChip
    extends
        StatelessWidget {
  const AdminStatusChip({
    super.key,
    required this.status,
  });

  final String status;

  Color statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'delivered':
        return const Color(
          0xFF2E7D32,
        );
      case 'pending':
        return const Color(
          0xFFFF7A1A,
        );
      case 'rejected':
      case 'cancelled':
        return const Color(
          0xFFD32F2F,
        );
      default:
        return const Color(
          0xFF7B8FA3,
        );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final color = statusColor(
      status,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(
          24,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: color.withAlpha(
            60,
          ),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
