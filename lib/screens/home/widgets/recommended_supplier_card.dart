import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class RecommendedSupplierCard extends StatefulWidget {
  const RecommendedSupplierCard({
    super.key,
    required this.supplier,
    required this.supplierId,
    required this.onTap,
    this.availableListingCount,
  });

  final Supplier supplier;
  final String supplierId;
  final VoidCallback onTap;
  final int? availableListingCount;

  @override
  State<RecommendedSupplierCard> createState() =>
      _RecommendedSupplierCardState();
}

class _RecommendedSupplierCardState extends State<RecommendedSupplierCard> {
  final FavoriteSupplierService favoriteService = FavoriteSupplierService();

  bool favoriteBusy = false;

  Supplier get supplier => widget.supplier;

  bool get hasNetworkImage {
    final imageUrl = supplier.profileImageUrl.trim();
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  bool get canFavorite {
    final currentUserId = favoriteService.currentUserId;
    final supplierId = widget.supplierId.trim();

    return currentUserId != null &&
        supplierId.isNotEmpty &&
        supplierId != currentUserId;
  }

  String get storeInitial {
    final name = supplier.name.trim();
    return name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase();
  }

  String get reviewLabel {
    if (supplier.reviews <= 0 || supplier.rating <= 0) {
      return 'No reviews yet';
    }

    return '${supplier.rating.toStringAsFixed(1)} · ${supplier.reviews} review${supplier.reviews == 1 ? '' : 's'}';
  }


  String get compactLocation {
    final rawLocation = supplier.location.trim();

    if (rawLocation.isEmpty) {
      return 'Caraga Region';
    }

    final parts = rawLocation
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => part.toLowerCase() != 'caraga region')
        .toList();

    if (parts.isEmpty) {
      return 'Caraga Region';
    }

    if (parts.length == 1) {
      return parts.first;
    }

    return '${parts[parts.length - 2]}, ${parts.last}';
  }

  Future<void> toggleFavorite(bool currentlyFavorite) async {
    if (favoriteBusy || !canFavorite) {
      return;
    }

    setState(() {
      favoriteBusy = true;
    });

    try {
      await favoriteService.toggleFavorite(
        supplierId: widget.supplierId,
        currentlyFavorite: currentlyFavorite,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              currentlyFavorite
                  ? 'Supplier removed from Favorites.'
                  : 'Supplier added to Favorites.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.from(
                error,
                fallback: 'Unable to update Favorites right now.',
                allowBusinessMessage: true,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          favoriteBusy = false;
        });
      }
    }
  }

  Widget buildStorePhoto() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30002842),
            blurRadius: 13,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: hasNetworkImage
            ? Image.network(
                supplier.profileImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return StoreInitial(initial: storeInitial);
                },
              )
            : StoreInitial(initial: storeInitial),
      ),
    );
  }

  Widget newSupplierBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8952F),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35E8892D),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 10),
          const SizedBox(width: 3),
          Text(
            'NEW · ${supplier.newSupplierDaysRemaining}D',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget verifiedMark() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withAlpha(48)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF9CF5ED), size: 11),
          SizedBox(width: 3),
          Text(
            'VERIFIED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget favoriteButton() {
    if (!canFavorite) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: favoriteService.isFavoriteStream(widget.supplierId),
      initialData: false,
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: favoriteBusy ? null : () => toggleFavorite(isFavorite),
            customBorder: const CircleBorder(),
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4EBF5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A00334E),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: favoriteBusy
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0A73D8),
                      ),
                    )
                  : Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE94D67)
                          : const Color(0xFF0A73D8),
                      size: 15,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget banner() {
    return SizedBox(
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF063D68),
                  Color(0xFF087CC4),
                  Color(0xFF12B5CE),
                ],
                stops: [0, 0.60, 1],
              ),
            ),
          ),
          const Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
              child: CustomPaint(
                painter: _IsdaLinkSupplierBannerPainter(),
              ),
            ),
          ),
          if (supplier.isNewSupplier)
            Positioned(
              left: 10,
              top: 9,
              child: newSupplierBadge(),
            ),
          Positioned(
            right: 10,
            top: 9,
            child: favoriteButton(),
          ),
          Positioned(
            right: 10,
            bottom: 9,
            child: verifiedMark(),
          ),
          Positioned(
            left: 12,
            bottom: -23,
            child: buildStorePhoto(),
          ),
        ],
      ),
    );
  }

  Widget reviewMeta() {
    final hasReviews = supplier.reviews > 0 && supplier.rating > 0;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasReviews ? Icons.star_rounded : Icons.star_border_rounded,
            color: hasReviews
                ? const Color(0xFFE89A20)
                : const Color(0xFF7890A1),
            size: 11.5,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              reviewLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasReviews
                    ? const Color(0xFF7F5A17)
                    : const Color(0xFF6F8798),
                fontSize: 8.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget availableMeta() {
    final count = widget.availableListingCount;

    if (count == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF0877C9),
          size: 10.8,
        ),
        const SizedBox(width: 3),
        Text(
          count == 1 ? '1 available' : '$count available',
          style: const TextStyle(
            color: Color(0xFF0877C9),
            fontSize: 8.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = compactLocation;
    final storeName = supplier.name.trim().isEmpty
        ? 'Verified Supplier'
        : supplier.name.trim();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.56).clamp(205.0, 224.0).toDouble();

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 0,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: const Color(0x160A73D8),
          highlightColor: const Color(0x090A73D8),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD3E7F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x17002842),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                banner(),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF102F46),
                            fontSize: 12.8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: Color(0xFF6C8BA0),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B8799),
                            fontSize: 8.6,
                            height: 1.18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    children: [
                      reviewMeta(),
                      if (widget.availableListingCount != null) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 1,
                          height: 11,
                          color: const Color(0xFFD9E5EC),
                        ),
                        const SizedBox(width: 7),
                        availableMeta(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF2FAFE),
                          Color(0xFFEAF8FD),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4EBF5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF0877C9),
                          size: 13,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View store',
                          style: TextStyle(
                            color: Color(0xFF0877C9),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF0877C9),
                          size: 13,
                        ),
                      ],
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

