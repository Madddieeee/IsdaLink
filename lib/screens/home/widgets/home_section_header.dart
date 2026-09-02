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

  String get eyebrow {
    switch (title.trim().toLowerCase()) {
      case 'recommended suppliers':
        return 'ISDALINK PICKS';
      case 'latest fish stocks':
        return 'FRESH MARKET';
      default:
        return 'ISDALINK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF075C9B),
                Color(0xFF078ED1),
                Color(0xFF11B9D1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220A73D8),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5D8BA5),
                  fontSize: 7.2,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.82,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF12354C),
                  fontSize: 16.2,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
            ],
          ),
        ),
        if (badgeLabel?.trim().isNotEmpty == true) ...[
          Container(
            margin: const EdgeInsets.only(right: 7),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFC7EEDD)),
            ),
            child: Text(
              badgeLabel!.trim(),
              style: const TextStyle(
                color: Color(0xFF16835F),
                fontSize: 8.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
        if (onViewAll != null)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            child: InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 2, 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel?.trim().isNotEmpty == true
                          ? actionLabel!.trim()
                          : 'View all',
                      style: const TextStyle(
                        color: Color(0xFF0876C8),
                        fontSize: 9.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF0876C8),
                      size: 10,
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
