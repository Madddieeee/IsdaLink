import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.actionLabel,
    this.badgeLabel,
    this.onViewAll,
  });

  final String title;
  final IconData icon;
  final String? actionLabel;
  final String? badgeLabel;
  final VoidCallback? onViewAll;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A73D8),
                Color(0xFF12B6D6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260A73D8),
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
              color: Color(0xFF13354B),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (badgeLabel?.trim().isNotEmpty == true) ...[
          Container(
            margin: const EdgeInsets.only(right: 7),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFC7EEDD),
              ),
            ),
            child: Text(
              badgeLabel!.trim(),
              style: const TextStyle(
                color: Color(0xFF16835F),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
        if (onViewAll != null)
          Material(
            color: const Color(0xFFE8F8FD),
            borderRadius: BorderRadius.circular(99),
            child: InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel?.trim().isNotEmpty == true
                          ? actionLabel!.trim()
                          : 'View all',
                      style: const TextStyle(
                        color: Color(0xFF0A73D8),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF0A73D8),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
