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
        builder: (_) => const AnalyticsScreen(),
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
              stream:
                  FirebaseFirestore.instance.collection('supplierProfiles').snapshots(),
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

            return HomeBottomNav(
              activeOrderCount: vendorCount,
              supplierNotificationCount: supplierPendingCount,
              onMyOrders: onMyOrders,
              onAnalytics: onAnalytics,
              onMe: onMe,
            );
          },
        );
      },
    );
  }
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

  bool matchesQuery(
    List<String> values,
  ) {
    final lowerQuery = query.trim().toLowerCase();

    if (lowerQuery.isEmpty) {
      return true;
    }

    return values.any(
      (value) => value.toLowerCase().contains(lowerQuery),
    );
  }

  bool isApprovedSupplier(
    Map<String, dynamic> data,
  ) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    final verificationStatus =
        (data['verificationStatus'] ?? '').toString().toLowerCase();

    return status == 'approved' || verificationStatus == 'approved';
  }

  bool isAvailableFishStock(
    Map<String, dynamic> data,
  ) {
    final status = (data['status'] ?? 'available').toString().toLowerCase();
    final quantity = double.tryParse((data['quantity'] ?? 0).toString()) ?? 0;

    return (status == 'available' || status == 'active') && quantity > 0;
  }

  Widget buildResults({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> fishDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> supplierDocuments,
  }) {
    final fishResults = fishDocuments.where(
      (document) {
        final data = document.data();

        if (!isAvailableFishStock(data)) {
          return false;
        }

        final productName = (data['productName'] ?? '').toString();
        final supplierName = (data['supplierName'] ?? '').toString();
        final location =
            (data['supplierLocation'] ?? data['location'] ?? '').toString();
        final category = (data['category'] ?? '').toString();

        return matchesQuery([
          productName,
          supplierName,
          location,
          category,
        ]);
      },
    ).take(8).toList();

    final supplierResults = supplierDocuments.where(
      (document) {
        final data = document.data();

        if (!isApprovedSupplier(data)) {
          return false;
        }

        final supplierName = (data['supplierName'] ??
                data['storeName'] ??
                data['businessName'] ??
                '')
            .toString();
        final location =
            (data['location'] ?? data['storeLocation'] ?? '').toString();
        final serviceArea = (data['serviceArea'] ?? '').toString();

        return matchesQuery([
          supplierName,
          location,
          serviceArea,
        ]);
      },
    ).take(8).toList();

    if (fishResults.isEmpty && supplierResults.isEmpty) {
      return const HomeSearchEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
      children: [
        if (fishResults.isNotEmpty) ...[
          const HomeSearchSectionLabel(
            label: 'Available fish stocks',
          ),
          const SizedBox(height: 9),
          ...fishResults.map(
            (document) {
              final data = document.data();
              final product = stockService.fishProductFromFirestore(data);
              final supplier = stockService.supplierForStock(data);
              final supplierId = (data['supplierId'] ?? '').toString();

              if (supplier == null) {
                return const SizedBox.shrink();
              }

              return HomeSearchResultTile(
                icon: product.emoji,
                title: cleanText(
                  value: product.name,
                  fallback: 'Fresh Fish Stock',
                ),
                subtitle:
                    '${cleanText(value: supplier.name, fallback: 'Verified Supplier')} • ${product.priceUnit} • ${product.availableQuantity.toStringAsFixed(product.availableQuantity % 1 == 0 ? 0 : 1)} ${product.quantityUnit}',
                badge: '₱${product.price.toStringAsFixed(0)}',
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
          const SizedBox(height: 14),
        ],
        if (supplierResults.isNotEmpty) ...[
          const HomeSearchSectionLabel(
            label: 'Verified suppliers',
          ),
          const SizedBox(height: 9),
          ...supplierResults.map(
            (document) {
              final data = document.data();
              final supplier = supplierService.supplierFromProfile(data);

              return HomeSearchResultTile(
                icon: '🏪',
                title: cleanText(
                  value: supplier.name,
                  fallback: 'Verified Supplier',
                ),
                subtitle: cleanText(
                  value: supplier.location,
                  fallback: 'Caraga Region',
                ),
                badge: 'View',
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
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FAFF),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9DDEA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search IsdaLink Market',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Find fish stocks, verified suppliers, and locations without leaving Home.',
                      style: TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Try: shark, bangus, vendor, Butuan',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AADBC),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF087AC0),
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();

                                  setState(() {
                                    query = '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFF7B8FA3),
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
                            color: Color(0xFFD7EEF6),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFD7EEF6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFF087AC0),
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('fishStocks')
                      .snapshots(),
                  builder: (context, fishSnapshot) {
                    if (fishSnapshot.hasError) {
                      return HomeSearchErrorState(
                        error: fishSnapshot.error!,
                      );
                    }

                    if (!fishSnapshot.hasData) {
                      return const HomeSearchLoading();
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('supplierProfiles')
                          .snapshots(),
                      builder: (context, supplierSnapshot) {
                        if (supplierSnapshot.hasError) {
                          return HomeSearchErrorState(
                            error: supplierSnapshot.error!,
                          );
                        }

                        if (!supplierSnapshot.hasData) {
                          return const HomeSearchLoading();
                        }

                        return buildResults(
                          fishDocuments: fishSnapshot.data!.docs,
                          supplierDocuments: supplierSnapshot.data!.docs,
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

class HomeSearchSectionLabel extends StatelessWidget {
  const HomeSearchSectionLabel({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF102C44),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class HomeSearchResultTile extends StatelessWidget {
  const HomeSearchResultTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: const Color(0xFFE1EEF6),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F9FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(
                    fontSize: 25,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F9FF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Color(0xFF087AC0),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeSearchEmptyState extends StatelessWidget {
  const HomeSearchEmptyState({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'No matching fish stocks or suppliers found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7B8FA3),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    );
  }
}

class HomeSearchErrorState extends StatelessWidget {
  const HomeSearchErrorState({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          'Unable to load search results: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
