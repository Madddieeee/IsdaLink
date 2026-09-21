import 'package:flutter/material.dart';

class PostStockSectionCard extends StatelessWidget {
  const PostStockSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E00152A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9F7FF), Color(0xFFDDF1FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF146BFF), size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 13.5,
                              letterSpacing: -0.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7FB),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Color(0xFF146BFF),
                                fontSize: 7.6,
                                letterSpacing: 0.45,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.6,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
