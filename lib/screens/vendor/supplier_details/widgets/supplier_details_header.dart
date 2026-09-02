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
    this.businessLocationPreview,
    this.showFavoriteAction = false,
    this.isFavorite = false,
    this.favoriteBusy = false,
    this.onFavoriteToggle,
    this.includeSystemTopPadding = true,
    this.showNavigationHeader = true,
  });

  final Supplier supplier;
  final SupplierDetailsStats stats;
  final VoidCallback onBack;
  final Widget? businessLocationPreview;
  final bool showFavoriteAction;
  final bool isFavorite;
  final bool favoriteBusy;
  final VoidCallback? onFavoriteToggle;
  final bool includeSystemTopPadding;
  final bool showNavigationHeader;

  bool get hasNetworkImage {
    final imageUrl = supplier.profileImageUrl.trim();
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  String get storeInitial {
    final name = supplier.name.trim();
    return name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase();
  }

  String get compactLocation {
    final parts = supplier.location
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => part.toLowerCase() != 'caraga region')
        .toList();

    if (parts.length <= 2) {
      return parts.join(', ');
    }

    return parts.sublist(parts.length - 2).join(', ');
  }

  String get cleanDescription {
    final value = supplier.description.trim();
    if (value.isEmpty) return '';

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

    if (blocked.contains(lower)) return '';

    final looksLikeRandom = !value.contains(' ') && value.length < 18;
    return looksLikeRandom ? '' : value;
  }

  Widget storePhoto() {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(195), width: 2.7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B031A31),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: hasNetworkImage
            ? Image.network(
                supplier.profileImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => StoreInitial(initial: storeInitial),
              )
            : StoreInitial(initial: storeInitial),
      ),
    );
  }

  Widget favoriteActionButton() {
    return Tooltip(
      message: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
      child: Material(
        color: isFavorite
            ? const Color(0xFFFFF0F3)
            : Colors.white.withAlpha(30),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: favoriteBusy ? null : onFavoriteToggle,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: favoriteBusy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: isFavorite
                            ? const Color(0xFFE94C72)
                            : Colors.white,
                      ),
                    )
                  : Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE94C72)
                          : Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget newSupplierBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8B8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF955700), size: 12),
          SizedBox(width: 4),
          Text(
            'New supplier',
            style: TextStyle(
              color: Color(0xFF805000),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget ratingLine() {
    final hasReviews = supplier.rating > 0 && supplier.reviews > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasReviews ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFFD166),
          size: 14,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            hasReviews
                ? '${supplier.rating.toStringAsFixed(1)} · ${supplier.reviews} review${supplier.reviews == 1 ? '' : 's'}'
                : 'No reviews yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFEAF5FB),
              fontSize: 10.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget overviewMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withAlpha(33),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: accent.withAlpha(60)),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD8EFFA),
                    fontSize: 8.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget metricDivider() {
    return Container(
      width: 1,
      height: 38,
      color: Colors.white.withAlpha(26),
      margin: const EdgeInsets.symmetric(horizontal: 9),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = includeSystemTopPadding
        ? MediaQuery.paddingOf(context).top
        : 0.0;
    final description = cleanDescription;
    final storeName = supplier.name.trim().isEmpty ? 'Supplier' : supplier.name.trim();
    final longName = storeName.length > 24;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SupplierStoreWaveAccentPainter()),
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
                    Color(0xFF0875D1),
                    Color(0xFF12BDD7),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _SupplierStoreBackdropPainter()),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 43),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showNavigationHeader) ...[
                          Row(
                            children: [
                              Material(
                                color: Colors.white.withAlpha(32),
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
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              verifiedBadge(),
                              if (showFavoriteAction) ...[
                                const SizedBox(width: 7),
                                favoriteActionButton(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withAlpha(16)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  storePhoto(),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'FRESH FISH MARKET',
                                          style: TextStyle(
                                            color: Color(0xFFCBF5FF),
                                            fontSize: 8.8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          storeName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: longName ? 19.8 : 22.2,
                                            fontWeight: FontWeight.w900,
                                            height: 1.04,
                                            letterSpacing: -0.25,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 1),
                                              child: Icon(
                                                Icons.location_on_rounded,
                                                color: Color(0xFFEAF5FB),
                                                size: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                compactLocation.isEmpty
                                                    ? supplier.location
                                                    : compactLocation,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFFEAF5FB),
                                                  fontSize: 10.1,
                                                  height: 1.24,
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
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (supplier.isNewSupplier) newSupplierBadge(),
                                  ?businessLocationPreview,
                                ],
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 11),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withAlpha(12)),
                                  ),
                                  child: Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFEAF5FB),
                                      fontSize: 10.4,
                                      height: 1.34,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(11),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withAlpha(14)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.insights_rounded,
                                    color: Color(0xFFD6F7FF),
                                    size: 13,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'STORE OVERVIEW',
                                    style: TextStyle(
                                      color: Color(0xFFD6F7FF),
                                      fontSize: 8.8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  overviewMetric(
                                    icon: Icons.set_meal_outlined,
                                    value: '${stats.totalListings}',
                                    label: 'Listings',
                                    accent: const Color(0xFF8DE7FF),
                                  ),
                                  metricDivider(),
                                  overviewMetric(
                                    icon: Icons.inventory_2_outlined,
                                    value: '${stats.availableListings}',
                                    label: 'Available',
                                    accent: const Color(0xFF9AF1C8),
                                  ),
                                  metricDivider(),
                                  overviewMetric(
                                    icon: Icons.star_outline_rounded,
                                    value: '${supplier.reviews}',
                                    label: 'Reviews',
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