class _IsdaLinkSupplierBannerPainter extends CustomPainter {
  const _IsdaLinkSupplierBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = Colors.white.withAlpha(11);
    canvas.drawCircle(
      Offset(size.width * 0.89, size.height * 0.08),
      size.width * 0.25,
      glow,
    );

    final routePaint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final route = Path()
      ..moveTo(size.width * 0.42, size.height * 0.22)
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.08,
        size.width * 0.62,
        size.height * 0.45,
        size.width * 0.74,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.18,
        size.width * 0.92,
        size.height * 0.58,
        size.width * 1.04,
        size.height * 0.42,
      );
    canvas.drawPath(route, routePaint);

    final nodePaint = Paint()..color = const Color(0xFF8FE9F2).withAlpha(125);
    final nodes = <Offset>[
      Offset(size.width * 0.48, size.height * 0.19),
      Offset(size.width * 0.64, size.height * 0.34),
      Offset(size.width * 0.80, size.height * 0.26),
      Offset(size.width * 0.91, size.height * 0.46),
    ];
    for (final node in nodes) {
      canvas.drawCircle(node, 2.2, nodePaint);
      canvas.drawCircle(
        node,
        4.8,
        Paint()
          ..color = Colors.white.withAlpha(18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final wavePaint = Paint()
      ..color = const Color(0xFF73E4EA).withAlpha(38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final wave = Path()
      ..moveTo(-10, size.height * 0.77)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.58,
        size.width * 0.43,
        size.height * 0.90,
        size.width * 0.66,
        size.height * 0.69,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.54,
        size.width * 0.96,
        size.height * 0.65,
        size.width + 10,
        size.height * 0.51,
      );
    canvas.drawPath(wave, wavePaint);

    final fishPaint = Paint()..color = Colors.white.withAlpha(15);
    final fishCenter = Offset(size.width * 0.67, size.height * 0.70);
    final fishBody = Rect.fromCenter(
      center: fishCenter,
      width: 34,
      height: 14,
    );
    canvas.drawOval(fishBody, fishPaint);
    final tail = Path()
      ..moveTo(fishCenter.dx - 17, fishCenter.dy)
      ..lineTo(fishCenter.dx - 28, fishCenter.dy - 8)
      ..lineTo(fishCenter.dx - 28, fishCenter.dy + 8)
      ..close();
    canvas.drawPath(tail, fishPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StoreInitial extends StatelessWidget {
  const StoreInitial({
    super.key,
    required this.initial,
  });

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F8FD),
            Color(0xFFD4F2FA),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF0875D1),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
