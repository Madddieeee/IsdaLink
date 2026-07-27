import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.onLogout,
    required this.onSearchTap,
    required this.onProfileTap,
  });

  final VoidCallback onLogout;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final searchLayerLink = LayerLink();

  final HomeStockService stockService = const HomeStockService();
  final SupplierBrowseService supplierService = const SupplierBrowseService();

  OverlayEntry? searchOverlayEntry;
  String query = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    searchFocusNode.addListener(
      () {
        if (searchFocusNode.hasFocus) {
          showSearchOverlay();
        } else if (query.trim().isEmpty) {
          hideSearchOverlay();
        }

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    hideSearchOverlay();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void showSearchOverlay() {
    if (searchOverlayEntry != null) {
      searchOverlayEntry!.markNeedsBuild();
      return;
    }

    searchOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: closeSearch,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              CompositedTransformFollower(
                link: searchLayerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 58),
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 36,
                    child: searchResultsDropdown(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(searchOverlayEntry!);
  }

  void hideSearchOverlay() {
    searchOverlayEntry?.remove();
    searchOverlayEntry = null;
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
        lowerText == 'asdf' ||
        lowerText == 'sample') {
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

  bool isAvailableFishStock(
    Map<String, dynamic> data,
  ) {
    final status = OrderHelpers.getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );

    return (status == 'available' || status == 'active') && quantity > 0;
  }

  bool isApprovedSupplier(
    Map<String, dynamic> data,
  ) {
    final status = OrderHelpers.getStringValue(
      data,
      'status',
      '',
    ).toLowerCase();

    final verificationStatus = OrderHelpers.getStringValue(
      data,
      'verificationStatus',
      '',
    ).toLowerCase();

    return status == 'approved' || verificationStatus == 'approved';
  }

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  void closeSearch() {
    searchController.clear();
    searchFocusNode.unfocus();

    if (mounted) {
      setState(() {
        query = '';
      });
    }

    hideSearchOverlay();
  }

  void openSupplierDetails({
    required Supplier supplier,
    required String supplierId,
  }) {
    closeSearch();

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

  void openProductDetails({
    required Supplier supplier,
    required FishProduct product,
    required String stockId,
    required String supplierId,
  }) {
    closeSearch();

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

  Widget userHeaderInfo() {
    final user = currentUser;

    if (user == null) {
      return const HomeUserText(
        name: 'Guest User',
        subtitle: 'Find verified suppliers, fresh fish stocks, and COD orders.',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final fallbackName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'IsdaLink User';

        final name = data == null
            ? fallbackName
            : OrderHelpers.getStringValue(
                data,
                'name',
                fallbackName,
              );

        final role = data == null
            ? 'vendor'
            : OrderHelpers.getStringValue(
                data,
                'role',
                'vendor',
              ).toLowerCase();

        final supplierStatus = data == null
            ? 'not_applicable'
            : OrderHelpers.getStringValue(
                data,
                'supplierStatus',
                'not_applicable',
              ).toLowerCase();

        final isSupplier = role == 'supplier' || supplierStatus == 'approved';

        return HomeUserText(
          name: cleanText(
            value: name,
            fallback: 'IsdaLink User',
          ),
          subtitle: isSupplier
              ? 'Manage supplier tools, COD orders, and market insights.'
              : 'Find verified suppliers, fresh fish stocks, and COD orders.',
        );
      },
    );
  }

  Widget searchBox() {
    return CompositedTransformTarget(
      link: searchLayerLink,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          focusNode: searchFocusNode,
          textInputAction: TextInputAction.search,
          onTap: showSearchOverlay,
          onChanged: (value) {
            setState(() {
              query = value;
            });

            showSearchOverlay();
            searchOverlayEntry?.markNeedsBuild();
          },
          decoration: InputDecoration(
            hintText: 'Search fish, suppliers, or locations',
            hintStyle: const TextStyle(
              color: Color(0xFF9AADBC),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF6B8CA3),
              size: 21,
            ),
            suffixIcon: query.trim().isEmpty
                ? const Icon(
                    Icons.set_meal,
                    color: Color(0xFF10B7D4),
                    size: 20,
                  )
                : IconButton(
                    onPressed: closeSearch,
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF7B8FA3),
                      size: 20,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget searchResultsDropdown() {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 420,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE1EEF6),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF4FAFF),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE1EEF6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    query.trim().isEmpty
                        ? Icons.auto_awesome
                        : Icons.manage_search,
                    color: const Color(0xFF087AC0),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      query.trim().isEmpty
                          ? 'Explore available market'
                          : 'Matching market results',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: closeSearch,
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFF7B8FA3),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('fishStocks')
                    .snapshots(),
                builder: (context, fishSnapshot) {
                  if (fishSnapshot.hasError) {
                    return HomeInlineSearchError(
                      error: fishSnapshot.error!,
                    );
                  }

                  if (!fishSnapshot.hasData) {
                    return const HomeInlineSearchLoading();
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('supplierProfiles')
                        .snapshots(),
                    builder: (context, supplierSnapshot) {
                      if (supplierSnapshot.hasError) {
                        return HomeInlineSearchError(
                          error: supplierSnapshot.error!,
                        );
                      }

                      if (!supplierSnapshot.hasData) {
                        return const HomeInlineSearchLoading();
                      }

                      return buildSearchResults(
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
      ),
    );
  }

  Widget buildSearchResults({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> fishDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> supplierDocuments,
  }) {
    final fishResults = fishDocuments.where(
      (document) {
        final data = document.data();

        if (!isAvailableFishStock(data)) {
          return false;
        }

        final productName = OrderHelpers.getStringValue(
          data,
          'productName',
          '',
        );

        final supplierName = OrderHelpers.getStringValue(
          data,
          'supplierName',
          '',
        );

        final location = OrderHelpers.getStringValue(
          data,
          'supplierLocation',
          OrderHelpers.getStringValue(
            data,
            'location',
            '',
          ),
        );

        final category = OrderHelpers.getStringValue(
          data,
          'category',
          '',
        );

        return matchesQuery([
          productName,
          supplierName,
          location,
          category,
        ]);
      },
    ).take(6).toList();

    final supplierResults = supplierDocuments.where(
      (document) {
        final data = document.data();

        if (!isApprovedSupplier(data)) {
          return false;
        }

        final supplierName = OrderHelpers.getStringValue(
          data,
          'supplierName',
          OrderHelpers.getStringValue(
            data,
            'storeName',
            OrderHelpers.getStringValue(
              data,
              'businessName',
              '',
            ),
          ),
        );

        final location = OrderHelpers.getStringValue(
          data,
          'location',
          OrderHelpers.getStringValue(
            data,
            'storeLocation',
            '',
          ),
        );

        final serviceArea = OrderHelpers.getStringValue(
          data,
          'serviceArea',
          '',
        );

        return matchesQuery([
          supplierName,
          location,
          serviceArea,
        ]);
      },
    ).take(5).toList();

    if (fishResults.isEmpty && supplierResults.isEmpty) {
      return const HomeInlineSearchEmpty();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      shrinkWrap: true,
      children: [
        HomeSearchMarketSummary(
          fishCount: fishResults.length,
          supplierCount: supplierResults.length,
          query: query,
        ),
        const SizedBox(height: 11),
        if (fishResults.isNotEmpty) ...[
          HomeInlineSearchLabel(
            label: 'Fish available now',
            count: fishResults.length,
          ),
          const SizedBox(height: 8),
          ...fishResults.map(
            (document) {
              final data = document.data();

              final product = stockService.fishProductFromFirestore(
                data,
              );

              final supplier = stockService.supplierForStock(
                data,
              );

              final supplierId = OrderHelpers.getStringValue(
                data,
                'supplierId',
                '',
              );

              if (supplier == null) {
                return const SizedBox.shrink();
              }

              return HomeInlineSearchTile(
                emoji: product.emoji,
                imageUrl: product.imageUrl,
                title: cleanText(
                  value: product.name,
                  fallback: 'Fresh Fish Stock',
                ),
                subtitle:
                    '${cleanText(value: supplier.name, fallback: 'Verified Supplier')} • ${formatNumber(product.availableQuantity)} ${product.quantityUnit}',
                badge: '₱${product.price.toStringAsFixed(0)}',
                isPrice: true,
                onTap: () {
                  openProductDetails(
                    supplier: supplier,
                    product: product,
                    stockId: document.id,
                    supplierId: supplierId,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (supplierResults.isNotEmpty) ...[
          HomeInlineSearchLabel(
            label: 'Trusted suppliers',
            count: supplierResults.length,
          ),
          const SizedBox(height: 8),
          ...supplierResults.map(
            (document) {
              final data = document.data();

              final supplier = supplierService.supplierFromProfile(
                data,
              );

              return HomeInlineSearchTile(
                emoji: '🏪',
                imageUrl: '',
                title: cleanText(
                  value: supplier.name,
                  fallback: 'Verified Supplier',
                ),
                subtitle: cleanText(
                  value: supplier.location,
                  fallback: 'Caraga Region',
                ),
                badge: 'View',
                isPrice: false,
                onTap: () {
                  openSupplierDetails(
                    supplier: supplier,
                    supplierId: document.id,
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget headerCountsRow() {
    final uid = currentUser?.uid;

    return Row(
      children: [
        Expanded(
          child: HeaderCountChip(
            title: 'Suppliers',
            icon: Icons.storefront,
            stream: FirebaseFirestore.instance
                .collection('supplierProfiles')
                .snapshots(),
            countBuilder: (docs) {
              return docs.where(
                (document) {
                  final data = document.data();

                  final status = OrderHelpers.getStringValue(
                    data,
                    'status',
                    '',
                  ).toLowerCase();

                  final verificationStatus = OrderHelpers.getStringValue(
                    data,
                    'verificationStatus',
                    '',
                  ).toLowerCase();

                  return status == 'approved' ||
                      verificationStatus == 'approved';
                },
              ).length;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HeaderCountChip(
            title: 'Fish Stocks',
            icon: Icons.set_meal,
            stream: FirebaseFirestore.instance
                .collection('fishStocks')
                .snapshots(),
            countBuilder: (docs) {
              return docs.where(
                (document) {
                  final data = document.data();

                  final status = OrderHelpers.getStringValue(
                    data,
                    'status',
                    'available',
                  ).toLowerCase();

                  final quantity = OrderHelpers.getDoubleValue(
                    data,
                    'quantity',
                  );

                  return status != 'unavailable' && quantity > 0;
                },
              ).length;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: uid == null
              ? const StaticHeaderCountChip(
                  title: 'Active Orders',
                  value: '0',
                  icon: Icons.receipt_long,
                )
              : HeaderCountChip(
                  title: 'Active Orders',
                  icon: Icons.receipt_long,
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('vendorId', isEqualTo: uid)
                      .snapshots(),
                  countBuilder: (docs) {
                    return docs.where(
                      (document) {
                        final status = OrderHelpers.getStringValue(
                          document.data(),
                          'orderStatus',
                          '',
                        ).toLowerCase();

                        return status == 'pending' || status == 'accepted';
                      },
                    ).length;
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063B5C),
            Color(0xFF087AC0),
            Color(0xFF10B7D4),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -36,
            top: 14,
            child: SeaBubble(
              size: 112,
              opacity: 32,
            ),
          ),
          Positioned(
            left: -46,
            bottom: 36,
            child: SeaBubble(
              size: 90,
              opacity: 24,
            ),
          ),
          Positioned(
            right: 54,
            bottom: -44,
            child: SeaBubble(
              size: 96,
              opacity: 22,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ISDALINK',
                    style: TextStyle(
                      color: Color(0xFFE6F9FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(42),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(34),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Caraga Region',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  HeaderCircleButton(
                    icon: Icons.person,
                    onTap: widget.onProfileTap,
                  ),
                  const SizedBox(width: 8),
                  HeaderCircleButton(
                    icon: Icons.logout,
                    onTap: widget.onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              userHeaderInfo(),
              const SizedBox(height: 15),
              searchBox(),
              const SizedBox(height: 12),
              headerCountsRow(),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderCountChip extends StatelessWidget {
  const HeaderCountChip({
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
        final value = snapshot.hasData ? '${countBuilder(snapshot.data!.docs)}' : '--';

        return StaticHeaderCountChip(
          title: title,
          value: value,
          icon: icon,
        );
      },
    );
  }
}

class StaticHeaderCountChip extends StatelessWidget {
  const StaticHeaderCountChip({
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
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withAlpha(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSearchMarketSummary extends StatelessWidget {
  const HomeSearchMarketSummary({
    super.key,
    required this.fishCount,
    required this.supplierCount,
    required this.query,
  });

  final int fishCount;
  final int supplierCount;
  final String query;

  @override
  Widget build(
    BuildContext context,
  ) {
    final isSearching = query.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE6F9FF),
            Color(0xFFF4FAFF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD7EEF6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF087AC0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isSearching ? Icons.manage_search : Icons.storefront,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSearching ? 'Filtered marketplace' : 'Ready to browse',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$fishCount fish stocks • $supplierCount suppliers',
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
        ],
      ),
    );
  }
}

class HomeInlineSearchLabel extends StatelessWidget {
  const HomeInlineSearchLabel({
    super.key,
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  IconData get icon {
    if (label.toLowerCase().contains('fish')) {
      return Icons.set_meal;
    }

    return Icons.verified;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F9FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF087AC0),
            size: 15,
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
            color: const Color(0xFFE6F9FF),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF087AC0),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class HomeInlineSearchTile extends StatelessWidget {
  const HomeInlineSearchTile({
    super.key,
    required this.emoji,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isPrice,
    required this.onTap,
  });

  final String emoji;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String badge;
  final bool isPrice;
  final VoidCallback onTap;

  bool get hasImage {
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE1EEF6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F9FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return SearchImageFallback(
                            emoji: emoji,
                          );
                        },
                      )
                    : SearchImageFallback(
                        emoji: emoji,
                      ),
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPrice
                              ? const Color(0xFFE6F9FF)
                              : const Color(0xFFFFF4E0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: isPrice
                                ? const Color(0xFF087AC0)
                                : const Color(0xFFFF7A1A),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isPrice
                              ? const Color(0xFFEAF8EE)
                              : const Color(0xFFE6F9FF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPrice ? Icons.inventory_2 : Icons.verified,
                              color: isPrice
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF087AC0),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPrice ? 'Ready to order' : 'Open store',
                              style: TextStyle(
                                color: isPrice
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF087AC0),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9AADBC),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchImageFallback extends StatelessWidget {
  const SearchImageFallback({
    super.key,
    required this.emoji,
  });

  final String emoji;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Text(
        emoji,
        style: const TextStyle(
          fontSize: 29,
        ),
      ),
    );
  }
}

class HomeInlineSearchEmpty extends StatelessWidget {
  const HomeInlineSearchEmpty({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Text(
        'No matching result yet. Try typing a fish name like bangus, shark, or a supplier location.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF7B8FA3),
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class HomeInlineSearchLoading extends StatelessWidget {
  const HomeInlineSearchLoading({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Padding(
      padding: EdgeInsets.all(22),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class HomeInlineSearchError extends StatelessWidget {
  const HomeInlineSearchError({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        'Unable to load search results: $error',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class HomeUserText extends StatelessWidget {
  const HomeUserText({
    super.key,
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE2F7FF),
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class HeaderCircleButton extends StatelessWidget {
  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(42),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withAlpha(34),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class SeaBubble extends StatelessWidget {
  const SeaBubble({
    super.key,
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
