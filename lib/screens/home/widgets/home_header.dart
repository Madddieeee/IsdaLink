import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onLogout,
    required this.onSearchTap,
    this.onProfileTap,
    this.onSuppliersTap,
    this.onFishStocksTap,
    this.onActiveOrdersTap,
  });

  final VoidCallback onLogout;
  final VoidCallback onSearchTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSuppliersTap;
  final VoidCallback? onFishStocksTap;
  final VoidCallback? onActiveOrdersTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth <= 400;

    return ClipPath(
      clipper: _OceanEdge(),
      child: SizedBox(
        height: compact ? 260 : 276,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF063A61),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/home_header_boat.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.60, -0.10),
                ),
              ),

              // Darken the left side only so the boat stays visible while
              // the hero text remains readable, like the approved reference.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.0, 0.43, 0.74, 1.0],
                      colors: [
                        Color(0xE8063559),
                        Color(0xB7085680),
                        Color(0x580A7199),
                        Color(0x180A7199),
                      ],
                    ),
                  ),
                ),
              ),

              // Small curved light brand area, instead of a full-width pale
              // strip. This keeps the top much closer to the reference.
              Positioned(
                top: 0,
                left: 0,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _TopBrandWaveClipper(),
                    child: Container(
                      width: screenWidth * (compact ? 0.58 : 0.56),
                      height: compact ? 100 : 106,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF9FDFF),
                            Color(0xFFEAF8FE),
                            Color(0xD7D8F2FC),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: compact ? 106 : 112,
                left: compact ? 26 : 32,
                child: const _HeaderMessageText(),
              ),

              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : 18,
                    8,
                    compact ? 14 : 18,
                    30,
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: _TopBrandRow(
                          compact: compact,
                          screenWidth: screenWidth,
                          onProfileTap: onProfileTap,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _HeaderSearch(
                          onTap: onSearchTap,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBrandRow extends StatelessWidget {
  const _TopBrandRow({
    required this.compact,
    required this.screenWidth,
    required this.onProfileTap,
  });

  final bool compact;
  final double screenWidth;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final horizontalPagePadding = compact ? 14.0 : 18.0;
    final waveWidth = screenWidth * (compact ? 0.58 : 0.56);

    return SizedBox(
      height: compact ? 62 : 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Center the complete IsdaLink lockup inside the white wave itself,
          // independent of the controls on the right.
          Positioned(
            left: -horizontalPagePadding,
            top: compact ? -4 : -3,
            width: waveWidth,
            child: Transform.translate(
              offset: const Offset(-12, 0),
              child: Center(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: compact ? 146 : 158,
                    height: compact ? 42 : 46,
                    child: Image.asset(
                      'assets/images/isdalink_logo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: Text(
                      'Fresh Tides, Better Tomorrow',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF174A70),
                        fontSize: compact ? 7.4 : 8.0,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),

          // Keep location and action controls aligned independently on the
          // right so they never push the logo away from the wave center.
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RegionLabel(compact: compact),
                SizedBox(width: compact ? 5 : 7),
                _HeaderActionButton(
                  tooltip: 'Notifications',
                  icon: Icons.notifications_none_rounded,
                  onTap: null,
                  compact: compact,
                ),
                SizedBox(width: compact ? 5 : 7),
                _HeaderActionButton(
                  tooltip: 'My profile',
                  icon: Icons.person_rounded,
                  onTap: onProfileTap,
                  compact: compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMessageText extends StatelessWidget {
  const _HeaderMessageText();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.035,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Fresh fish.\nConnected in Caraga.',
            textAlign: TextAlign.left,
            maxLines: 2,
            style: TextStyle(
              color: Color(0xFFF8FCFF),
              fontSize: 14.6,
              height: 1.08,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.08,
              shadows: [
                Shadow(
                  color: Color(0x8600182B),
                  blurRadius: 7,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(
            width: 106,
            height: 12,
            child: CustomPaint(
              painter: _MessageUnderlinePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageUnderlinePainter extends CustomPainter {
  const _MessageUnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x99F7FCFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.66)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.98,
        size.width * 0.52,
        size.height * 0.90,
        size.width * 0.72,
        size.height * 0.53,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.34,
        size.width * 0.91,
        size.height * 0.30,
        size.width * 0.97,
        size.height * 0.38,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MessageUnderlinePainter oldDelegate) => false;
}

class _RegionLabel extends StatelessWidget {
  const _RegionLabel({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 39 : 43,
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12002440),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: const Color(0xFF0B3658),
            size: compact ? 15 : 17,
          ),
          SizedBox(width: compact ? 3 : 5),
          Text(
            'Caraga',
            style: TextStyle(
              color: const Color(0xFF0B3658),
              fontSize: compact ? 9.6 : 10.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: compact ? 1 : 2),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF0B3658),
            size: compact ? 15 : 17,
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    required this.compact,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 42.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(242),
        shape: const CircleBorder(),
        elevation: 0.5,
        shadowColor: const Color(0x16001D33),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: const Color(0xFF0B3658),
              size: compact ? 19 : 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSearch extends StatelessWidget {
  const _HeaderSearch({
    required this.onTap,
    required this.compact,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final searchHeight = compact ? 47.0 : 50.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 2.5,
      shadowColor: const Color(0x26002036),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: double.infinity,
          height: searchHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 18,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: const Color(0xFF123452),
                  size: compact ? 23 : 25,
                ),
                SizedBox(width: compact ? 9 : 11),
                Expanded(
                  child: Text(
                    'Search fish, suppliers, or locations...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8B97A4),
                      fontSize: compact ? 10.6 : 11.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OceanEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 12)
      ..cubicTo(
        size.width * 0.20,
        size.height - 2,
        size.width * 0.44,
        size.height - 20,
        size.width * 0.66,
        size.height - 14,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height - 10,
        size.width * 0.93,
        size.height - 4,
        size.width,
        size.height - 7,
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _OceanEdge oldClipper) => false;
}

class _TopBrandWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.64)
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.94,
        size.width * 0.64,
        size.height * 1.00,
        size.width * 0.43,
        size.height * 0.92,
      )
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.85,
        size.width * 0.11,
        size.height * 1.02,
        0,
        size.height * 0.95,
      )
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _TopBrandWaveClipper oldClipper) => false;
}
