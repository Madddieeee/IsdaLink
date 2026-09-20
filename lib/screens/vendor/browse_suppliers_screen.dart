import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_header.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_status_cards.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/supplier_profile_card.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

enum BrowseSupplierTab { all, favorites }

enum BrowseSupplierSort { recommended, rating, listings, recentlyUpdated, name }

class BrowseSuppliersScreen extends StatefulWidget {
  const BrowseSuppliersScreen({super.key});

  @override
  State<BrowseSuppliersScreen> createState() => _BrowseSuppliersScreenState();
}

class _BrowseSuppliersScreenState extends State<BrowseSuppliersScreen> {
  final searchController = TextEditingController();
  final SupplierBrowseService supplierService = const SupplierBrowseService();

  String searchQuery = '';
  BrowseSupplierTab selectedTab = BrowseSupplierTab.all;
  BrowseSupplierSort selectedSort = BrowseSupplierSort.recommended;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openSupplierDetails({
    required BuildContext context,
    required String supplierId,
    required Map<String, dynamic> data,
  }) {
    final supplier = supplierService.supplierFromProfile(data);

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

  String stringValue(
    Map<String, dynamic> data,
    String key, [
    String fallback = '',
  ]) {
    final value = data[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String supplierImageUrl(Map<String, dynamic> data) {
    final profileImageUrl = stringValue(data, 'profileImageUrl');
    if (profileImageUrl.isNotEmpty) return profileImageUrl;

    final storePhotoUrl = stringValue(data, 'storePhotoUrl');
    if (storePhotoUrl.isNotEmpty) return storePhotoUrl;

    final photoUrl = stringValue(data, 'photoUrl');
    if (photoUrl.isNotEmpty) return photoUrl;

    final application = data['supplierApplication'];
    if (application is Map<String, dynamic>) {
      return stringValue(application, 'storePhotoUrl');
    }

    return '';
  }

  bool isAvailableStock(Map<String, dynamic> data) {
    final status = stringValue(data, 'status', 'available').toLowerCase();
    final quantity = double.tryParse((data['quantity'] ?? 0).toString()) ?? 0;
    return (status == 'available' || status == 'active') && quantity > 0;
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> stockMap(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  ) {
    final result = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final stock in stocks) {
      final data = stock.data();
      if (!isAvailableStock(data)) continue;

      final supplierId = stringValue(data, 'supplierId');
      if (supplierId.isEmpty) continue;

      result.putIfAbsent(supplierId, () => []).add(stock);
    }

    return result;
  }

  List<String> productNamesFor(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  ) {
    final names = <String>[];
    final seen = <String>{};

    for (final stock in stocks) {
      final name = stringValue(stock.data(), 'productName');
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) names.add(name);
    }

    return names;
  }

  int createdAtMillis(Map<String, dynamic> data) {
    final value = data['createdAt'];
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }

  int stockActivityMillis(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
  ) {
    var latest = 0;
    for (final stock in stocks) {
      final data = stock.data();
      for (final key in const ['updatedAt', 'restockedAt', 'createdAt']) {
        final value = data[key];
        if (value is Timestamp) {
          final millis = value.millisecondsSinceEpoch;
          if (millis > latest) latest = millis;
          break;
        }
      }
    }
    return latest;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> applySort({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> stocksBySupplier,
  }) {
    final sorted = [...documents];

    switch (selectedSort) {
      case BrowseSupplierSort.rating:
        sorted.sort((a, b) {
          final aSupplier = supplierService.supplierFromProfile(a.data());
          final bSupplier = supplierService.supplierFromProfile(b.data());
          final ratingCompare = bSupplier.rating.compareTo(aSupplier.rating);
          if (ratingCompare != 0) return ratingCompare;
          final reviewCompare = bSupplier.reviews.compareTo(aSupplier.reviews);
          if (reviewCompare != 0) return reviewCompare;
          return aSupplier.name.toLowerCase().compareTo(
                bSupplier.name.toLowerCase(),
              );
        });
        break;
      case BrowseSupplierSort.listings:
        sorted.sort((a, b) {
          final countCompare = (stocksBySupplier[b.id]?.length ?? 0).compareTo(
            stocksBySupplier[a.id]?.length ?? 0,
          );
          if (countCompare != 0) return countCompare;
          final aName = supplierService.supplierFromProfile(a.data()).name;
          final bName = supplierService.supplierFromProfile(b.data()).name;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
        break;
      case BrowseSupplierSort.recentlyUpdated:
        sorted.sort((a, b) {
          final aUpdated = stockActivityMillis(
            stocksBySupplier[a.id] ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          );
          final bUpdated = stockActivityMillis(
            stocksBySupplier[b.id] ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          );
          final updateCompare = bUpdated.compareTo(aUpdated);
          if (updateCompare != 0) return updateCompare;
          final aName = supplierService.supplierFromProfile(a.data()).name;
          final bName = supplierService.supplierFromProfile(b.data()).name;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
        break;
      case BrowseSupplierSort.name:
        sorted.sort((a, b) {
          final aName = supplierService.supplierFromProfile(a.data()).name;
          final bName = supplierService.supplierFromProfile(b.data()).name;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
        break;
      case BrowseSupplierSort.recommended:
        sorted.sort((a, b) {
          final aStocks = stocksBySupplier[a.id] ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final bStocks = stocksBySupplier[b.id] ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          final availabilityCompare = (bStocks.isNotEmpty ? 1 : 0).compareTo(
            aStocks.isNotEmpty ? 1 : 0,
          );
          if (availabilityCompare != 0) return availabilityCompare;

          final aSupplier = supplierService.supplierFromProfile(a.data());
          final bSupplier = supplierService.supplierFromProfile(b.data());
          final ratingCompare = bSupplier.rating.compareTo(aSupplier.rating);
          if (ratingCompare != 0) return ratingCompare;

          final reviewCompare = bSupplier.reviews.compareTo(aSupplier.reviews);
          if (reviewCompare != 0) return reviewCompare;

          final listingCompare = bStocks.length.compareTo(aStocks.length);
          if (listingCompare != 0) return listingCompare;

          final activityCompare = stockActivityMillis(bStocks).compareTo(
            stockActivityMillis(aStocks),
          );
          if (activityCompare != 0) return activityCompare;

          return aSupplier.name.toLowerCase().compareTo(
                bSupplier.name.toLowerCase(),
              );
        });
        break;
    }

    return sorted;
  }

  String sortLabel(BrowseSupplierSort sort) {
    switch (sort) {
      case BrowseSupplierSort.recommended:
        return 'Recommended';
      case BrowseSupplierSort.rating:
        return 'Top Rated';
      case BrowseSupplierSort.listings:
        return 'Most Listings';
      case BrowseSupplierSort.recentlyUpdated:
        return 'Recently Updated';
      case BrowseSupplierSort.name:
        return 'Name A-Z';
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> favoriteStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favoriteSuppliers')
        .snapshots();
  }

  Widget browseSearchSection({
    required int approvedCount,
    required int listingCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18003C61),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Color(0xFF123A59),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search supplier, fish, or location...',
                hintStyle: const TextStyle(
                  color: Color(0xFF8BA2B4),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0875D1),
                      size: 21,
                    ),
                  ),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: searchController.text.isEmpty
                      ? Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF0875D1),
                            size: 21,
                          ),
                        )
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF7890A2),
                          ),
                        ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          BrowseSuppliersStatusCards(
            supplierCount: approvedCount,
            listingCount: listingCount,
          ),
        ],
      ),
    );
  }

