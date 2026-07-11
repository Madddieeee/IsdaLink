import 'package:flutter/material.dart';

class HomeSectionHeader
    extends
        StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onViewAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onViewAll;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(
            0xFFFF7A1A,
          ),
          size: 20,
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(
                0xFF102C44,
              ),
            ),
          ),
        ),
        if (onViewAll !=
            null)
          GestureDetector(
            onTap: onViewAll,
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(
                0xFF7B8FA3,
              ),
            ),
          ),
      ],
    );
  }
}
