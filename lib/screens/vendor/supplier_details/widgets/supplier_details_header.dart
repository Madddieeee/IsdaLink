import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/supplier_details_service.dart';

class SupplierDetailsHeader extends StatelessWidget {
  const SupplierDetailsHeader({
    super.key,
    required this.supplier,
    required this.stats,
    required this.onBack,
  });

  final Supplier supplier;
  final SupplierDetailsStats stats;
  final VoidCallback onBack;

  bool get hasNetworkImage {
    final imageUrl = supplier.profileImageUrl.trim();

    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  String get storeInitial {
    final name = supplier.name.trim();

    if (name.isEmpty) {
      return 'S';
    }

    return name.substring(0, 1).toUpperCase();
  }

  String get cleanDescription {
    final value = supplier.description.trim();

    if (value.isEmpty) {
      return '';
    }

    final lower = value.toLowerCase();
    const blocked = [
      'n/a',
      'na',
      'none',
      'test',
      'sample',
      'placeholder',
      'asdasd',
      'asdf',
    ];

    if (blocked.contains(lower)) {
      return '';
    }

    final looksLikeRandom = !value.contains(' ') && value.length < 18;

    if (looksLikeRandom) {
      return '';
    }

    return value;
  }

  Widget storePhoto() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withAlpha(185),
          width: 2.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2F031A31),
            blurRadius: 16,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: hasNetworkImage
            ? Image.network(
                supplier.profileImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) {
                  return StoreInitial(
                    initial: storeInitial,
                  );
                },
              )
            : StoreInitial(
                initial: storeInitial,
              ),
      ),
    );
  }

  Widget headerChip({
    required IconData icon,
    required String text,
    Color? foregroundColor,
    Color? backgroundColor,
    bool outlined = true,
  }) {
    final foreground = foregroundColor ?? Colors.white;
    final background =
        backgroundColor ?? Colors.white.withAlpha(26);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: outlined
            ? Border.all(
                color: foreground.withAlpha(42),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: foreground,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget overviewMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withAlpha(36),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withAlpha(68),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD8EFFA),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget metricDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withAlpha(28),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget ratingLine() {
    if (supplier.rating <= 0 || supplier.reviews <= 0) {
      return const Row(
        children: [
          Icon(
            Icons.star_border_rounded,
            color: Color(0xFFFFD166),
            size: 15,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'No reviews yet',
              style: TextStyle(
                color: Color(0xFFEAF5FB),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: Color(0xFFFFD166),
          size: 15,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${supplier.rating.toStringAsFixed(1)} from '
            '${supplier.reviews} review'
            '${supplier.reviews == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Color(0xFFEAF5FB),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget brandBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withAlpha(22),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.waves_rounded,
            color: Color(0xFFD7F6FF),
            size: 12,
          ),
          SizedBox(width: 5),
          Text(
            'Supplier Profile',
            style: TextStyle(
              color: Color(0xFFEAFBFF),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final description = cleanDescription;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SupplierStoreWaveAccentPainter(),
                ),
              ),
            ),
            ClipPath(
              clipper: const _SupplierStoreHeaderClipper(),
              clipBehavior: Clip.hardEdge,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF06355F),
                      Color(0xFF0A7BDA),
                      Color(0xFF13BED9),
                    ],
                    stops: [0, 0.57, 1],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _SupplierStoreBackdropPainter(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        topPadding + 10,
                        18,
                        44,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Material(
                                color: Colors.white.withAlpha(34),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: onBack,
                                  customBorder: const CircleBorder(),
                                  child: const SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Supplier Store',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              headerChip(
                                icon: Icons.verified_rounded,
                                text: 'Verified',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          brandBadge(),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(12),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withAlpha(16),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14001226),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    storePhoto(),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'FRESH FISH MARKET',
                                            style: TextStyle(
                                              color: Color(0xFFCBF5FF),
                                              fontSize: 9.2,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            supplier.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              height: 1.02,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_rounded,
                                                color: Color(0xFFEAF5FB),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  supplier.location,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFFEAF5FB),
                                                    fontSize: 10.8,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ratingLine(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    headerChip(
                                      icon: Icons.payments_outlined,
                                      text: 'COD only',
                                    ),
                                    headerChip(
                                      icon: Icons.storefront_rounded,
                                      text: 'Fish supplier',
                                    ),
                                    if (supplier.isNewSupplier)
                                      headerChip(
                                        icon:
                                            Icons.auto_awesome_rounded,
                                        text: 'New supplier',
                                        foregroundColor:
                                            const Color(0xFF8A4D00),
                                        backgroundColor:
                                            const Color(0xFFFFE29A),
                                        outlined: false,
                                      ),
                                  ],
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(10),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(12),
                                      ),
                                    ),
                                    child: Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFEAF5FB),
                                        fontSize: 10.7,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withAlpha(14),
                                  Colors.white.withAlpha(10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.insights_rounded,
                                      color: Color(0xFFD6F7FF),
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'STORE OVERVIEW',
                                        style: TextStyle(
                                          color: Color(0xFFD6F7FF),
                                          fontSize: 9.6,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.05,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Live snapshot',
                                      style: TextStyle(
                                        color: Color(0xFFDCF6FF),
                                        fontSize: 9.4,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    overviewMetric(
                                      icon: Icons.set_meal_outlined,
                                      value: '${stats.totalListings}',
                                      label: 'Fish listings',
                                      accent: const Color(0xFF8DE7FF),
                                    ),
                                    metricDivider(),
                                    overviewMetric(
                                      icon: Icons.inventory_2_outlined,
                                      value: '${stats.availableListings}',
                                      label: 'Available now',
                                      accent: const Color(0xFF9AF1C8),
                                    ),
                                    metricDivider(),
                                    overviewMetric(
                                      icon: Icons.star_outline_rounded,
                                      value: '${supplier.reviews}',
                                      label: 'Store reviews',
                                      accent: const Color(0xFFFFE08A),
                                    ),
                                  ],
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
          ],
        ),
      ),
    );
  }
}

