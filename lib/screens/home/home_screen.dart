import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'package:isdalink/screens/home/widgets/home_bottom_nav.dart';
import 'package:isdalink/screens/home/widgets/home_header.dart';
import 'package:isdalink/screens/home/widgets/home_section_header.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_posts.dart';
import 'package:isdalink/screens/home/widgets/recommended_supplier_card.dart';
import 'package:isdalink/screens/home/widgets/top_selling_fish_strip.dart';
import 'package:isdalink/screens/profile/me_screen.dart';
import 'package:isdalink/screens/vendor/browse_suppliers_screen.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  SupplierBrowseService get supplierService => const SupplierBrowseService();
  HomeStockService get stockService => const HomeStockService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> logout(
    BuildContext context,
  ) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  void openAnalytics(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnalyticsScreen(
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
        builder: (_) => const BrowseSuppliersScreen(),
      ),
    );
  }

  void openHomeSearch(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return HomeSearchSheet(
          onSupplierTap: (
            supplier,
            supplierId,
          ) {
            openSupplierDetails(
              context,
              supplier,
              supplierId: supplierId,
            );
          },
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
        builder: (_) => const MyOrdersScreen(),
      ),
    );
  }

  void openMe(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MeScreen(),
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
        builder: (_) => SupplierDetailsScreen(
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
        builder: (_) => ProductDetailsScreen(
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
      height: 212,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: supplierService.suppliersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.only(left: 14),
              scrollDirection: Axis.horizontal,
              children: [
                homeSupplierMessageCard(
                  icon: Icons.error_outline,
                  title: 'Unable to load suppliers',
                  subtitle: '${snapshot.error}',
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

          final approvedSuppliers = supplierService
              .approvedSuppliers(
                snapshot.data!.docs,
              )
              .take(5)
              .toList();

          if (approvedSuppliers.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(left: 14),
              scrollDirection: Axis.horizontal,
              children: [
                homeSupplierMessageCard(
                  icon: Icons.storefront_outlined,
                  title: 'No approved suppliers yet',
                  subtitle:
                      'Approved supplier profiles from Firebase will appear here.',
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.only(left: 14),
            scrollDirection: Axis.horizontal,
            children: approvedSuppliers.map(
              (document) {
                final data = document.data();
                final supplier = supplierService.supplierFromProfile(data);

                return RecommendedSupplierCard(
                  supplier: supplier,
                  onTap: () => openSupplierDetails(
                    context,
                    supplier,
                    supplierId: document.id,
                  ),
                );
              },
            ).toList(),
          );
        },
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
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isError ? const Color(0xFFD32F2F) : const Color(0xFF087AC0),
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: OverviewCountCard(
              title: 'Suppliers',
              icon: Icons.storefront,
              stream: FirebaseFirestore.instance
                  .collection('supplierProfiles')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              countBuilder: (docs) {
                return docs.where(
                  (doc) {
                    final data = doc.data();

                    final status =
                        (data['status'] ?? '').toString().toLowerCase();

                    final verificationStatus =
                        (data['verificationStatus'] ?? '')
                            .toString()
                            .toLowerCase();

                    return status == 'approved' ||
                        verificationStatus == 'approved';
                  },
                ).length;
              },
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: OverviewCountCard(
              title: 'Fish Posts',
              icon: Icons.set_meal,
              stream: FirebaseFirestore.instance.collection('fishStocks').snapshots(),
              countBuilder: (docs) {
                return docs.where(
                  (doc) {
                    final data = doc.data();

                    final status = (data['status'] ?? 'available')
                        .toString()
                        .toLowerCase();

                    final quantity = double.tryParse(
                          (data['quantity'] ?? 0).toString(),
                        ) ??
                        0;

                    return status != 'unavailable' && quantity > 0;
                  },
                ).length;
              },
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: uid == null
                ? const StaticOverviewCard(
                    title: 'Active Orders',
                    value: '0',
                    icon: Icons.receipt_long,
                  )
                : OverviewCountCard(
                    title: 'Active Orders',
                    icon: Icons.receipt_long,
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('vendorId', isEqualTo: uid)
                        .snapshots(),
                    countBuilder: (docs) {
                      return docs.where(
                        (doc) {
                          final status = (doc.data()['orderStatus'] ?? '')
                              .toString()
                              .toLowerCase();

                          return status == 'pending' || status == 'accepted';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HomeHeader(
                  onLogout: () => logout(context),
                  onSearchTap: () => openHomeSearch(context),
                  onProfileTap: () => openMe(context),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: HomeSectionHeader(
                    title: 'Recommended Suppliers',
                    icon: Icons.verified,
                    actionLabel: 'View all',
                    onViewAll: () => openBrowseSuppliers(context),
                  ),
                ),
                const SizedBox(height: 10),
                recommendedSuppliersList(context),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: HomeSectionHeader(
                    title: 'Fresh Fish Available',
                    icon: Icons.set_meal,
                  ),
                ),
                const SizedBox(height: 10),
                RecentFishPosts(
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
                const SizedBox(height: 18),
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
    );
  }
}

class OverviewCountCard extends StatelessWidget {
  const OverviewCountCard({
    super.key,
    required this.title,
    required this.icon,
    required this.stream,
    required this.countBuilder,
  });

  final String title;
  final IconData icon;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final int Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs)
      countBuilder;

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final value =
            snapshot.hasData ? '${countBuilder(snapshot.data!.docs)}' : '--';

        return StaticOverviewCard(
          title: title,
          value: value,
          icon: icon,
        );
      },
    );
  }
}

class StaticOverviewCard extends StatelessWidget {
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0F1F7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF087AC0),
            size: 19,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
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


class HomeBottomNavWithBadge extends StatelessWidget {
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
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where(
      (document) {
        final status = (document.data()['orderStatus'] ?? '')
            .toString()
            .toLowerCase();

        return status == 'pending' || status == 'accepted';
      },
    ).length;
  }

  int pendingSupplierOrderCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where(
      (document) {
        final status = (document.data()['orderStatus'] ?? '')
            .toString()
            .toLowerCase();

        return status == 'pending';
      },
    ).length;
  }

  int unreadSupplierStockNotificationCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where(
      (document) {
        final data = document.data();
        final type =
            (data['type'] ?? '').toString().toLowerCase();

        return type == 'stock_alert' &&
            data['isRead'] != true;
      },
    ).length;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (userId == null || userId!.trim().isEmpty) {
      return HomeBottomNav(
        activeOrderCount: 0,
        supplierNotificationCount: 0,
        onMyOrders: onMyOrders,
        onAnalytics: onAnalytics,
        onMe: onMe,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, vendorSnapshot) {
        final vendorCount = vendorSnapshot.hasData
            ? activeVendorOrderCount(vendorSnapshot.data!.docs)
            : 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('supplierId', isEqualTo: userId)
              .snapshots(),
          builder: (context, supplierSnapshot) {
            final supplierPendingCount = supplierSnapshot.hasData
                ? pendingSupplierOrderCount(supplierSnapshot.data!.docs)
                : 0;

            return StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where(
                    'supplierId',
                    isEqualTo: userId,
                  )
                  .snapshots(),
              builder: (
                context,
                notificationSnapshot,
              ) {
                final stockNotificationCount =
                    notificationSnapshot.hasData
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

class HomeSearchSheet extends StatefulWidget {
  const HomeSearchSheet({
    super.key,
    required this.onSupplierTap,
    required this.onProductTap,
  });

  final void Function(
    Supplier supplier,
    String supplierId,
  ) onSupplierTap;

  final void Function(
    Supplier supplier,
    FishProduct product,
    String stockId,
    String supplierId,
  ) onProductTap;

  @override
  State<HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends State<HomeSearchSheet> {
  final searchController = TextEditingController();
  final HomeStockService stockService = const HomeStockService();
  final SupplierBrowseService supplierService = const SupplierBrowseService();

  String query = '';
  HomeSearchFilter selectedFilter = HomeSearchFilter.all;

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

    if (lowerText == 'test' ||
        lowerText == 'testing' ||
        lowerText == 'asdw' ||
        lowerText == 'asdf') {
      return fallback;
    }

    return text;
  }

  bool matchesAny(
    Iterable<String> values,
  ) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return values.any(
      (value) => value.trim().toLowerCase().contains(normalizedQuery),
    );
  }

  bool fishMatches(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (!stockService.isAvailableStock(document)) {
      return false;
    }

    final productName = (data['productName'] ?? '').toString();
    final category = (data['category'] ?? '').toString();
    final supplierName = (data['supplierName'] ?? '').toString();
    final location = (
      data['supplierLocation'] ??
      data['storeLocation'] ??
      data['location'] ??
      ''
    ).toString();

    return switch (selectedFilter) {
      HomeSearchFilter.suppliers => false,
      HomeSearchFilter.locations => matchesAny([
          location,
        ]),
      HomeSearchFilter.fish => matchesAny([
          productName,
          category,
        ]),
      HomeSearchFilter.all => matchesAny([
          productName,
          category,
          supplierName,
          location,
        ]),
    };
  }

  bool supplierMatches(
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

    return switch (selectedFilter) {
      HomeSearchFilter.fish => false,
      HomeSearchFilter.locations => matchesAny([
          supplier.location,
          serviceArea,
        ]),
      HomeSearchFilter.suppliers => matchesAny([
          supplier.name,
          supplier.location,
          serviceArea,
        ]),
      HomeSearchFilter.all => matchesAny([
          supplier.name,
          supplier.location,
          serviceArea,
        ]),
    };
  }

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
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

    if (lower.startsWith('per ')) {
      return unit.substring(4);
    }

    if (unit.startsWith('/')) {
      return unit.substring(1).trim();
    }

    return unit;
  }

  String fishLocation(
    Map<String, dynamic> data,
    Supplier supplier,
  ) {
    final candidates = <dynamic>[
      data['supplierLocation'],
      data['storeLocation'],
      data['location'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return cleanText(
      value: supplier.location,
      fallback: 'Caraga Region',
    );
  }

  Map<String, int> availableListingCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> fishDocuments,
  ) {
    final counts = <String, int>{};

    for (final document in fishDocuments) {
      if (!stockService.isAvailableStock(document)) {
        continue;
      }

      final supplierId =
          (document.data()['supplierId'] ?? '').toString().trim();

      if (supplierId.isEmpty) {
        continue;
      }

      counts[supplierId] = (counts[supplierId] ?? 0) + 1;
    }

    return counts;
  }

  Widget resultSummary({
    required int resultCount,
  }) {
    final searchText = query.trim();

    String label;

    if (searchText.isNotEmpty) {
      label = '$resultCount result${resultCount == 1 ? '' : 's'} for "$searchText"';
    } else {
      label = switch (selectedFilter) {
        HomeSearchFilter.fish =>
          '$resultCount available fish listing${resultCount == 1 ? '' : 's'}',
        HomeSearchFilter.suppliers =>
          '$resultCount verified supplier${resultCount == 1 ? '' : 's'}',
        HomeSearchFilter.locations => 'Search by location',
        HomeSearchFilter.all => 'Explore the marketplace',
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
                color: Color(0xFF657C8E),
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
                foregroundColor: const Color(0xFF087AC0),
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

    final fishMatchesList = fishDocuments.where(fishMatches).toList();
    final supplierMatchesList =
        approvedSuppliers.where(supplierMatches).toList();

    if (selectedFilter == HomeSearchFilter.locations &&
        normalizedQuery.isEmpty) {
      return HomeSearchLocationPrompt(
        scrollController: scrollController,
      );
    }

    final totalResultCount =
        fishMatchesList.length + supplierMatchesList.length;

    if (totalResultCount == 0) {
      return HomeSearchEmptyState(
        query: query,
        filter: selectedFilter,
        scrollController: scrollController,
        onClear: () {
          searchController.clear();

          setState(
            () {
              query = '';
              selectedFilter = HomeSearchFilter.all;
            },
          );
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
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        26,
      ),
      children: [
        resultSummary(
          resultCount: totalResultCount,
        ),
        if (visibleFish.isNotEmpty) ...[
          HomeSearchSectionLabel(
            icon: Icons.set_meal_outlined,
            label: selectedFilter == HomeSearchFilter.locations
                ? 'Fish in this location'
                : isBrowsing
                    ? 'Available Now'
                    : 'Fish Stocks',
            count: fishMatchesList.length,
          ),
          const SizedBox(height: 10),
          ...visibleFish.map(
            (document) {
              final data = document.data();
              final product = stockService.fishProductFromFirestore(
                data,
              );
              final supplier = stockService.supplierForStock(
                data,
              );
              final supplierId =
                  (data['supplierId'] ?? '').toString().trim();

              if (supplier == null || supplierId.isEmpty) {
                return const SizedBox.shrink();
              }

              final ownerListing =
                  currentUid.isNotEmpty && supplierId == currentUid;

              return HomeSearchFishCard(
                imageUrl: product.imageUrl,
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
                ownerListing: ownerListing,
                onTap: () {
                  Navigator.pop(context);

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
          const SizedBox(height: 8),
        ],
        if (visibleSuppliers.isNotEmpty) ...[
          HomeSearchSectionLabel(
            icon: Icons.verified_outlined,
            label: selectedFilter == HomeSearchFilter.locations
                ? 'Suppliers in this location'
                : 'Verified Suppliers',
            count: supplierMatchesList.length,
          ),
          const SizedBox(height: 10),
          ...visibleSuppliers.map(
            (document) {
              final supplier = supplierService.supplierFromProfile(
                document.data(),
              );

              final ownerStore =
                  currentUid.isNotEmpty && document.id == currentUid;

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
                activeListings:
                    listingCounts[document.id] ?? 0,
                ownerStore: ownerStore,
                onTap: () {
                  Navigator.pop(context);

                  Future.microtask(
                    () => widget.onSupplierTap(
                      supplier,
                      document.id,
                    ),
                  );
                },
              );
            },
          ),
        ],
        if (isBrowsing &&
            selectedFilter == HomeSearchFilter.all &&
            (fishMatchesList.length > 4 ||
                supplierMatchesList.length > 4)) ...[
          const SizedBox(height: 4),
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
            selected: selectedFilter == HomeSearchFilter.all,
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
          const SizedBox(width: 7),
          HomeSearchFilterChip(
            selected: selectedFilter == HomeSearchFilter.fish,
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
          const SizedBox(width: 7),
          HomeSearchFilterChip(
            selected: selectedFilter == HomeSearchFilter.suppliers,
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
          const SizedBox(width: 7),
          HomeSearchFilterChip(
            selected: selectedFilter == HomeSearchFilter.locations,
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
      initialChildSize: 0.88,
      minChildSize: 0.52,
      maxChildSize: 0.95,
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
                blurRadius: 26,
                offset: Offset(0, -7),
              ),
            ],
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
                padding: const EdgeInsets.fromLTRB(
                  18,
                  14,
                  18,
                  9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0875D1),
                                Color(0xFF12B6D6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.travel_explore_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search IsdaLink Market',
                                style: TextStyle(
                                  color: Color(0xFF102C44),
                                  fontSize: 19.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Find fish stocks, verified suppliers, and locations.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF7B8FA3),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: const Color(0xFFEAF2F7),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: const SizedBox(
                              width: 38,
                              height: 38,
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
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(
                          () {
                            query = value;
                          },
                        );
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
                          fontSize: 11.8,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF087AC0),
                          size: 21,
                        ),
                        suffixIcon: query.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  searchController.clear();

                                  setState(
                                    () {
                                      query = '';
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF7B8FA3),
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
                          borderRadius: BorderRadius.circular(17),
                          borderSide: const BorderSide(
                            color: Color(0xFFDCEAF2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: const BorderSide(
                            color: Color(0xFFDCEAF2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: const BorderSide(
                            color: Color(0xFF087AC0),
                            width: 1.35,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    filterBar(),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE5EFF5),
              ),
              Expanded(
                child:
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('fishStocks')
                      .snapshots(),
                  builder: (
                    context,
                    fishSnapshot,
                  ) {
                    if (fishSnapshot.hasError) {
                      return HomeSearchErrorState(
                        scrollController: scrollController,
                      );
                    }

                    if (!fishSnapshot.hasData) {
                      return const HomeSearchLoading();
                    }

                    return StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('supplierProfiles')
                          .where('status', isEqualTo: 'approved')
                          .snapshots(),
                      builder: (
                        context,
                        supplierSnapshot,
                      ) {
                        if (supplierSnapshot.hasError) {
                          return HomeSearchErrorState(
                            scrollController: scrollController,
                          );
                        }

                        if (!supplierSnapshot.hasData) {
                          return const HomeSearchLoading();
                        }

                        return buildResults(
                          fishDocuments: fishSnapshot.data!.docs,
                          supplierDocuments:
                              supplierSnapshot.data!.docs,
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

class HomeSearchFilterChip extends StatelessWidget {
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
          ? const Color(0xFF087AC0)
          : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFF087AC0)
                  : const Color(0xFFDDEAF2),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x20087AC0),
                      blurRadius: 8,
                      offset: Offset(0, 4),
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
                    : const Color(0xFF6D8495),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF52677A),
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

class HomeSearchSectionLabel extends StatelessWidget {
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
            color: const Color(0xFFE7F7FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF087AC0),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF102C44),
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
            color: const Color(0xFFEAF2F7),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF657C8E),
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class HomeSearchFishCard extends StatelessWidget {
  const HomeSearchFishCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.supplierName,
    required this.location,
    required this.priceText,
    required this.stockText,
    required this.stockStatus,
    required this.stockColor,
    required this.ownerListing,
    required this.onTap,
  });

  final String imageUrl;
  final String productName;
  final String supplierName;
  final String location;
  final String priceText;
  final String stockText;
  final String stockStatus;
  final Color stockColor;
  final bool ownerListing;
  final VoidCallback onTap;

  bool get hasImage {
    final value = imageUrl.trim();

    return value.startsWith('http://') ||
        value.startsWith('https://');
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
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const _SearchImagePlaceholder(
          icon: Icons.set_meal_rounded,
          loading: true,
        );
      },
      errorBuilder: (_, __, ___) {
        return const _SearchImagePlaceholder(
          icon: Icons.set_meal_rounded,
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
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
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                            productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 13.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (ownerListing) ...[
                          const SizedBox(width: 6),
                          const _SearchOwnerBadge(
                            label: 'YOUR LISTING',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: Color(0xFF6D8495),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            supplierName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF52677A),
                              fontSize: 9.8,
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
                              fontSize: 8.9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            priceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF087AC0),
                              fontSize: 12.5,
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
                              fontSize: 7.6,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stockText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF71889A),
                        fontSize: 8.9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9AB0BF),
                size: 14,
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
    required this.onTap,
  });

  final String imageUrl;
  final String supplierName;
  final String location;
  final double rating;
  final int reviews;
  final int activeListings;
  final bool ownerStore;
  final VoidCallback onTap;

  bool get hasImage {
    final value = imageUrl.trim();

    return value.startsWith('http://') ||
        value.startsWith('https://');
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
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const _SearchImagePlaceholder(
          icon: Icons.storefront_rounded,
          loading: true,
        );
      },
      errorBuilder: (_, __, ___) {
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
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
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
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                              fontSize: 13.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF087AC0),
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF7B8FA3),
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7B8FA3),
                              fontSize: 9.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          reviews > 0
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFB703),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ratingText,
                          style: const TextStyle(
                            color: Color(0xFF52677A),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB3C1CC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '$activeListings active listing${activeListings == 1 ? '' : 's'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF657C8E),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: ownerStore
                      ? const Color(0xFFE4F6EE)
                      : const Color(0xFFE8F8FD),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  ownerStore ? 'Your Store' : 'View Store',
                  style: TextStyle(
                    color: ownerStore
                        ? const Color(0xFF147D64)
                        : const Color(0xFF087AC0),
                    fontSize: 8.3,
                    fontWeight: FontWeight.w900,
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

class _SearchImagePlaceholder extends StatelessWidget {
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
      color: const Color(0xFFEAF6FA),
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
              color: const Color(0xFF087AC0),
              size: 27,
            ),
    );
  }
}

class _SearchOwnerBadge extends StatelessWidget {
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
        color: const Color(0xFFE4F6EE),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF147D64),
          fontSize: 6.8,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class HomeSearchBrowseHint extends StatelessWidget {
  const HomeSearchBrowseHint({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD7EBF3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Color(0xFF087AC0),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Type a fish, supplier, or location to narrow the marketplace results.',
              style: TextStyle(
                color: Color(0xFF657C8E),
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
  });

  final ScrollController scrollController;

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        18,
        24,
        18,
        26,
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            20,
            18,
            20,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEAF8FC),
                Color(0xFFF1F8FF),
              ],
            ),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: const Color(0xFFD6EAF3),
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.location_searching_rounded,
                color: Color(0xFF087AC0),
                size: 32,
              ),
              SizedBox(height: 10),
              Text(
                'Search by location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Enter a city, municipality, province, or market area to find available fish and verified suppliers there.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF657C8E),
                  fontSize: 10.2,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Example: Butuan City',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF087AC0),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
    required this.onClear,
  });

  final String query;
  final HomeSearchFilter filter;
  final ScrollController scrollController;
  final VoidCallback onClear;

  String get message {
    final text = query.trim();

    if (text.isEmpty) {
      return switch (filter) {
        HomeSearchFilter.fish =>
          'There are no available fish listings right now.',
        HomeSearchFilter.suppliers =>
          'There are no verified suppliers available right now.',
        HomeSearchFilter.locations =>
          'Enter a location to search the marketplace.',
        HomeSearchFilter.all =>
          'There are no marketplace results available right now.',
      };
    }

    return 'No marketplace results matched "$text". Try another fish, supplier, or location.';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        18,
        28,
        18,
        26,
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
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
                  Icons.search_off_rounded,
                  color: Color(0xFF087AC0),
                  size: 27,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No results found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 14,
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
      ],
    );
  }
}

class HomeSearchLoading extends StatelessWidget {
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
  });

  final ScrollController scrollController;

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        18,
        28,
        18,
        26,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFF0D6D4),
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFD94A45),
                size: 31,
              ),
              SizedBox(height: 10),
              Text(
                'Search is temporarily unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Check your connection and try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF657C8E),
                  fontSize: 10.2,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

