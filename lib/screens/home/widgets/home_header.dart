import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String stringValue(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    if (data == null) {
      return fallback;
    }

    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double doubleValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  bool approvedSupplier(
    Map<String, dynamic> data,
  ) {
    final status = stringValue(
      data,
      'status',
      '',
    ).toLowerCase();

    final verificationStatus = stringValue(
      data,
      'verificationStatus',
      '',
    ).toLowerCase();

    final isApproved = data['isApproved'] == true;
    final isVerified = data['isVerified'] == true;

    return status == 'approved' ||
        status == 'active' ||
        status == 'verified' ||
        verificationStatus == 'approved' ||
        verificationStatus == 'verified' ||
        isApproved ||
        isVerified;
  }

  bool availableFishStock(
    Map<String, dynamic> data,
  ) {
    final status = stringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    final quantity = doubleValue(
      data,
      'quantity',
    );

    return (status == 'available' || status == 'active') &&
        quantity > 0;
  }

  bool activeVendorOrder(
    Map<String, dynamic> data,
  ) {
    final status = stringValue(
      data,
      'orderStatus',
      '',
    ).toLowerCase();

    return status == 'pending' || status == 'accepted';
  }

  String fallbackName() {
    final displayName = currentUser?.displayName?.trim() ?? '';

    if (displayName.isNotEmpty) {
      return displayName;
    }

    final email = currentUser?.email?.trim() ?? '';

    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'IsdaLink User';
  }

  Widget buildLiveHeader({
    required BuildContext context,
    required String userName,
    required int supplierCount,
    required int fishStockCount,
    required int activeOrderCount,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDarkMode =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    final headerGradient = isDarkMode
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06101E),
              Color(0xFF082D4F),
              Color(0xFF07536C),
            ],
            stops: [
              0,
              0.56,
              1,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06355F),
              Color(0xFF0875D1),
              Color(0xFF12B6D6),
            ],
            stops: [
              0,
              0.56,
              1,
            ],
          );

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: isDarkMode
          ? const Color(0xFF06101E)
          : const Color(0xFF06355F),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _PremiumWaveTransitionPainter(
                    isDarkMode: isDarkMode,
                  ),
                ),
              ),
            ),
            ClipPath(
              clipper: const _PremiumHomeHeaderClipper(),
              clipBehavior: Clip.hardEdge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF06101E)
                      : const Color(0xFF06355F),
                  gradient: headerGradient,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _PremiumMarineBackdropPainter(
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        topPadding + 6,
                        12,
                        29,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PremiumHeaderTopBar(
                            isDarkMode: isDarkMode,
                            onProfileTap: onProfileTap,
                            onLogout: onLogout,
                          ),
                          const SizedBox(height: 14),
                          _PremiumGreeting(
                            userName: userName,
                          ),
                          const SizedBox(height: 12),
                          _PremiumSearchBar(
                            onTap: onSearchTap,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 10),
                          _PremiumNetworkPanel(
                            supplierCount: supplierCount,
                            fishStockCount: fishStockCount,
                            activeOrderCount: activeOrderCount,
                            isDarkMode: isDarkMode,
                            onSuppliersTap: onSuppliersTap,
                            onFishStocksTap: onFishStocksTap,
                            onActiveOrdersTap: onActiveOrdersTap,
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final uid = currentUser?.uid;

    if (uid == null || uid.trim().isEmpty) {
      return buildLiveHeader(
        context: context,
        userName: fallbackName(),
        supplierCount: 0,
        fishStockCount: 0,
        activeOrderCount: 0,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userName = stringValue(
          userSnapshot.data?.data(),
          'name',
          fallbackName(),
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('supplierProfiles')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, supplierSnapshot) {
            final supplierCount = supplierSnapshot.hasData
                ? supplierSnapshot.data!.docs.where(
                    (document) {
                      return approvedSupplier(
                        document.data(),
                      );
                    },
                  ).length
                : 0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('fishStocks')
                  .snapshots(),
              builder: (context, stockSnapshot) {
                final fishStockCount = stockSnapshot.hasData
                    ? stockSnapshot.data!.docs.where(
                        (document) {
                          return availableFishStock(
                            document.data(),
                          );
                        },
                      ).length
                    : 0;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where(
                        'vendorId',
                        isEqualTo: uid,
                      )
                      .snapshots(),
                  builder: (context, orderSnapshot) {
                    final activeOrderCount = orderSnapshot.hasData
                        ? orderSnapshot.data!.docs.where(
                            (document) {
                              return activeVendorOrder(
                                document.data(),
                              );
                            },
                          ).length
                        : 0;

                    return buildLiveHeader(
                      context: context,
                      userName: userName,
                      supplierCount: supplierCount,
                      fishStockCount: fishStockCount,
                      activeOrderCount: activeOrderCount,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PremiumHeaderTopBar extends StatelessWidget {
  const _PremiumHeaderTopBar({
    required this.isDarkMode,
    required this.onProfileTap,
    required this.onLogout,
  });

  final bool isDarkMode;
  final VoidCallback? onProfileTap;
  final VoidCallback onLogout;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        const Expanded(
          child: _BrandLockup(),
        ),
        _RegionChip(
          isDarkMode: isDarkMode,
        ),
        const SizedBox(width: 7),
        _PremiumActionButton(
          icon: Icons.person_rounded,
          tooltip: 'Profile',
          onTap: onProfileTap,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(width: 6),
        _PremiumActionButton(
          icon: Icons.logout_rounded,
          tooltip: 'Log out',
          onTap: onLogout,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withAlpha(42),
            ),
          ),
          child: const Icon(
            Icons.set_meal_rounded,
            color: Color(0xFFE9FDFF),
            size: 17,
          ),
        ),
        const SizedBox(width: 8),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ISDALINK',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.8,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.35,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'FISH SUPPLY NETWORK',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFBFEFF3),
                  fontSize: 6.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.72,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.isDarkMode,
  });

  final bool isDarkMode;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(
          isDarkMode ? 17 : 24,
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withAlpha(
            isDarkMode ? 22 : 36,
          ),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Color(0xFFE9FDFF),
            size: 13,
          ),
          SizedBox(width: 4),
          Text(
            'Caraga',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActionButton extends StatelessWidget {
  const _PremiumActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDarkMode,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDarkMode;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(
          isDarkMode ? 17 : 24,
        ),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          splashColor: Colors.white.withAlpha(28),
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: Colors.white.withAlpha(
                  isDarkMode ? 20 : 34,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumGreeting extends StatelessWidget {
  const _PremiumGreeting({
    required this.userName,
  });

  final String userName;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SizedBox(
              width: 18,
              child: Divider(
                color: Color(0xFF82E9F1),
                thickness: 2,
                height: 2,
              ),
            ),
            SizedBox(width: 7),
            Text(
              'GOOD DAY',
              style: TextStyle(
                color: Color(0xFFCBF4F7),
                fontSize: 8.4,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            height: 1.03,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Fresh fish, trusted suppliers, and clear Cash on Delivery order tracking.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFFDDF5F7),
            fontSize: 11.1,
            height: 1.36,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PremiumSearchBar extends StatelessWidget {
  const _PremiumSearchBar({
    required this.onTap,
    required this.isDarkMode,
  });

  final VoidCallback onTap;
  final bool isDarkMode;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Semantics(
      button: true,
      label: 'Search IsdaLink marketplace',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 50,
            padding: const EdgeInsets.fromLTRB(8, 5, 7, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white,
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    isDarkMode ? 32 : 25,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF47728A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search IsdaLink Market',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF163C55),
                          fontSize: 11.1,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fish, suppliers, or locations',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF8AA0AF),
                          fontSize: 8.4,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0875D1),
                        Color(0xFF10ACC9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2B0875D1),
                        blurRadius: 9,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white,
                    size: 17,
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

class _PremiumNetworkPanel extends StatelessWidget {
  const _PremiumNetworkPanel({
    required this.supplierCount,
    required this.fishStockCount,
    required this.activeOrderCount,
    required this.isDarkMode,
    this.onSuppliersTap,
    this.onFishStocksTap,
    this.onActiveOrdersTap,
  });

  final int supplierCount;
  final int fishStockCount;
  final int activeOrderCount;
  final bool isDarkMode;
  final VoidCallback? onSuppliersTap;
  final VoidCallback? onFishStocksTap;
  final VoidCallback? onActiveOrdersTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        9,
        10,
        9,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(
              isDarkMode ? 20 : 34,
            ),
            Colors.white.withAlpha(
              isDarkMode ? 9 : 17,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withAlpha(
            isDarkMode ? 22 : 42,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              isDarkMode ? 30 : 19,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF8AF0B0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x668AF0B0),
                      blurRadius: 7,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'LIVE MARKETPLACE',
                style: TextStyle(
                  color: Color(0xFFD8F7F5),
                  fontSize: 7.8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
              const Spacer(),
              const Text(
                'Tap to explore',
                style: TextStyle(
                  color: Color(0xFFBCE8EC),
                  fontSize: 7.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PremiumMetricItem(
                  icon: Icons.storefront_rounded,
                  value: supplierCount,
                  label: 'Suppliers',
                  accentColor: const Color(0xFFA8F0DC),
                  onTap: onSuppliersTap,
                ),
              ),
              const _PremiumMetricDivider(),
              Expanded(
                child: _PremiumMetricItem(
                  icon: Icons.set_meal_rounded,
                  value: fishStockCount,
                  label: 'Fish Stocks',
                  accentColor: const Color(0xFFAEEBFF),
                  onTap: onFishStocksTap,
                ),
              ),
              const _PremiumMetricDivider(),
              Expanded(
                child: _PremiumMetricItem(
                  icon: Icons.receipt_long_rounded,
                  value: activeOrderCount,
                  label: 'Active Orders',
                  accentColor: const Color(0xFFFFDEA0),
                  onTap: onActiveOrdersTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumMetricDivider extends StatelessWidget {
  const _PremiumMetricDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 1,
      height: 35,
      margin: const EdgeInsets.symmetric(
        horizontal: 3,
      ),
      color: Colors.white.withAlpha(39),
    );
  }
}

class _PremiumMetricItem extends StatelessWidget {
  const _PremiumMetricItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Semantics(
      button: onTap != null,
      label: 'Open $label',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: Colors.white.withAlpha(23),
          highlightColor: Colors.white.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(32),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withAlpha(70),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD8F3F5),
                          fontSize: 7.8,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _PremiumHeaderWaveGeometry {
  const _PremiumHeaderWaveGeometry._();

  static Path clipPath(
    Size size,
  ) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(
        0,
        size.height - 31,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height - 17,
        size.width * 0.38,
        size.height - 7,
        size.width * 0.56,
        size.height - 11,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height - 15,
        size.width * 0.87,
        size.height - 31,
        size.width + 8,
        size.height - 33,
      )
      ..lineTo(
        size.width + 8,
        0,
      )
      ..close();

    return path;
  }

  static Path bottomEdge(
    Size size,
  ) {
    return Path()
      ..moveTo(
        -8,
        size.height - 31,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height - 17,
        size.width * 0.38,
        size.height - 7,
        size.width * 0.56,
        size.height - 11,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height - 15,
        size.width * 0.87,
        size.height - 31,
        size.width + 10,
        size.height - 33,
      );
  }
}

class _PremiumHomeHeaderClipper extends CustomClipper<Path> {
  const _PremiumHomeHeaderClipper();

  @override
  Path getClip(
    Size size,
  ) {
    return _PremiumHeaderWaveGeometry.clipPath(
      size,
    );
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return false;
  }
}

class _PremiumWaveTransitionPainter extends CustomPainter {
  const _PremiumWaveTransitionPainter({
    required this.isDarkMode,
  });

  final bool isDarkMode;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final wave = _PremiumHeaderWaveGeometry.bottomEdge(
      size,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(
        isDarkMode ? 52 : 32,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawPath(
      wave,
      shadowPaint,
    );

    final underglowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF0B76C8),
          Color(0xFF16B8D5),
          Color(0xFF77E6EB),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          size.height - 45,
          size.width,
          32,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      wave,
      underglowPaint,
    );

    final foamPaint = Paint()
      ..color = Colors.white.withAlpha(
        isDarkMode ? 42 : 104,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      wave,
      foamPaint,
    );

    final softHighlightPaint = Paint()
      ..color = const Color(0xFFBFF8FA).withAlpha(
        isDarkMode ? 28 : 62,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        3,
      );

    canvas.drawPath(
      wave,
      softHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PremiumWaveTransitionPainter oldDelegate,
  ) {
    return oldDelegate.isDarkMode != isDarkMode;
  }
}

class _PremiumMarineBackdropPainter extends CustomPainter {
  const _PremiumMarineBackdropPainter({
    required this.isDarkMode,
  });

  final bool isDarkMode;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final glowCenter = Offset(
      size.width * 0.87,
      size.height * 0.28,
    );

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(
            isDarkMode ? 12 : 22,
          ),
          Colors.white.withAlpha(0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: glowCenter,
          radius: size.width * 0.42,
        ),
      );

    canvas.drawCircle(
      glowCenter,
      size.width * 0.42,
      glowPaint,
    );

    final ringPaint = Paint()
      ..color = Colors.white.withAlpha(
        isDarkMode ? 5 : 10,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final radius in [
      size.width * 0.10,
      size.width * 0.18,
    ]) {
      canvas.drawCircle(
        Offset(
          size.width * 0.93,
          size.height * 0.36,
        ),
        radius,
        ringPaint,
      );
    }

    final wavePaint = Paint()
      ..color = Colors.white.withAlpha(
        isDarkMode ? 5 : 10,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final upperWave = Path()
      ..moveTo(
        -20,
        size.height * 0.27,
      )
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.18,
        size.width * 0.47,
        size.height * 0.37,
        size.width + 24,
        size.height * 0.22,
      );

    final lowerWave = Path()
      ..moveTo(
        -24,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.60,
        size.width * 0.58,
        size.height * 0.82,
        size.width + 22,
        size.height * 0.66,
      );

    canvas
      ..drawPath(
        upperWave,
        wavePaint,
      )
      ..drawPath(
        lowerWave,
        wavePaint,
      );
  }

  @override
  bool shouldRepaint(
    covariant _PremiumMarineBackdropPainter oldDelegate,
  ) {
    return oldDelegate.isDarkMode != isDarkMode;
  }
}
