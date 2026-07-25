import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onViewAll,
    this.actionLabel = 'View all',
  });

  final String title;
  final IconData icon;
  final VoidCallback? onViewAll;
  final String actionLabel;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF087AC0),
                Color(0xFF10B7D4),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22087AC0),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F9FF),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFFC9EDF7),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Color(0xFF087AC0),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF087AC0),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