class StoreInitial extends StatelessWidget {
  const StoreInitial({
    super.key,
    required this.initial,
  });

  final String initial;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF8FC),
            Color(0xFFD6F0FA),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF087AC0),
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SupplierStoreHeaderClipper extends CustomClipper<Path> {
  const _SupplierStoreHeaderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 38);
    path.quadraticBezierTo(
      size.width * 0.18,
      size.height - 8,
      size.width * 0.40,
      size.height - 24,
    );
    path.quadraticBezierTo(
      size.width * 0.64,
      size.height - 42,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return false;
  }
}

class _SupplierStoreBackdropPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final glowFill = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(22);

    final topGlow = Rect.fromCircle(
      center: Offset(size.width * 0.79, size.height * 0.18),
      radius: size.width * 0.30,
    );
    glowFill.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x20FFFFFF),
        Color(0x04FFFFFF),
      ],
    ).createShader(topGlow);
    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.18),
      size.width * 0.30,
      glowFill,
    );

    glowFill.color = Colors.white.withAlpha(10);
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.30),
      size.width * 0.14,
      glowFill,
    );

    glowFill.color = Colors.white.withAlpha(7);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.66),
      size.width * 0.18,
      glowFill,
    );

    final softPanel = Path()
      ..moveTo(size.width * 0.60, size.height * 0.07)
      ..lineTo(size.width * 0.97, size.height * 0.07)
      ..lineTo(size.width * 0.97, size.height * 0.57)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.64,
        size.width * 0.60,
        size.height * 0.49,
      )
      ..quadraticBezierTo(
        size.width * 0.61,
        size.height * 0.25,
        size.width * 0.60,
        size.height * 0.07,
      );
    canvas.drawPath(
      softPanel,
      Paint()..color = Colors.white.withAlpha(7),
    );

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.18),
      size.width * 0.23,
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.18),
      size.width * 0.13,
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.73),
      size.width * 0.09,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

class _SupplierStoreWaveAccentPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final fill = Paint()..style = PaintingStyle.fill;

    final shadowPath = Path()
      ..moveTo(0, size.height - 36)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height - 10,
        size.width * 0.40,
        size.height - 24,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height - 40,
        size.width,
        size.height - 8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fill.color = const Color(0x1611B8D5);
    canvas.drawPath(shadowPath.shift(const Offset(0, 10)), fill);

    final midWave = Path()
      ..moveTo(0, size.height - 22)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height - 4,
        size.width * 0.44,
        size.height - 16,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height - 28,
        size.width,
        size.height - 4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fill.color = const Color(0x1719CAE3);
    canvas.drawPath(midWave, fill);

    final highlightWave = Path()
      ..moveTo(0, size.height - 18)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height - 1,
        size.width * 0.52,
        size.height - 12,
      )
      ..quadraticBezierTo(
        size.width * 0.79,
        size.height - 22,
        size.width,
        size.height - 5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fill.color = const Color(0x12FFFFFF);
    canvas.drawPath(highlightWave, fill);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
