import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.assetIconPath,
    this.subtitle,
    this.actionLabel,
    this.badgeLabel,
    this.onViewAll,
  });

  final String title;
  final IconData icon;
  final String? assetIconPath;
  final String? subtitle;
  final String? actionLabel;
  final String? badgeLabel;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final hasBadge = badgeLabel != null && badgeLabel!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: hasSubtitle
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F6FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: assetIconPath != null && assetIconPath!.trim().isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    assetIconPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) =>
                        Icon(icon, color: const Color(0xFF087EBA), size: 17),
                  ),
                )
              : Icon(icon, color: const Color(0xFF087EBA), size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102D48),
                        fontSize: 19,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.45,
                      ),
                    ),
                  ),
                  if (hasBadge) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F8F1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badgeLabel!,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF16835F),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasSubtitle) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF758B9B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onViewAll != null) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel ?? 'See all',
                  style: const TextStyle(
                    color: Color(0xFF008EC5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: Color(0xFF008EC5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
