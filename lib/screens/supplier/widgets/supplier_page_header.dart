import 'package:flutter/material.dart';

class SupplierPageHeader extends StatelessWidget {
  const SupplierPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.eyebrow = 'SUPPLIER WORKSPACE',
  });

  final String title;
  final String subtitle;
  final String eyebrow;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final oceanHeight = topPadding + 178;
    final totalHeight = oceanHeight + 24;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: oceanHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/home_header_boat.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF06355F),
                            Color(0xFF0875D1),
                            Color(0xFF12A7D1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF052D4D).withValues(alpha: 0.38),
                          const Color(0xFF073F67).withValues(alpha: 0.50),
                          const Color(0xFF075C89).withValues(alpha: 0.74),
                        ],
                        stops: const [0, 0.52, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      topPadding + 10,
                      16,
                      22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: onBack,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.20),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 23,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 92,
                              height: 38,
                              child: Image.asset(
                                'assets/images/isdalink_logo.png',
                                fit: BoxFit.contain,
                                color: Colors.white,
                                colorBlendMode: BlendMode.srcIn,
                                errorBuilder: (_, _, _) => const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'IsdaLink',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            color: Color(0xFFD2F4FB),
                            fontSize: 8.8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.45,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23.5,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE2F4FA),
                            fontSize: 10.4,
                            height: 1.30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 17),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 36,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1800152A),
                      blurRadius: 22,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
