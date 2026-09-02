import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'package:isdalink/screens/home/widgets/home_bottom_nav.dart';
import 'package:isdalink/screens/home/widgets/home_header.dart';
import 'package:isdalink/screens/home/widgets/home_carousel_physics.dart';
import 'package:isdalink/screens/home/widgets/home_section_header.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_posts.dart';
import 'package:isdalink/screens/home/widgets/recommended_supplier_card.dart';
import 'package:isdalink/screens/home/widgets/top_selling_fish_strip.dart';
import 'package:isdalink/screens/profile/me_screen.dart';
import 'package:isdalink/screens/vendor/browse_suppliers_screen.dart';
import 'package:isdalink/screens/vendor/latest_fish_stocks_screen.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/services/search_history_service.dart';
import 'package:isdalink/services/push_notification_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class HomeScreen
    extends
        StatelessWidget {
  const HomeScreen({
    super.key,
  });

  SupplierBrowseService get supplierService => const SupplierBrowseService();
  HomeStockService get stockService => const HomeStockService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<
    void
  >
  logout(
    BuildContext context,
  ) async {
    await PushNotificationService.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const WelcomeScreen(),
      ),
      (
        route,
      ) => false,
    );
  }

  void openAnalytics(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const AnalyticsScreen(
              mode: AnalyticsMode.vendor,
            ),
      ),
    );
  }

  void openBrowseSuppliers(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const BrowseSuppliersScreen(),
      ),
    );
  }

  void openHomeSearch(
    BuildContext context,
  ) {
    showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (
            sheetContext,
          ) {
            return HomeSearchSheet(
              onSupplierTap:
                  (
                    supplier,
                    supplierId,
                  ) {
                    openSupplierDetails(
                      context,
                      supplier,
                      supplierId: supplierId,
                    );
                  },
              onProductTap:
                  (
                    supplier,
                    product,
                    stockId,
                    supplierId,
                  ) {
                    openProductDetails(
                      context,
                      supplier,
                      product,
                      stockId: stockId,
                      supplierId: supplierId,
                    );
                  },
            );
          },
    );
  }

  void openMyOrders(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const MyOrdersScreen(),
      ),
    );
  }

  void openLatestFishStocks(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LatestFishStocksScreen(),
      ),
    );
  }

  void openMe(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const MeScreen(),
      ),
    );
  }

  void openSupplierDetails(
    BuildContext context,
    Supplier supplier, {
    String? supplierId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => SupplierDetailsScreen(
              supplier: supplier,
              supplierId: supplierId,
            ),
      ),
    );
  }

  void openProductDetails(
    BuildContext context,
    Supplier supplier,
    FishProduct product, {
    String stockId = '',
    String supplierId = '',
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => ProductDetailsScreen(
              supplier: supplier,
              product: product,
              stockId: stockId,
              supplierId: supplierId,
            ),
      ),
    );
  }

  Widget recommendedSuppliersList(
    BuildContext context,
  ) {
    return SizedBox(
      height: 205,
      child:
          StreamBuilder<
            QuerySnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: supplierService.suppliersStream,
            builder:
                (
                  context,
                  snapshot,
                ) {
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 4,
                      ),
                      scrollDirection: Axis.horizontal,
                      children: [
                        homeSupplierMessageCard(
                          icon: Icons.error_outline,
                          title: 'Unable to load suppliers',
                          subtitle: 'Please refresh the Home dashboard and try again.',
                          isError: true,
                        ),
                      ],
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final allApprovedSuppliers = supplierService.approvedSuppliers(
                    snapshot.data!.docs,
                  );
                  final currentUid = currentUser?.uid.trim() ?? '';
                  final recommendationPool = allApprovedSuppliers.where((document) {
                    if (currentUid.isEmpty) {
                      return true;
                    }

                    final data = document.data();
                    final supplierIds = <String>{
                      document.id.trim(),
                      for (final key in const [
                        'supplierId',
                        'userId',
                        'uid',
                      ])
                        if ((data[key] ?? '').toString().trim().isNotEmpty)
                          (data[key] ?? '').toString().trim(),
                    };

                    return !supplierIds.contains(currentUid);
                  }).toList();
                  final approvedSuppliers = recommendationPool.take(5).toList();

                  if (approvedSuppliers.isEmpty) {
                    final hasOnlyOwnStore =
                        allApprovedSuppliers.isNotEmpty && recommendationPool.isEmpty;

                    return ListView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 4,
                      ),
                      scrollDirection: Axis.horizontal,
                      children: [
                        homeSupplierMessageCard(
                          icon: Icons.storefront_outlined,
                          title: hasOnlyOwnStore
                              ? 'No other suppliers yet'
                              : 'No approved suppliers yet',
                          subtitle: hasOnlyOwnStore
                              ? 'Other approved supplier stores will appear here when available.'
                              : 'Approved supplier stores will appear here when available.',
                        ),
                      ],
                    );
                  }

                  return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>
                  >(
                    stream: stockService.allFishPostsStream,
                    builder: (context, stockSnapshot) {
                      final availableCounts = <String, int>{};

                      if (stockSnapshot.hasData) {
                        final availableStocks = stockService.availableStocks(
                          stockSnapshot.data!.docs,
                        );

                        for (final stock in availableStocks) {
                          final supplierId =
                              (stock.data()['supplierId'] ?? '')
                                  .toString()
                                  .trim();

                          if (supplierId.isEmpty) {
                            continue;
                          }

                          availableCounts.update(
                            supplierId,
                            (currentCount) => currentCount + 1,
                            ifAbsent: () => 1,
                          );
                        }
                      }

                      final List<Widget> cards =
                          approvedSuppliers.map<Widget>((document) {
                        final data = document.data();
                        final supplier =
                            supplierService.supplierFromProfile(data);
                        final supplierIds = <String>{
                          document.id,
                          for (final key in const [
                            'supplierId',
                            'userId',
                            'uid',
                          ])
                            if ((data[key] ?? '').toString().trim().isNotEmpty)
                              (data[key] ?? '').toString().trim(),
                        };

                        int? availableListingCount;

                        if (stockSnapshot.hasData) {
                          availableListingCount = 0;
                          for (final supplierId in supplierIds) {
                            final count = availableCounts[supplierId];
                            if (count != null && count > availableListingCount!) {
                              availableListingCount = count;
                            }
                          }
                        }

                        return RecommendedSupplierCard(
                          supplier: supplier,
                          supplierId: document.id,
                          availableListingCount: availableListingCount,
                          onTap: () => openSupplierDetails(
                            context,
                            supplier,
                            supplierId: document.id,
                          ),
                        );
                      }).toList();

                      if (allApprovedSuppliers.length >
                          approvedSuppliers.length) {
                        cards.add(
                          homeSupplierExploreCard(
                            totalSuppliers: allApprovedSuppliers.length,
                            onTap: () => openBrowseSuppliers(context),
                          ),
                        );
                      }

                      final screenWidth = MediaQuery.sizeOf(context).width;
                      final cardWidth = (screenWidth * 0.56)
                          .clamp(205.0, 224.0)
                          .toDouble();

                      return _HomeSupplierSnappingCarousel(
                        itemExtent: cardWidth + 12,
                        children: cards,
                      );
                    },
                  );
                },
          ),
    );
  }

  Widget homeSupplierExploreCard({
    required int totalSuppliers,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 148,
      child: Center(
        child: SizedBox(
          height: 158,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF5FBFD),
                      Color(0xFFEAF7FB),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFCFE7F1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D075C9B),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xFFD3EAF3)),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF087AC0),
                          size: 17,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$totalSuppliers suppliers',
                        style: const TextStyle(
                          color: Color(0xFF7693A4),
                          fontSize: 8.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Explore all',
                        style: TextStyle(
                          color: Color(0xFF123B55),
                          fontSize: 14.2,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Row(
                        children: [
                          Text(
                            'Browse market',
                            style: TextStyle(
                              color: Color(0xFF087AC0),
                              fontSize: 8.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF087AC0),
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget homeSupplierMessageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(
        right: 12,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isError
                ? const Color(
                    0xFFD32F2F,
                  )
                : const Color(
                    0xFF087AC0,
                  ),
            size: 34,
          ),
          const SizedBox(
            height: 9,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget todayOverview(
    BuildContext context,
  ) {
    final uid = currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: OverviewCountCard(
              title: 'Suppliers',
              icon: Icons.storefront,
              stream: FirebaseFirestore.instance
                  .collection(
                    'supplierProfiles',
                  )
                  .where(
                    'status',
                    isEqualTo: 'approved',
                  )
                  .snapshots(),
              countBuilder:
                  (
                    docs,
                  ) {
                    return docs.where(
                      (
                        doc,
                      ) {
                        final data = doc.data();

                        final status =
                            (data['status'] ??
                                    '')
                                .toString()
                                .toLowerCase();

                        final verificationStatus =
                            (data['verificationStatus'] ??
                                    '')
                                .toString()
                                .toLowerCase();

                        return status ==
                                'approved' ||
                            verificationStatus ==
                                'approved';
                      },
                    ).length;
                  },
            ),
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: OverviewCountCard(
              title: 'Fish Posts',
              icon: Icons.set_meal,
              stream: FirebaseFirestore.instance
                  .collection(
                    'fishStocks',
                  )
                  .snapshots(),
              countBuilder:
                  (
                    docs,
                  ) {
                    return docs.where(
                      (
                        doc,
                      ) {
                        final data = doc.data();

                        final status =
                            (data['status'] ??
                                    'available')
                                .toString()
                                .toLowerCase();

                        final quantity =
                            double.tryParse(
                              (data['quantity'] ??
                                      0)
                                  .toString(),
                            ) ??
                            0;

                        return status !=
                                'unavailable' &&
                            quantity >
                                0;
                      },
                    ).length;
                  },
            ),
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child:
                uid ==
                    null
                ? const StaticOverviewCard(
                    title: 'Active Orders',
                    value: '0',
                    icon: Icons.receipt_long,
                  )
                : OverviewCountCard(
                    title: 'Active Orders',
                    icon: Icons.receipt_long,
                    stream: FirebaseFirestore.instance
                        .collection(
                          'orders',
                        )
                        .where(
                          'vendorId',
                          isEqualTo: uid,
                        )
                        .snapshots(),
                    countBuilder:
                        (
                          docs,
                        ) {
                          return docs.where(
                            (
                              doc,
                            ) {
                              final status =
                                  (doc.data()['orderStatus'] ??
                                          '')
                                      .toString()
                                      .toLowerCase();

                              return status ==
                                      'pending' ||
                                  status ==
                                      'accepted';
                            },
                          ).length;
                        },
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
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: _HomeScrollChrome(
        statusBarHeight: statusBarHeight,
        onSearchTap: () => openHomeSearch(context),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  HomeHeader(
                    onLogout: () => logout(context),
                    onSearchTap: () => openHomeSearch(context),
                    onProfileTap: () => openMe(context),
                  ),
                  const SizedBox(height: 10),
                  TopSellingFishStrip(
                    onProductTap: (
                      supplier,
                      product,
                      stockId,
                      supplierId,
                    ) {
                      openProductDetails(
                        context,
                        supplier,
                        product,
                        stockId: stockId,
                        supplierId: supplierId,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HomeSectionHeader(
                      title: 'Recommended Suppliers',
                      icon: Icons.verified,
                      actionLabel: 'View all',
                      onViewAll: () => openBrowseSuppliers(context),
                    ),
                  ),
                  const SizedBox(height: 9),
                  recommendedSuppliersList(context),
                  const SizedBox(height: 14),
                  RecentFishPosts(
                    onViewAll: () => openLatestFishStocks(context),
                    onProductTap: (
                      supplier,
                      product,
                      stockId,
                      supplierId,
                    ) {
                      openProductDetails(
                        context,
                        supplier,
                        product,
                        stockId: stockId,
                        supplierId: supplierId,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            HomeBottomNavWithBadge(
              userId: currentUser?.uid,
              onMyOrders: () => openMyOrders(context),
              onAnalytics: () => openAnalytics(context),
              onMe: () => openMe(context),
            ),
          ],
        ),
      ),
    );
  }
}


class _HomeScrollChrome extends StatefulWidget {
  const _HomeScrollChrome({
    required this.statusBarHeight,
    required this.onSearchTap,
    required this.child,
  });

  final double statusBarHeight;
  final VoidCallback onSearchTap;
  final Widget child;

  @override
  State<_HomeScrollChrome> createState() => _HomeScrollChromeState();
}

class _HomeScrollChromeState extends State<_HomeScrollChrome> {
  bool compactHeaderVisible = false;

  bool handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final shouldShow = notification.metrics.pixels > 92;

    if (shouldShow != compactHeaderVisible) {
      setState(() {
        compactHeaderVisible = shouldShow;
      });
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: handleScroll,
          child: widget.child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.statusBarHeight,
          child: const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Color(0xFF06355F),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0xFF06355F),
              ),
            ),
          ),
        ),
        Positioned(
          top: widget.statusBarHeight,
          left: 0,
          right: 0,
          height: 46,
          child: IgnorePointer(
            ignoring: !compactHeaderVisible,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              offset: compactHeaderVisible
                  ? Offset.zero
                  : const Offset(0, -0.35),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: compactHeaderVisible ? 1 : 0,
                child: Material(
                  color: const Color(0xFF064A78),
                  elevation: 2,
                  shadowColor: const Color(0x33001C31),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: const Color(0x33FFFFFF),
                            ),
                          ),
                          child: const Icon(
                            Icons.set_meal_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ISDALINK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Fish supply network',
                                style: TextStyle(
                                  color: Color(0xFFCFE9F6),
                                  fontSize: 7.8,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: widget.onSearchTap,
                            borderRadius: BorderRadius.circular(10),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _HomeSupplierSnappingCarousel extends StatelessWidget {
  const _HomeSupplierSnappingCarousel({
    required this.children,
    required this.itemExtent,
  });

  final List<Widget> children;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 16),
      physics: HomeItemSnapScrollPhysics(
        parent: const BouncingScrollPhysics(),
        itemExtent: itemExtent,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }
}

class OverviewCountCard
    extends
        StatelessWidget {
  const OverviewCountCard({
    super.key,
    required this.title,
    required this.icon,
    required this.stream,
    required this.countBuilder,
  });

  final String title;
  final IconData icon;
  final Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  stream;
  final int Function(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    docs,
  )
  countBuilder;

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<
      QuerySnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: stream,
      builder:
          (
            context,
            snapshot,
          ) {
            final value = snapshot.hasData
                ? '${countBuilder(snapshot.data!.docs)}'
                : '--';

            return StaticOverviewCard(
              title: title,
              value: value,
              icon: icon,
            );
          },
    );
  }
}

class StaticOverviewCard
    extends
        StatelessWidget {
  const StaticOverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFE0F1F7,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0D000000,
            ),
            blurRadius: 10,
            offset: Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(
              0xFF087AC0,
            ),
            size: 19,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 9.2,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeBottomNavWithBadge
    extends
        StatelessWidget {
  const HomeBottomNavWithBadge({
    super.key,
    required this.userId,
    required this.onMyOrders,
    required this.onAnalytics,
    required this.onMe,
  });

  final String? userId;
  final VoidCallback onMyOrders;
  final VoidCallback onAnalytics;
  final VoidCallback onMe;

  int activeVendorOrderCount(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    return documents.where(
      (
        document,
      ) {
        final status =
            (document.data()['orderStatus'] ??
                    '')
                .toString()
                .toLowerCase();

        return status ==
                'pending' ||
            status ==
                'accepted';
      },
    ).length;
  }

  int pendingSupplierOrderCount(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    return documents.where(
      (
        document,
      ) {
        final status =
            (document.data()['orderStatus'] ??
                    '')
                .toString()
                .toLowerCase();

        return status ==
            'pending';
      },
    ).length;
  }

  int unreadSupplierStockNotificationCount(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    return documents.where(
      (
        document,
      ) {
        final data = document.data();
        final type =
            (data['type'] ??
                    '')
                .toString()
                .toLowerCase();

        return type ==
                'stock_alert' &&
            data['isRead'] !=
                true;
      },
    ).length;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (userId ==
            null ||
        userId!.trim().isEmpty) {
      return HomeBottomNav(
        activeOrderCount: 0,
        supplierNotificationCount: 0,
        onMyOrders: onMyOrders,
        onAnalytics: onAnalytics,
        onMe: onMe,
      );
    }

    return StreamBuilder<
      QuerySnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: FirebaseFirestore.instance
          .collection(
            'orders',
          )
          .where(
            'vendorId',
            isEqualTo: userId,
          )
          .snapshots(),
      builder:
          (
            context,
            vendorSnapshot,
          ) {
            final vendorCount = vendorSnapshot.hasData
                ? activeVendorOrderCount(
                    vendorSnapshot.data!.docs,
                  )
                : 0;

            return StreamBuilder<
              QuerySnapshot<
                Map<
                  String,
                  dynamic
                >
              >
            >(
              stream: FirebaseFirestore.instance
                  .collection(
                    'orders',
                  )
                  .where(
                    'supplierId',
                    isEqualTo: userId,
                  )
                  .snapshots(),
              builder:
                  (
                    context,
                    supplierSnapshot,
                  ) {
                    final supplierPendingCount = supplierSnapshot.hasData
                        ? pendingSupplierOrderCount(
                            supplierSnapshot.data!.docs,
                          )
                        : 0;

                    return StreamBuilder<
                      QuerySnapshot<
                        Map<
                          String,
                          dynamic
                        >
                      >
                    >(
                      stream: FirebaseFirestore.instance
                          .collection(
                            'notifications',
                          )
                          .where(
                            'supplierId',
                            isEqualTo: userId,
                          )
                          .snapshots(),
                      builder:
                          (
                            context,
                            notificationSnapshot,
                          ) {
                            final stockNotificationCount = notificationSnapshot.hasData
                                ? unreadSupplierStockNotificationCount(
                                    notificationSnapshot.data!.docs,
                                  )
                                : 0;

                            return HomeBottomNav(
                              activeOrderCount: vendorCount,
                              supplierNotificationCount:
                                  supplierPendingCount +
                                  stockNotificationCount,
                              onMyOrders: onMyOrders,
                              onAnalytics: onAnalytics,
                              onMe: onMe,
                            );
                          },
                    );
                  },
            );
          },
    );
  }
}

enum HomeSearchFilter {
  all,
  fish,
  suppliers,
  locations,
}

class HomeSearchSheet
    extends
        StatefulWidget {
  const HomeSearchSheet({
    super.key,
    required this.onSupplierTap,
    required this.onProductTap,
  });

  final void Function(
    Supplier supplier,
    String supplierId,
  )
  onSupplierTap;

  final void Function(
    Supplier supplier,
    FishProduct product,
    String stockId,
    String supplierId,
  )
  onProductTap;

  @override
  State<
    HomeSearchSheet
  >
  createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState
    extends
        State<
          HomeSearchSheet
        > {
  final searchController = TextEditingController();
  final HomeStockService stockService = const HomeStockService();
  final SupplierBrowseService supplierService = const SupplierBrowseService();
  final FavoriteSupplierService favoriteService = FavoriteSupplierService();

  late final SearchHistoryService searchHistoryService;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> fishStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> supplierStream;

  String query = '';
  HomeSearchFilter selectedFilter = HomeSearchFilter.all;
  List<String> recentSearches = const <String>[];

  String get normalizedQuery => query.trim().toLowerCase();

  String get searchHint {
    return switch (selectedFilter) {
      HomeSearchFilter.fish => 'Search fish name or category',
      HomeSearchFilter.suppliers => 'Search supplier or store name',
      HomeSearchFilter.locations => 'Search city, municipality, or province',
      HomeSearchFilter.all => 'Search fish, supplier, or location',
    };
  }

  @override
  void initState() {
    super.initState();
    searchHistoryService = SearchHistoryService(
      userId: FirebaseAuth.instance.currentUser?.uid,
    );
    fishStream = FirebaseFirestore.instance.collection('fishStocks').snapshots();
    supplierStream = supplierService.suppliersStream;
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final items = await searchHistoryService.load();

    if (!mounted) {
      return;
    }

    setState(() {
      recentSearches = items;
    });
  }

  void _recordSearch(String value) {
    final clean = value.trim();

    if (clean.length < 2) {
      return;
    }

    searchHistoryService.add(clean).then((items) {
      if (!mounted) {
        return;
      }

      setState(() {
        recentSearches = items;
      });
    });
  }

  void _removeRecentSearch(String value) {
    searchHistoryService.remove(value).then((items) {
      if (!mounted) {
        return;
      }

      setState(() {
        recentSearches = items;
      });
    });
  }

  void _clearRecentSearches() {
    searchHistoryService.clear().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        recentSearches = const <String>[];
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String cleanText({
    required String value,
    required String fallback,
  }) {
    final text = value.trim();

    if (text.isEmpty) {
      return fallback;
    }

    final lowerText = text.toLowerCase();

    if (lowerText ==
            'test' ||
        lowerText ==
            'testing' ||
        lowerText ==
            'asdw' ||
        lowerText ==
            'asdf') {
      return fallback;
    }

    return text;
  }

  bool matchesAny(
    Iterable<
      String
    >
    values,
  ) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return values.any(
      (
        value,
      ) => value.trim().toLowerCase().contains(
        normalizedQuery,
      ),
    );
  }

  List<String> fishSearchValues(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final productName = (data['productName'] ?? '').toString();
    final category = (data['category'] ?? '').toString();
    final supplierName = (data['supplierName'] ?? '').toString();
    final location = (data['supplierLocation'] ??
            data['storeLocation'] ??
            data['location'] ??
            '')
        .toString();
    final quantityUnit = (data['quantityUnit'] ?? '').toString();
    final priceUnit = (data['priceUnit'] ?? '').toString();
    final stockStatus = (data['stockStatus'] ?? '').toString();

    return switch (selectedFilter) {
      HomeSearchFilter.suppliers => const <String>[],
      HomeSearchFilter.locations => <String>[
          location,
        ],
      HomeSearchFilter.fish => <String>[
          productName,
          category,
          quantityUnit,
          priceUnit,
          stockStatus,
        ],
      HomeSearchFilter.all => <String>[
          productName,
          category,
          quantityUnit,
          priceUnit,
          stockStatus,
          supplierName,
          location,
        ],
    };
  }

  List<String> supplierSearchValues(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final supplier = supplierService.supplierFromProfile(data);
    final serviceArea = supplierService.firstAvailableText(
      data,
      const [
        'serviceArea',
        'primaryMarketArea',
      ],
    );
    final ownerName = supplierService.firstAvailableText(
      data,
      const [
        'ownerName',
        'fullName',
      ],
    );

    return switch (selectedFilter) {
      HomeSearchFilter.fish => const <String>[],
      HomeSearchFilter.locations => <String>[
          supplier.location,
          serviceArea,
        ],
      HomeSearchFilter.suppliers => <String>[
          supplier.name,
          supplier.location,
          serviceArea,
          ownerName,
          supplier.description,
        ],
      HomeSearchFilter.all => <String>[
          supplier.name,
          supplier.location,
          serviceArea,
          ownerName,
          supplier.description,
          'verified supplier',
          'cod',
          'cash on delivery',
        ],
    };
  }

  bool fishMatches(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (!stockService.isAvailableStock(document)) {
      return false;
    }

    final values = fishSearchValues(document);
    return values.isNotEmpty && matchesAny(values);
  }

  bool supplierMatches(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final values = supplierSearchValues(document);
    return values.isNotEmpty && matchesAny(values);
  }

  int relevanceScore(Iterable<String> values) {
    if (normalizedQuery.isEmpty) {
      return 0;
    }

    var bestScore = 3;

    for (final value in values) {
      final normalized = value.trim().toLowerCase();

      if (normalized.isEmpty) {
        continue;
      }

      if (normalized == normalizedQuery) {
        return 0;
      }

      if (normalized.startsWith(normalizedQuery)) {
        bestScore = bestScore > 1 ? 1 : bestScore;
        continue;
      }

      if (normalized.contains(normalizedQuery)) {
        bestScore = bestScore > 2 ? 2 : bestScore;
      }
    }

    return bestScore;
  }

  int compareFishDocuments(
    QueryDocumentSnapshot<Map<String, dynamic>> first,
    QueryDocumentSnapshot<Map<String, dynamic>> second,
  ) {
    if (normalizedQuery.isNotEmpty) {
      final scoreComparison = relevanceScore(fishSearchValues(first))
          .compareTo(relevanceScore(fishSearchValues(second)));

      if (scoreComparison != 0) {
        return scoreComparison;
      }
    }

    final firstActivity = stockService.latestActivityAt(first.data());
    final secondActivity = stockService.latestActivityAt(second.data());

    if (firstActivity == null && secondActivity == null) {
      return 0;
    }

    if (firstActivity == null) {
      return 1;
    }

    if (secondActivity == null) {
      return -1;
    }

    return secondActivity.compareTo(firstActivity);
  }

  int compareSupplierDocuments(
    QueryDocumentSnapshot<Map<String, dynamic>> first,
    QueryDocumentSnapshot<Map<String, dynamic>> second,
  ) {
    if (normalizedQuery.isNotEmpty) {
      final scoreComparison = relevanceScore(supplierSearchValues(first))
          .compareTo(relevanceScore(supplierSearchValues(second)));

      if (scoreComparison != 0) {
        return scoreComparison;
      }
    }

    final firstSupplier = supplierService.supplierFromProfile(first.data());
    final secondSupplier = supplierService.supplierFromProfile(second.data());

    if (firstSupplier.isNewSupplier != secondSupplier.isNewSupplier) {
      return firstSupplier.isNewSupplier ? -1 : 1;
    }

    final ratingComparison = secondSupplier.rating.compareTo(firstSupplier.rating);

    if (ratingComparison != 0) {
      return ratingComparison;
    }

    final reviewComparison = secondSupplier.reviews.compareTo(firstSupplier.reviews);

    if (reviewComparison != 0) {
      return reviewComparison;
    }

    return firstSupplier.name
        .toLowerCase()
        .compareTo(secondSupplier.name.toLowerCase());
  }

  String formatNumber(
    double value,
  ) {
    if (value %
            1 ==
        0) {
      return value.toStringAsFixed(
        0,
      );
    }

    return value.toStringAsFixed(
      1,
    );
  }

  String cleanPriceUnit(
    String value,
    String fallback,
  ) {
    final unit = value.trim();

    if (unit.isEmpty) {
      return fallback;
    }

    final lower = unit.toLowerCase();

    if (lower.startsWith(
      'per ',
    )) {
      return unit.substring(
        4,
      );
    }

    if (unit.startsWith(
      '/',
    )) {
      return unit
          .substring(
            1,
          )
          .trim();
    }

    return unit;
  }

  String fishLocation(
    Map<
      String,
      dynamic
    >
    data,
    Supplier supplier,
  ) {
    final candidates =
        <
          dynamic
        >[
          data['supplierLocation'],
          data['storeLocation'],
          data['location'],
        ];

    for (final candidate in candidates) {
      final value =
          candidate?.toString().trim() ??
          '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return cleanText(
      value: supplier.location,
      fallback: 'Caraga Region',
    );
  }

  Map<
    String,
    int
  >
  availableListingCounts(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    fishDocuments,
  ) {
    final counts =
        <
          String,
          int
        >{};

    for (final document in fishDocuments) {
      if (!stockService.isAvailableStock(
        document,
      )) {
        continue;
      }

      final supplierId =
          (document.data()['supplierId'] ??
                  '')
              .toString()
              .trim();

      if (supplierId.isEmpty) {
        continue;
      }

      counts[supplierId] =
          (counts[supplierId] ??
              0) +
          1;
    }

    return counts;
  }

  String compactLocationSuggestion(String value) {
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length >= 3) {
      return parts[parts.length - 3];
    }

    return parts.first;
  }

  List<String> suggestedSearchTerms({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> fishDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> supplierDocuments,
  }) {
    final terms = <String>[];

    void addTerm(String value) {
      final clean = value.trim();

      if (clean.isEmpty ||
          terms.any((item) => item.toLowerCase() == clean.toLowerCase())) {
        return;
      }

      terms.add(clean);
    }

    final approvedSuppliers = supplierService.approvedSuppliers(supplierDocuments);
    final approvedSupplierIds =
        approvedSuppliers.map((document) => document.id).toSet();
    final availableFish = fishDocuments.where((document) {
      final supplierId =
          (document.data()['supplierId'] ?? '').toString().trim();

      return supplierId.isNotEmpty &&
          approvedSupplierIds.contains(supplierId) &&
          stockService.isAvailableStock(document);
    }).toList()
      ..sort(compareFishDocuments);

    if (selectedFilter == HomeSearchFilter.fish ||
        selectedFilter == HomeSearchFilter.all) {
      for (final document in availableFish) {
        addTerm((document.data()['productName'] ?? '').toString());

        if (terms.length >= (selectedFilter == HomeSearchFilter.all ? 2 : 5)) {
          break;
        }
      }
    }

    if (selectedFilter == HomeSearchFilter.suppliers ||
        selectedFilter == HomeSearchFilter.all) {
      final rankedSuppliers = approvedSuppliers.toList()
        ..sort(compareSupplierDocuments);

      for (final document in rankedSuppliers) {
        addTerm(supplierService.supplierFromProfile(document.data()).name);

        if (terms.length >= (selectedFilter == HomeSearchFilter.all ? 4 : 5)) {
          break;
        }
      }
    }

    if (selectedFilter == HomeSearchFilter.locations ||
        selectedFilter == HomeSearchFilter.all) {
      for (final document in approvedSuppliers) {
        final data = document.data();
        final serviceArea = supplierService.firstAvailableText(
          data,
          const [
            'serviceArea',
            'primaryMarketArea',
          ],
        );
        final location = serviceArea.isNotEmpty
            ? serviceArea
            : supplierService.supplierFromProfile(data).location;
        addTerm(compactLocationSuggestion(location));

        if (terms.length >= 5) {
          break;
        }
      }
    }

    return terms.take(5).toList();
  }

  List<String> matchingSearchSuggestions({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> fishDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> supplierDocuments,
  }) {
    final normalized = normalizedQuery;

    if (normalized.isEmpty) {
      return const <String>[];
    }

    final terms = <String>[];

    void addTerm(String value) {
      final clean = value.trim();

      if (clean.isEmpty ||
          clean.toLowerCase() == normalized ||
          terms.any((item) => item.toLowerCase() == clean.toLowerCase())) {
        return;
      }

      terms.add(clean);
    }

    final approvedSuppliers = supplierService.approvedSuppliers(supplierDocuments);
    final approvedSupplierIds =
        approvedSuppliers.map((document) => document.id).toSet();
    final availableFish = fishDocuments.where((document) {
      final supplierId =
          (document.data()['supplierId'] ?? '').toString().trim();

      return supplierId.isNotEmpty &&
          approvedSupplierIds.contains(supplierId) &&
          stockService.isAvailableStock(document);
    }).toList()
      ..sort(compareFishDocuments);

    if (selectedFilter == HomeSearchFilter.fish ||
        selectedFilter == HomeSearchFilter.all) {
      for (final document in availableFish) {
        addTerm((document.data()['productName'] ?? '').toString());
      }
    }

    if (selectedFilter == HomeSearchFilter.suppliers ||
        selectedFilter == HomeSearchFilter.all) {
      for (final document in approvedSuppliers) {
        addTerm(supplierService.supplierFromProfile(document.data()).name);
      }
    }

    if (selectedFilter == HomeSearchFilter.locations ||
        selectedFilter == HomeSearchFilter.all) {
      for (final document in approvedSuppliers) {
        final data = document.data();
        final serviceArea = supplierService.firstAvailableText(
          data,
          const [
            'serviceArea',
            'primaryMarketArea',
          ],
        );
        final location = serviceArea.isNotEmpty
            ? serviceArea
            : supplierService.supplierFromProfile(data).location;

        addTerm(compactLocationSuggestion(location));
      }
    }

    final matches = terms.where((term) {
      return term.toLowerCase().contains(normalized);
    }).toList();

    matches.sort((first, second) {
      final firstStarts = first.toLowerCase().startsWith(normalized);
      final secondStarts = second.toLowerCase().startsWith(normalized);

      if (firstStarts != secondStarts) {
        return firstStarts ? -1 : 1;
      }

      return first.toLowerCase().compareTo(second.toLowerCase());
    });

    return matches.take(5).toList();
  }

  void applySearchSuggestion(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      return;
    }

    searchController.text = clean;
    searchController.selection = TextSelection.collapsed(offset: clean.length);

    setState(() {
      query = clean;
    });

    _recordSearch(clean);
  }

  Future<void> toggleFavoriteSupplier({
    required String supplierId,
    required bool currentlyFavorite,
  }) async {
    try {
      await favoriteService.toggleFavorite(
        supplierId: supplierId,
        currentlyFavorite: currentlyFavorite,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = AppErrorMessage.from(
        error,
        fallback: 'Favorite suppliers could not be updated right now. Please try again.',
        allowBusinessMessage: true,
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget resultSummary({
    required int resultCount,
  }) {
    final searchText = query.trim();

    String label;

    if (searchText.isNotEmpty) {
      label = '$resultCount match${resultCount == 1 ? '' : 'es'} for "$searchText"';
    } else {
      label = switch (selectedFilter) {
        HomeSearchFilter.fish => '$resultCount available fish listing${resultCount == 1 ? '' : 's'}',
        HomeSearchFilter.suppliers => '$resultCount verified supplier${resultCount == 1 ? '' : 's'}',
        HomeSearchFilter.locations => 'Search by location',
        HomeSearchFilter.all => 'Live marketplace results',
      };
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(
                  0xFF657C8E,
                ),
                fontSize: 10.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (searchText.isNotEmpty)
            TextButton(
              onPressed: () {
                searchController.clear();

                setState(
                  () {
                    query = '';
                  },
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                  0xFF087AC0,
                ),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildResults({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> fishDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> supplierDocuments,
    required ScrollController scrollController,
  }) {
    final approvedSuppliers = supplierService.approvedSuppliers(
      supplierDocuments,
    );
    final approvedSupplierIds = approvedSuppliers.map((document) => document.id).toSet();

    final fishMatchesList = fishDocuments.where((document) {
      final supplierId = (document.data()['supplierId'] ?? '').toString().trim();

      return supplierId.isNotEmpty &&
          approvedSupplierIds.contains(supplierId) &&
          fishMatches(document);
    }).toList()
      ..sort(compareFishDocuments);

    final supplierMatchesList = approvedSuppliers.where(supplierMatches).toList()
      ..sort(compareSupplierDocuments);

    final suggestedTerms = suggestedSearchTerms(
      fishDocuments: fishDocuments,
      supplierDocuments: supplierDocuments,
    );
    final matchingTerms = matchingSearchSuggestions(
      fishDocuments: fishDocuments,
      supplierDocuments: supplierDocuments,
    );

    if (selectedFilter == HomeSearchFilter.locations &&
        normalizedQuery.isEmpty) {
      return HomeSearchLocationPrompt(
        scrollController: scrollController,
        suggestions: suggestedTerms,
        onSuggestionTap: applySearchSuggestion,
      );
    }

    final totalResultCount = fishMatchesList.length + supplierMatchesList.length;

    if (totalResultCount == 0) {
      return HomeSearchEmptyState(
        query: query,
        filter: selectedFilter,
        scrollController: scrollController,
        suggestions: matchingTerms.isNotEmpty ? matchingTerms : suggestedTerms,
        onSuggestionTap: applySearchSuggestion,
        onClear: () {
          searchController.clear();

          setState(() {
            query = '';
            selectedFilter = HomeSearchFilter.all;
          });
        },
      );
    }

    final listingCounts = availableListingCounts(
      fishDocuments,
    );

    final isBrowsing = normalizedQuery.isEmpty;

    final visibleFish = fishMatchesList.take(
      isBrowsing && selectedFilter == HomeSearchFilter.all ? 4 : 12,
    );

    final visibleSuppliers = supplierMatchesList.take(
      isBrowsing && selectedFilter == HomeSearchFilter.all ? 4 : 12,
    );

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ListView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        28,
      ),
      children: [
        if (isBrowsing &&
            selectedFilter == HomeSearchFilter.all &&
            recentSearches.isNotEmpty) ...[
          HomeSearchRecentSearches(
            terms: recentSearches,
            onTap: applySearchSuggestion,
            onRemove: _removeRecentSearch,
            onClearAll: _clearRecentSearches,
          ),
          const SizedBox(height: 12),
        ],
        if (isBrowsing && suggestedTerms.isNotEmpty) ...[
          HomeSearchSuggestedSearches(
            terms: suggestedTerms,
            onTap: applySearchSuggestion,
          ),
          const SizedBox(height: 14),
        ],
        if (!isBrowsing && matchingTerms.isNotEmpty) ...[
          HomeSearchSuggestedSearches(
            title: 'Suggested matches',
            trailingLabel: 'Tap to search',
            icon: Icons.auto_awesome_rounded,
            terms: matchingTerms,
            onTap: applySearchSuggestion,
          ),
          const SizedBox(height: 14),
        ],
        resultSummary(
          resultCount: totalResultCount,
        ),
        if (visibleFish.isNotEmpty) ...[
          HomeSearchSectionLabel(
            icon: Icons.set_meal_outlined,
            label: selectedFilter == HomeSearchFilter.locations
                ? 'Fish in this location'
                : isBrowsing
                    ? 'Fish Available Now'
                    : 'Matching Fish Stocks',
            count: fishMatchesList.length,
          ),
          const SizedBox(
            height: 10,
          ),
          ...visibleFish.map(
            (document) {
              final data = document.data();
              final product = stockService.fishProductFromFirestore(
                data,
              );
              final supplier = stockService.supplierForStock(
                data,
              );
              final supplierId = (data['supplierId'] ?? '').toString().trim();

              if (supplier == null || supplierId.isEmpty) {
                return const SizedBox.shrink();
              }

              final ownerListing = currentUid.isNotEmpty && supplierId == currentUid;
              final arrivalBadge = stockService.arrivalBadge(data);
              final activityLabel = stockService.activityLabel(data);

              return HomeSearchFishCard(
                imageUrl: product.imageUrl,
                supplierImageUrl: supplier.profileImageUrl,
                productName: cleanText(
                  value: product.name,
                  fallback: 'Fresh Fish Stock',
                ),
                supplierName: cleanText(
                  value: supplier.name,
                  fallback: 'Verified Supplier',
                ),
                location: fishLocation(
                  data,
                  supplier,
                ),
                priceText:
                    '₱${formatNumber(product.price)} / ${cleanPriceUnit(product.priceUnit, product.quantityUnit)}',
                stockText:
                    '${formatNumber(product.availableQuantity)} ${product.quantityUnit} available',
                stockStatus: product.stockStatus,
                stockColor: product.stockColor,
                arrivalBadge: arrivalBadge,
                activityLabel: activityLabel,
                ownerListing: ownerListing,
                onTap: () {
                  _recordSearch(query);
                  Navigator.pop(
                    context,
                  );

                  Future.microtask(
                    () => widget.onProductTap(
                      supplier,
                      product,
                      document.id,
                      supplierId,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(
            height: 8,
          ),
        ],
        if (visibleSuppliers.isNotEmpty) ...[
          HomeSearchSectionLabel(
            icon: Icons.verified_outlined,
            label: selectedFilter == HomeSearchFilter.locations
                ? 'Suppliers in this location'
                : 'Verified Suppliers',
            count: supplierMatchesList.length,
          ),
          const SizedBox(
            height: 10,
          ),
          ...visibleSuppliers.map(
            (document) {
              final supplier = supplierService.supplierFromProfile(
                document.data(),
              );

              final ownerStore = currentUid.isNotEmpty && document.id == currentUid;

              return StreamBuilder<bool>(
                stream: favoriteService.isFavoriteStream(document.id),
                initialData: false,
                builder: (context, favoriteSnapshot) {
                  final isFavorite = favoriteSnapshot.data ?? false;

                  return HomeSearchSupplierCard(
                    imageUrl: supplier.profileImageUrl,
                    supplierName: cleanText(
                      value: supplier.name,
                      fallback: 'Verified Supplier',
                    ),
                    location: cleanText(
                      value: supplier.location,
                      fallback: 'Caraga Region',
                    ),
                    rating: supplier.rating,
                    reviews: supplier.reviews,
                    activeListings: listingCounts[document.id] ?? 0,
                    ownerStore: ownerStore,
                    isFavorite: isFavorite,
                    favoriteBusy:
                        favoriteSnapshot.connectionState == ConnectionState.waiting &&
                        !favoriteSnapshot.hasData,
                    onFavoriteTap: ownerStore
                        ? null
                        : () => toggleFavoriteSupplier(
                              supplierId: document.id,
                              currentlyFavorite: isFavorite,
                            ),
                    onTap: () {
                      _recordSearch(query);
                      Navigator.pop(
                        context,
                      );

                      Future.microtask(
                        () => widget.onSupplierTap(
                          supplier,
                          document.id,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
        if (isBrowsing &&
            selectedFilter == HomeSearchFilter.all &&
            (fishMatchesList.length > 4 || supplierMatchesList.length > 4)) ...[
          const SizedBox(
            height: 4,
          ),
          const HomeSearchBrowseHint(),
        ],
      ],
    );
  }

  Widget filterBar() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          HomeSearchFilterChip(
            selected:
                selectedFilter ==
                HomeSearchFilter.all,
            icon: Icons.grid_view_rounded,
            label: 'All',
            onTap: () {
              setState(
                () {
                  selectedFilter = HomeSearchFilter.all;
                },
              );
            },
          ),
          const SizedBox(
            width: 7,
          ),
          HomeSearchFilterChip(
            selected:
                selectedFilter ==
                HomeSearchFilter.fish,
            icon: Icons.set_meal_outlined,
            label: 'Fish',
            onTap: () {
              setState(
                () {
                  selectedFilter = HomeSearchFilter.fish;
                },
              );
            },
          ),
          const SizedBox(
            width: 7,
          ),
          HomeSearchFilterChip(
            selected:
                selectedFilter ==
                HomeSearchFilter.suppliers,
            icon: Icons.storefront_outlined,
            label: 'Suppliers',
            onTap: () {
              setState(
                () {
                  selectedFilter = HomeSearchFilter.suppliers;
                },
              );
            },
          ),
          const SizedBox(
            width: 7,
          ),
          HomeSearchFilterChip(
            selected:
                selectedFilter ==
                HomeSearchFilter.locations,
            icon: Icons.location_on_outlined,
            label: 'Locations',
            onTap: () {
              setState(
                () {
                  selectedFilter = HomeSearchFilter.locations;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.91,
      minChildSize: 0.60,
      maxChildSize: 0.96,
      builder: (
        context,
        scrollController,
      ) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFF5FAFD),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x2600152A),
                blurRadius: 28,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF9FDFF),
                      Color(0xFFEEF9FD),
                      Color(0xFFF4FAFF),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 9),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC6D9E5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF0875D1),
                                      Color(0xFF0CB6CF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x240875D1),
                                      blurRadius: 12,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.travel_explore_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 11),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Explore IsdaLink Market',
                                      style: TextStyle(
                                        color: Color(0xFF102C44),
                                        fontSize: 18.8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.25,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Discover fresh fish and verified suppliers across Caraga.',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF6F8597),
                                        fontSize: 10.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: const Color(0xFFE8F2F7),
                                borderRadius: BorderRadius.circular(13),
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(13),
                                  child: const SizedBox(
                                    width: 39,
                                    height: 39,
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF52677A),
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1000152A),
                                  blurRadius: 12,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                _recordSearch(value);
                                FocusScope.of(context).unfocus();
                              },
                              onChanged: (value) {
                                setState(() {
                                  query = value;
                                });
                              },
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: searchHint,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9AAEBC),
                                  fontSize: 11.7,
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 2),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF087AC0),
                                    size: 21,
                                  ),
                                ),
                                suffixIcon: query.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          searchController.clear();

                                          setState(() {
                                            query = '';
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          color: Color(0xFF9AAEBC),
                                          size: 18,
                                        ),
                                      ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDCEAF2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDCEAF2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF087AC0),
                                    width: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          filterBar(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2EEF4),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: fishStream,
                  builder: (context, fishSnapshot) {
                    if (fishSnapshot.hasError) {
                      return HomeSearchErrorState(
                        scrollController: scrollController,
                        error: fishSnapshot.error!,
                      );
                    }

                    if (!fishSnapshot.hasData) {
                      return const HomeSearchLoading();
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: supplierStream,
                      builder: (context, supplierSnapshot) {
                        if (supplierSnapshot.hasError) {
                          return HomeSearchErrorState(
                            scrollController: scrollController,
                            error: supplierSnapshot.error!,
                          );
                        }

                        if (!supplierSnapshot.hasData) {
                          return const HomeSearchLoading();
                        }

                        return buildResults(
                          fishDocuments: fishSnapshot.data!.docs,
                          supplierDocuments: supplierSnapshot.data!.docs,
                          scrollController: scrollController,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeSearchFilterChip
    extends
        StatelessWidget {
  const HomeSearchFilterChip({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: selected
          ? const Color(
              0xFF087AC0,
            )
          : Colors.white,
      borderRadius: BorderRadius.circular(
        13,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          13,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color: selected
                  ? const Color(
                      0xFF087AC0,
                    )
                  : const Color(
                      0xFFDDEAF2,
                    ),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(
                        0x20087AC0,
                      ),
                      blurRadius: 8,
                      offset: Offset(
                        0,
                        4,
                      ),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : const Color(
                        0xFF6D8495,
                      ),
                size: 15,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF52677A,
                        ),
                  fontSize: 9.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeSearchSectionLabel
    extends
        StatelessWidget {
  const HomeSearchSectionLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: const Color(
              0xFFE7F7FC,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(
              0xFF087AC0,
            ),
            size: 16,
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(
              0xFFEAF2F7,
            ),
            borderRadius: BorderRadius.circular(
              99,
            ),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(
                0xFF657C8E,
              ),
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}


class HomeSearchRecentSearches extends StatelessWidget {
  const HomeSearchRecentSearches({
    super.key,
    required this.terms,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<String> terms;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0EBF1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0900152A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: Color(0xFF5F7B8E),
                size: 15,
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Recent searches',
                  style: TextStyle(
                    color: Color(0xFF405B6F),
                    fontSize: 9.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF087AC0),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 8.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: terms.map((term) {
              return Material(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(99),
                child: InkWell(
                  onTap: () => onTap(term),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 6, 6, 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFFDCE8EE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: Color(0xFF7891A2),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 132),
                          child: Text(
                            term,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF38566E),
                              fontSize: 8.6,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        InkWell(
                          onTap: () => onRemove(term),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              color: Color(0xFF9AAEBC),
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class HomeSearchSuggestedSearches extends StatelessWidget {
  const HomeSearchSuggestedSearches({
    super.key,
    this.title = 'Suggested searches',
    this.trailingLabel = 'Live marketplace',
    this.icon = Icons.auto_awesome_rounded,
    required this.terms,
    required this.onTap,
  });

  final String title;
  final String trailingLabel;
  final IconData icon;
  final List<String> terms;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF8FC),
            Color(0xFFF3FAFF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD7EBF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF087AC0),
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 9.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                trailingLabel,
                style: const TextStyle(
                  color: Color(0xFF91A5B4),
                  fontSize: 7.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: terms.map((term) {
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                child: InkWell(
                  onTap: () => onTap(term),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFFD9E9F1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7A95A7),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            term,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF38566E),
                              fontSize: 8.6,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class HomeSearchFishCard extends StatelessWidget {
  const HomeSearchFishCard({
    super.key,
    required this.imageUrl,
    required this.supplierImageUrl,
    required this.productName,
    required this.supplierName,
    required this.location,
    required this.priceText,
    required this.stockText,
    required this.stockStatus,
    required this.stockColor,
    required this.arrivalBadge,
    required this.activityLabel,
    required this.ownerListing,
    required this.onTap,
  });

  final String imageUrl;
  final String supplierImageUrl;
  final String productName;
  final String supplierName;
  final String location;
  final String priceText;
  final String stockText;
  final String stockStatus;
  final Color stockColor;
  final String arrivalBadge;
  final String activityLabel;
  final bool ownerListing;
  final VoidCallback onTap;

  bool get hasImage {
    final value = imageUrl.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool get hasSupplierImage {
    final value = supplierImageUrl.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Widget supplierAvatar() {
    if (!hasSupplierImage) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FB),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD4EAF4),
          ),
        ),
        child: const Icon(
          Icons.storefront_rounded,
          color: Color(0xFF087AC0),
          size: 12,
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFBFE3F3),
        ),
      ),
      child: ClipOval(
        child: Image.network(
          supplierImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Container(
              color: const Color(0xFFEAF7FB),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF087AC0),
                size: 11,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget image() {
    if (!hasImage) {
      return const _SearchImagePlaceholder(
        icon: Icons.set_meal_rounded,
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const _SearchImagePlaceholder(
          icon: Icons.set_meal_rounded,
          loading: true,
        );
      },
      errorBuilder: (_, _, _) {
        return const _SearchImagePlaceholder(
          icon: Icons.set_meal_rounded,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE0EDF4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D00152A),
                  blurRadius: 11,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 82,
                      height: 88,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: image(),
                      ),
                    ),
                    if (arrivalBadge.trim().isNotEmpty)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: arrivalBadge.toUpperCase() == 'RESTOCKED'
                                ? const Color(0xFF0E9F7A)
                                : const Color(0xFF087AC0),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2200152A),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            arrivalBadge.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 6.8,
                              letterSpacing: 0.25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (ownerListing) ...[
                            const SizedBox(width: 5),
                            const _SearchOwnerBadge(label: 'YOURS'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          supplierAvatar(),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              supplierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF52677A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF8BA0B0),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8BA0B0),
                                fontSize: 8.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              priceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF087AC0),
                                fontSize: 12.6,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: stockColor.withAlpha(24),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              stockStatus,
                              style: TextStyle(
                                color: stockColor,
                                fontSize: 7.3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stockText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF71889A),
                                fontSize: 8.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (activityLabel.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              activityLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9AAEBC),
                                fontSize: 7.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA3B6C3),
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSearchSupplierCard extends StatelessWidget {
  const HomeSearchSupplierCard({
    super.key,
    required this.imageUrl,
    required this.supplierName,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.activeListings,
    required this.ownerStore,
    required this.isFavorite,
    required this.favoriteBusy,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final String imageUrl;
  final String supplierName;
  final String location;
  final double rating;
  final int reviews;
  final int activeListings;
  final bool ownerStore;
  final bool isFavorite;
  final bool favoriteBusy;
  final VoidCallback? onFavoriteTap;
  final VoidCallback onTap;

  bool get hasImage {
    final value = imageUrl.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Widget image() {
    if (!hasImage) {
      return const _SearchImagePlaceholder(
        icon: Icons.storefront_rounded,
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const _SearchImagePlaceholder(
          icon: Icons.storefront_rounded,
          loading: true,
        );
      },
      errorBuilder: (_, _, _) {
        return const _SearchImagePlaceholder(
          icon: Icons.storefront_rounded,
        );
      },
    );
  }

  String get ratingText {
    if (rating <= 0 || reviews <= 0) {
      return 'No reviews yet';
    }

    return '${rating.toStringAsFixed(1)} · $reviews review${reviews == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE0EDF4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D00152A),
                  blurRadius: 11,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0D8DD3),
                        Color(0xFF12B6D6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: image(),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 13.3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF0A8FCC),
                            size: 15,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF7B8FA3),
                              size: 12.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7B8FA3),
                                fontSize: 8.9,
                                height: 1.22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reviews > 0
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: const Color(0xFFFFB703),
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                ratingText,
                                style: const TextStyle(
                                  color: Color(0xFF52677A),
                                  fontSize: 8.7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
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
                              '$activeListings available',
                              style: const TextStyle(
                                color: Color(0xFF087AC0),
                                fontSize: 7.7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!ownerStore)
                      Material(
                        color: isFavorite
                            ? const Color(0xFFFFEEF1)
                            : const Color(0xFFF1F7FA),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: favoriteBusy ? null : onFavoriteTap,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: favoriteBusy
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                    ),
                                  )
                                : Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFavorite
                                        ? const Color(0xFFF0546D)
                                        : const Color(0xFF7F98AA),
                                    size: 18,
                                  ),
                          ),
                        ),
                      )
                    else
                      const _SearchOwnerBadge(label: 'YOUR STORE'),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ownerStore
                            ? const Color(0xFFE4F6EE)
                            : const Color(0xFFE8F8FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ownerStore ? 'Open' : 'View Store',
                        style: TextStyle(
                          color: ownerStore
                              ? const Color(0xFF147D64)
                              : const Color(0xFF087AC0),
                          fontSize: 7.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchImagePlaceholder
    extends
        StatelessWidget {
  const _SearchImagePlaceholder({
    required this.icon,
    this.loading = false,
  });

  final IconData icon;
  final bool loading;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(
        0xFFEAF6FA,
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : Icon(
              icon,
              color: const Color(
                0xFF087AC0,
              ),
              size: 27,
            ),
    );
  }
}

class _SearchOwnerBadge
    extends
        StatelessWidget {
  const _SearchOwnerBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFE4F6EE,
        ),
        borderRadius: BorderRadius.circular(
          99,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(
            0xFF147D64,
          ),
          fontSize: 6.8,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class HomeSearchBrowseHint
    extends
        StatelessWidget {
  const HomeSearchBrowseHint({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFEAF7FB,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: const Color(
            0xFFD7EBF3,
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Color(
              0xFF087AC0,
            ),
            size: 18,
          ),
          SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              'Type a fish, supplier, or location to narrow the marketplace results.',
              style: TextStyle(
                color: Color(
                  0xFF657C8E,
                ),
                fontSize: 9.4,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSearchLocationPrompt extends StatelessWidget {
  const HomeSearchLocationPrompt({
    super.key,
    required this.scrollController,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final ScrollController scrollController;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE6F7FC),
                Color(0xFFF3F9FF),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD2E9F3),
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.location_searching_rounded,
                color: Color(0xFF087AC0),
                size: 31,
              ),
              SizedBox(height: 9),
              Text(
                'Find fish near a market area',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Search a city, municipality, province, or supplier market area. IsdaLink will show matching fish stocks and verified suppliers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF657C8E),
                  fontSize: 10.1,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 13),
          HomeSearchSuggestedSearches(
            terms: suggestions,
            onTap: onSuggestionTap,
          ),
        ],
      ],
    );
  }
}

class HomeSearchEmptyState extends StatelessWidget {
  const HomeSearchEmptyState({
    super.key,
    required this.query,
    required this.filter,
    required this.scrollController,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onClear,
  });

  final String query;
  final HomeSearchFilter filter;
  final ScrollController scrollController;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onClear;

  String get message {
    final text = query.trim();

    if (text.isEmpty) {
      return switch (filter) {
        HomeSearchFilter.fish => 'There are no available fish listings right now.',
        HomeSearchFilter.suppliers => 'There are no verified suppliers available right now.',
        HomeSearchFilter.locations => 'Enter a location to search the marketplace.',
        HomeSearchFilter.all => 'There are no marketplace results available right now.',
      };
    }

    return 'No exact match for "$text". Try another fish name, supplier, or Caraga location.';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE0EDF4),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: Color(0xFF087AC0),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No exact matches',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF657C8E),
                  fontSize: 10.2,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (query.trim().isNotEmpty) ...[
                const SizedBox(height: 13),
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Reset Search',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF087AC0),
                    side: const BorderSide(
                      color: Color(0xFFB9DCEB),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 13),
          HomeSearchSuggestedSearches(
            terms: suggestions,
            onTap: onSuggestionTap,
          ),
        ],
      ],
    );
  }
}

class HomeSearchLoading
    extends
        StatelessWidget {
  const HomeSearchLoading({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: SizedBox(
        width: 23,
        height: 23,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
        ),
      ),
    );
  }
}

class HomeSearchErrorState extends StatelessWidget {
  const HomeSearchErrorState({
    super.key,
    required this.scrollController,
    required this.error,
  });

  final ScrollController scrollController;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = AppErrorMessage.from(
      error,
      fallback: 'Marketplace search could not be loaded right now. Please try again in a moment.',
    );

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 21, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFF0D6D4),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFD94A45),
                  size: 28,
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'Search is temporarily unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF657C8E),
                  fontSize: 10.2,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'IsdaLink will reconnect automatically when the service is available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF93A6B4),
                  fontSize: 8.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
