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
    this.isOwnerView = false,
    this.profileImageUrlOverride,
    this.coverImageUrlOverride,
    this.profileImageBusy = false,
    this.coverImageBusy = false,
    this.onEditProfileImage,
    this.onEditCoverImage,
    this.onProfileImageTap,
    this.onCoverImageTap,
  });

  final Supplier supplier;
  final SupplierDetailsStats stats;
  final VoidCallback onBack;
  final Widget? businessLocationPreview;
  final bool showFavoriteAction;
  final bool isFavorite;
  final bool favoriteBusy;
  final VoidCallback? onFavoriteToggle;
  final bool isOwnerView;
  final String? profileImageUrlOverride;
  final String? coverImageUrlOverride;
  final bool profileImageBusy;
  final bool coverImageBusy;
  final VoidCallback? onEditProfileImage;
  final VoidCallback? onEditCoverImage;
  final VoidCallback? onProfileImageTap;
  final VoidCallback? onCoverImageTap;

  String get profileImageUrl =>
      (profileImageUrlOverride ?? supplier.profileImageUrl).trim();

  String get coverImageUrl =>
      (coverImageUrlOverride ?? supplier.coverImageUrl).trim();

  bool isNetworkImage(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
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
    const blocked = <String>{
      'n/a',
      'na',
      'none',
      'test',
      'sample',
      'placeholder',
      'asdasd',
      'asdf',
    };

    if (blocked.contains(lower)) return '';
    if (!value.contains(' ') && value.length < 18) return '';
    return value;
  }

  Widget circleAction({
    required IconData icon,
    required VoidCallback? onTap,
    bool busy = false,
    Color foreground = const Color(0xFF0A4E7E),
  }) {
    return Material(
      color: Colors.white.withAlpha(238),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(35),
      child: InkWell(
        onTap: busy ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : Icon(icon, color: foreground, size: 21),
          ),
        ),
      ),
    );
  }

  Widget coverBackground() {
    if (isNetworkImage(coverImageUrl)) {
      return Image.network(
        coverImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _StorefrontFallback();
        },
        errorBuilder: (_, _, _) => const _StorefrontFallback(),
      );
    }

    return const _StorefrontFallback();
  }

  Widget profileImage() {
    // Use a real white outer ring instead of drawing the image under a border.
    // This keeps the storefront avatar crisp against both photo and blank covers.
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x2B00182A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: isNetworkImage(profileImageUrl)
            ? Image.network(
                profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => StoreInitial(initial: storeInitial),
              )
            : StoreInitial(initial: storeInitial),
      ),
    );
  }

  Widget profileImageWithOwnerControl() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onProfileImageTap,
          child: profileImage(),
        ),
        if (isOwnerView)
          Positioned(
            right: -2,
            bottom: 0,
            child: Material(
              color: const Color(0xFF087AC0),
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                onTap: profileImageBusy ? null : onEditProfileImage,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 29,
                  height: 29,
                  child: Center(
                    child: profileImageBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget verifiedBadge() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8EDF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16002D46),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.verified_rounded,
        color: Color(0xFF0B8FC4),
        size: 19,
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
          color: const Color(0xFFFFB51B),
          size: 18,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            hasReviews
                ? '${supplier.rating.toStringAsFixed(1)} (${supplier.reviews} review${supplier.reviews == 1 ? '' : 's'})'
                : 'No reviews yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.6,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  String memberSinceValue() {
    final createdAt = supplier.accountCreatedAt;
    if (createdAt == null) {
      return '${stats.availableListings}';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = createdAt.toLocal();
    return '${months[local.month - 1]} ${local.day}';
  }

  String memberSinceLabel() {
    final createdAt = supplier.accountCreatedAt;
    if (createdAt == null) {
      return 'Available';
    }
    return 'Member Since · ${createdAt.toLocal().year}';
  }

  Widget summaryMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7FD),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: const Color(0xFF0A6094), size: 15),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF103B5C),
                      fontSize: 11.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B91A3),
                fontSize: 8.1,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final description = cleanDescription;
    final storeName = supplier.name.trim().isEmpty
        ? 'Supplier'
        : supplier.name.trim();
    final hasPublicCover = isNetworkImage(coverImageUrl);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Builder(
        builder: (context) {
          // Slightly taller than the compact version so the store identity
          // remains comfortably visible above the curved storefront body.
          final heroHeight = topPadding + (hasPublicCover ? 246.0 : 224.0);

          return SizedBox(
            height: heroHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Rear layer: supplier hero / cover.
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: hasPublicCover ? onCoverImageTap : null,
                        child: coverBackground(),
                      ),
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x2C001A2C),
                                Color(0x42001C31),
                                Color(0xE500385B),
                              ],
                              stops: [0.0, 0.44, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        top: topPadding + 12,
                        child: Row(
                          children: [
                            circleAction(
                              icon: Icons.arrow_back_rounded,
                              onTap: onBack,
                            ),
                            const Spacer(),
                            verifiedBadge(),
                            const SizedBox(width: 8),
                            if (isOwnerView)
                              circleAction(
                                icon: Icons.photo_camera_back_outlined,
                                onTap: onEditCoverImage,
                                busy: coverImageBusy,
                              )
                            else if (showFavoriteAction)
                              circleAction(
                                icon: isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onTap: onFavoriteToggle,
                                busy: favoriteBusy,
                                foreground: isFavorite
                                    ? const Color(0xFFE94C72)
                                    : const Color(0xFF0A4E7E),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 38,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            profileImageWithOwnerControl(),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    storeName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20.5,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ratingLine(),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          compactLocation.isEmpty
                                              ? supplier.location
                                              : compactLocation,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.2,
                                            height: 1.25,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFEAF6FC),
                                        fontSize: 10.2,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
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
          );
        },
      ),
    );
  }
}

class StoreInitial extends StatelessWidget {
  const StoreInitial({super.key, required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF8FC), Color(0xFFD6F0FA)],
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

class _StorefrontFallback extends StatelessWidget {
  const _StorefrontFallback();

  @override
  Widget build(BuildContext context) {
    // Intentionally blank storefront cover. A supplier's application/store
    // verification photo is not used as public branding. The owner can add a
    // cover later from View My Shop.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4F78), Color(0xFF0873A9), Color(0xFF0B88B2)],
        ),
      ),
    );
  }
}
