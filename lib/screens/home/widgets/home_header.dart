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
  });

  final VoidCallback onLogout;
  final VoidCallback onSearchTap;
  final VoidCallback? onProfileTap;

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

    return (status == 'available' || status == 'active') && quantity > 0;
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
    final isDarkMode = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    final headerGradient = isDarkMode
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071223),
              Color(0xFF0B1E38),
              Color(0xFF0C2D4A),
            ],
            stops: [0, 0.58, 1],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E69D5),
              Color(0xFF1588E6),
              Color(0xFF21C0D7),
            ],
            stops: [0, 0.58, 1],
          );

    final searchButtonGradient = isDarkMode
        ? const LinearGradient(
            colors: [
              Color(0xFF143E67),
              Color(0xFF155F7A),
            ],
          )
        : const LinearGradient(
            colors: [
              Color(0xFF0E69D5),
              Color(0xFF1AB8D8),
            ],
          );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDarkMode ? const Color(0xFF071223) : const Color(0xFF0E69D5),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: ClipPath(
        clipper: const _HomeHeaderClipper(),
        clipBehavior: Clip.hardEdge,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            14,
            topPadding + 6,
            14,
            30,
          ),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF071223)
              : const Color(0xFF0E69D5),
          gradient: headerGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -18,
              right: -36,
              child: _MarineBubble(
                size: 160,
                opacity: isDarkMode ? 8 : 16,
              ),
            ),
            Positioned(
              right: 54,
              bottom: -42,
              child: _MarineBubble(
                size: 118,
                opacity: isDarkMode ? 6 : 12,
              ),
            ),
            Positioned(
              left: -56,
              bottom: -70,
              child: _MarineBubble(
                size: 140,
                opacity: isDarkMode ? 6 : 12,
              ),
            ),
            Positioned(
              top: 46,
              right: -20,
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(
                      isDarkMode ? 8 : 17,
                    ),
                    width: 1.1,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ISDALINK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.45,
                        ),
                      ),
                    ),
                    _RegionChip(isDarkMode: isDarkMode),
                    const SizedBox(width: 8),
                    _HeaderCircleButton(
                      icon: Icons.person_rounded,
                      tooltip: 'Profile',
                      onTap: onProfileTap,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 7),
                    _HeaderCircleButton(
                      icon: Icons.logout_rounded,
                      tooltip: 'Log out',
                      onTap: onLogout,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Good day,',
                  style: TextStyle(
                    color: Color(0xFFD8F4F5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Find fresh fish, verified suppliers, and track your Cash on Delivery orders.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE0F5F6),
                    fontSize: 11.4,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 0,
                  child: InkWell(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26002339),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF68879B),
                            size: 22,
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Text(
                              'Search fish, suppliers, or locations',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF98AAB8),
                                fontSize: 11.7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: searchButtonGradient,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.set_meal_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderStatCard(
                        icon: Icons.storefront_outlined,
                        value: supplierCount,
                        label: 'Suppliers',
                        isDarkMode: isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _HeaderStatCard(
                        icon: Icons.set_meal_outlined,
                        value: fishStockCount,
                        label: 'Fish Stocks',
                        isDarkMode: isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _HeaderStatCard(
                        icon: Icons.receipt_long_outlined,
                        value: activeOrderCount,
                        label: 'Active Orders',
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          ),
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
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        final userName = stringValue(
          userSnapshot.data?.data(),
          'name',
          fallbackName(),
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('supplierProfiles').snapshots(),
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
              stream: FirebaseFirestore.instance.collection('fishStocks').snapshots(),
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

class _MarineBubble extends StatelessWidget {
  const _MarineBubble({
    required this.size,
    required this.opacity,
  });

  final double size;
  final int opacity;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HomeHeaderClipper extends CustomClipper<Path> {
  const _HomeHeaderClipper();

  @override
  Path getClip(
    Size size,
  ) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height - 22)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height - 5,
        size.width * 0.50,
        size.height - 2,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height - 5,
        size.width + 2,
        size.height - 22,
      )
      ..lineTo(size.width + 2, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return false;
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
      height: 32,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(
          isDarkMode ? 18 : 28,
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withAlpha(
            isDarkMode ? 20 : 34,
          ),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            'Caraga Region',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
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
          isDarkMode ? 18 : 28,
        ),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDarkMode,
  });

  final IconData icon;
  final int value;
  final String label;
  final bool isDarkMode;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(
          isDarkMode ? 14 : 24,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withAlpha(
            isDarkMode ? 18 : 30,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFFE4FAFB),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$value $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
