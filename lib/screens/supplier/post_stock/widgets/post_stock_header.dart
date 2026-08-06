import 'package:flutter/material.dart';

class PostStockHeader extends StatelessWidget {
  const PostStockHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 232,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xFF075FAE),
      foregroundColor: Colors.white,
      leadingWidth: 58,
      leading: Padding(
        padding: const EdgeInsets.only(
          left: 14,
          top: 8,
          bottom: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(99),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(32),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(27),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 8,
      title: const Text(
        'Post Fish Stock',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.5,
          letterSpacing: -0.15,
          fontWeight: FontWeight.w900,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF063B66),
                Color(0xFF075FAE),
                Color(0xFF146BFF),
              ],
              stops: [
                0.0,
                0.55,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -58,
                right: -52,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(9),
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 64,
                right: 24,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.paddingOf(context).top + 74,
                  18,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUPPLIER CENTER · 3-STEP LISTING',
                      style: TextStyle(
                        color: Color(0xFFBCE8FF),
                        fontSize: 8.6,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Publish accurate availability, pricing, and automatic stock alerts for vendor COD orders.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFDDEFFF),
                        fontSize: 10.7,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(29),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: Colors.white.withAlpha(31),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: _HeaderFeature(
                              icon: Icons.photo_outlined,
                              label: 'PHOTO',
                              value: 'Required',
                            ),
                          ),
                          _HeaderDivider(),
                          Expanded(
                            child: _HeaderFeature(
                              icon:
                                  Icons.notifications_active_outlined,
                              label: 'STOCK ALERT',
                              value: 'Automatic',
                            ),
                          ),
                          _HeaderDivider(),
                          Expanded(
                            child: _HeaderFeature(
                              icon: Icons.payments_outlined,
                              label: 'PAYMENT',
                              value: 'COD only',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
    );
  }
}

class _HeaderFeature extends StatelessWidget {
  const _HeaderFeature({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 17,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFBCE8FF),
            fontSize: 7.2,
            letterSpacing: 0.35,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      color: Colors.white.withAlpha(28),
    );
  }
}