  Widget tabButton({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF0875D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? Colors.white : const Color(0xFF617F95),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF617F95),
                      fontSize: 11.2,
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

  Widget filterRow({
    required int favoriteCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD8E8F1)),
            ),
            child: Row(
              children: [
                tabButton(
                  selected: selectedTab == BrowseSupplierTab.all,
                  icon: Icons.storefront_rounded,
                  label: 'All Suppliers',
                  onTap: () {
                    setState(() => selectedTab = BrowseSupplierTab.all);
                  },
                ),
                tabButton(
                  selected: selectedTab == BrowseSupplierTab.favorites,
                  icon: Icons.favorite_border_rounded,
                  label: 'Favorites',
                  onTap: () {
                    setState(() => selectedTab = BrowseSupplierTab.favorites);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<BrowseSupplierSort>(
              tooltip: 'Sort suppliers',
              initialValue: selectedSort,
              onSelected: (value) {
                setState(() => selectedSort = value);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              itemBuilder: (context) => BrowseSupplierSort.values
                  .map(
                    (sort) => PopupMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(
                            sort == selectedSort
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 17,
                            color: const Color(0xFF0875D1),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            sortLabel(sort),
                            style: const TextStyle(
                              color: Color(0xFF173B56),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              child: Container(
                height: 46,
                width: 156,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFE0F2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF0875D1),
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        sortLabel(selectedSort),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0875D1),
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF0875D1),
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEAF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0875D1), size: 28),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF71899B),
              fontSize: 11.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: supplierService.suppliersStream,
        builder: (context, supplierSnapshot) {
          final supplierDocuments = supplierSnapshot.data?.docs ?? [];
          final approvedDocuments = supplierService.approvedSuppliers(
            supplierDocuments,
          );

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('fishStocks').snapshots(),
            builder: (context, stockSnapshot) {
              final stockDocuments = stockSnapshot.data?.docs ?? [];
              final stocksBySupplier = stockMap(stockDocuments);
              final listingCount = stocksBySupplier.values.fold<int>(
                0,
                (total, items) => total + items.length,
              );

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                return _buildBody(
                  context: context,
                  supplierSnapshot: supplierSnapshot,
                  approvedDocuments: approvedDocuments,
                  stocksBySupplier: stocksBySupplier,
                  listingCount: listingCount,
                  favoriteIds: const <String>{},
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: favoriteStream(),
                builder: (context, favoriteSnapshot) {
                  final favoriteIds = favoriteSnapshot.data?.docs
                          .map((document) => document.id)
                          .toSet() ??
                      <String>{};

                  return _buildBody(
                    context: context,
                    supplierSnapshot: supplierSnapshot,
                    approvedDocuments: approvedDocuments,
                    stocksBySupplier: stocksBySupplier,
                    listingCount: listingCount,
                    favoriteIds: favoriteIds,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> supplierSnapshot,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> approvedDocuments,
    required Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> stocksBySupplier,
    required int listingCount,
    required Set<String> favoriteIds,
  }) {
    final supplierMatches = supplierService.searchSuppliers(
      documents: approvedDocuments,
      query: searchQuery,
    );

    final normalizedQuery = searchQuery.trim().toLowerCase();
    final supplierMatchIds = supplierMatches.map((document) => document.id).toSet();

    final filtered = normalizedQuery.isEmpty
        ? approvedDocuments
        : approvedDocuments.where((document) {
            if (supplierMatchIds.contains(document.id)) {
              return true;
            }

            final stocks = stocksBySupplier[document.id] ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            return stocks.any((stock) {
              final data = stock.data();
              final productName = stringValue(data, 'productName').toLowerCase();
              final category = stringValue(data, 'category').toLowerCase();
              return productName.contains(normalizedQuery) ||
                  category.contains(normalizedQuery);
            });
          }).toList();

    var visible = selectedTab == BrowseSupplierTab.favorites
        ? filtered.where((document) => favoriteIds.contains(document.id)).toList()
        : [...filtered];

    visible = applySort(
      documents: visible,
      stocksBySupplier: stocksBySupplier,
    );

    return ListView(
      padding: EdgeInsets.zero,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        BrowseSuppliersHeader(
          onBack: () => Navigator.pop(context),
        ),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
            children: [
              browseSearchSection(
                approvedCount: approvedDocuments.length,
                listingCount: listingCount,
              ),
              filterRow(favoriteCount: favoriteIds.length),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTab == BrowseSupplierTab.favorites
                                ? 'Favorite Suppliers'
                                : 'All Suppliers',
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 17,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            selectedTab == BrowseSupplierTab.favorites
                                ? '${visible.length} saved supplier${visible.length == 1 ? '' : 's'}.'
                                : '${approvedDocuments.length} verified suppliers across Caraga.',
                            style: const TextStyle(
                              color: Color(0xFF748C9E),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        if (supplierSnapshot.hasError)
          emptyCard(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to load suppliers',
            subtitle: AppErrorMessage.from(
              supplierSnapshot.error!,
              fallback: 'Please check your connection and try again.',
            ),
          )
        else if (!supplierSnapshot.hasData)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 42),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF0875D1),
              ),
            ),
          )
        else if (approvedDocuments.isEmpty)
          emptyCard(
            icon: Icons.storefront_outlined,
            title: 'No approved suppliers yet',
            subtitle: 'Approved supplier stores will appear here after verification.',
          )
        else if (visible.isEmpty && searchQuery.trim().isNotEmpty)
          emptyCard(
            icon: Icons.search_off_rounded,
            title: 'No matching suppliers',
            subtitle: 'Try another supplier name, fish product, or Caraga location.',
          )
        else if (visible.isEmpty && selectedTab == BrowseSupplierTab.favorites)
          emptyCard(
            icon: Icons.favorite_border_rounded,
            title: 'No favorite suppliers yet',
            subtitle: 'Tap the heart on a supplier card to save it here for quick access.',
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  Builder(
                    builder: (context) {
                      final document = visible[index];
                      final data = document.data();
                      final supplier = supplierService.supplierFromProfile(data);
                      final supplierStocks = stocksBySupplier[document.id] ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                      return SupplierProfileCard(
                        supplier: supplier,
                        supplierId: document.id,
                        imageUrl: supplierImageUrl(data),
                        availableListingCount: supplierStocks.length,
                        productNames: productNamesFor(supplierStocks),
                        onTap: () => openSupplierDetails(
                          context: context,
                          supplierId: document.id,
                          data: data,
                        ),
                      );
                    },
                  ),
                  if (index != visible.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
