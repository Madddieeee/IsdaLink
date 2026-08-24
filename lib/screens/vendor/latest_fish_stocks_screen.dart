import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_card.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class LatestFishStocksScreen extends StatefulWidget {
  const LatestFishStocksScreen({super.key});

  @override
  State<LatestFishStocksScreen> createState() =>
      _LatestFishStocksScreenState();
}

class _LatestFishStocksScreenState
    extends State<LatestFishStocksScreen> {
  final HomeStockService stockService = const HomeStockService();
  final TextEditingController searchController = TextEditingController();

  DateTime? sessionCutoff;
  String searchQuery = '';
  String selectedUnit = 'All';

  static const units = [
    'All',
    'Kilo',
    'Tab',
    'Icebox',
  ];

  @override
  void initState() {
    super.initState();
    loadFeedState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadFeedState() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    var cutoff = stockService.feedCutoff(null);

    if (userId.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        cutoff = stockService.feedCutoff(snapshot.data());
      } catch (_) {
        // Use the safe 48-hour fallback when the profile is unavailable.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      sessionCutoff = cutoff;
    });

    if (userId.isNotEmpty) {
      try {
        await stockService.markFishFeedViewed(userId);
      } catch (_) {
        // The listings remain usable and the seen marker can retry next time.
      }
    }
  }

  void openProductDetails({
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) {
    final data = document.data();
    final supplier = stockService.supplierForStock(data);

    if (supplier == null) {
      return;
    }

    final product = stockService.fishProductFromFirestore(data);
    final supplierId = OrderHelpers.getStringValue(
      data,
      'supplierId',
      '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          supplier: supplier,
          product: product,
          stockId: document.id,
          supplierId: supplierId,
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final available = stockService.availableStocks(documents);
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final normalizedUnit = selectedUnit.toLowerCase();

    return available.where((document) {
      final data = document.data();
      final quantityUnit = OrderHelpers.getStringValue(
        data,
        'quantityUnit',
        '',
      ).toLowerCase();

      if (normalizedUnit != 'all' && quantityUnit != normalizedUnit) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final searchableText = [
        OrderHelpers.getStringValue(data, 'productName', ''),
        OrderHelpers.getStringValue(data, 'category', ''),
        OrderHelpers.getStringValue(data, 'supplierName', ''),
        OrderHelpers.getStringValue(data, 'supplierLocation', ''),
        OrderHelpers.getStringValue(data, 'location', ''),
        quantityUnit,
      ].join(' ').toLowerCase();

      return searchableText.contains(normalizedQuery);
    }).toList();
  }

  Widget filterChip(String label) {
    final selected = selectedUnit == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? Colors.white
            : Colors.white.withAlpha(32),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: () {
            setState(() {
              selectedUnit = label;
            });
          },
          borderRadius: BorderRadius.circular(99),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withAlpha(65),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF0A73D8)
                    : Colors.white,
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget header({
    required int availableCount,
    required int unseenCount,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF075A94),
            Color(0xFF0875D1),
            Color(0xFF14B8D4),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 43,
                    height: 43,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VENDOR MARKETPLACE',
                      style: TextStyle(
                        color: Color(0xFFBFEAFF),
                        fontSize: 8.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Latest Fish Stocks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(28),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withAlpha(50),
                  ),
                ),
                child: Text(
                  '$availableCount available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  unseenCount > 0
                      ? '$unseenCount new or restocked since your last visit.'
                      : 'Newest available supplier listings appear first.',
                  style: const TextStyle(
                    color: Color(0xFFE0F5FF),
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF38D39F).withAlpha(40),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFB8FFE6),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Newest first',
                      style: TextStyle(
                        color: Color(0xFFB8FFE6),
                        fontSize: 8.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search fish, supplier, or Caraga location',
              hintStyle: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0875D1),
                size: 20,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF7B8FA3),
                        size: 18,
                      ),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 35,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: units.map(filterChip).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState({
    required bool hasAvailableStocks,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0EBF2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.set_meal_outlined,
                color: Color(0xFF0875D1),
                size: 40,
              ),
              const SizedBox(height: 11),
              Text(
                hasAvailableStocks
                    ? 'No matching fish stocks'
                    : 'No available fish stocks yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hasAvailableStocks
                    ? 'Try another fish, supplier, location, or selling unit.'
                    : 'New supplier listings will appear here automatically.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget stockGrid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: const SupplierBrowseService().suppliersStream,
      builder: (context, supplierSnapshot) {
        final supplierImageUrlsById = stockService.supplierImageUrlsById(
          supplierSnapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
          itemCount: documents.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 12,
            childAspectRatio: 1.02,
          ),
          itemBuilder: (context, index) {
            final document = documents[index];
            final data = document.data();
            final supplier = stockService.supplierForStock(data);
            final product = stockService.fishProductFromFirestore(data);

            return RecentFishCard(
              product: product,
              supplierName: supplier?.name ?? 'Verified Supplier',
              supplierImageUrl: stockService.supplierImageUrlForStock(
                data,
                supplierImageUrlsById,
              ),
              badgeLabel: stockService.arrivalBadge(data),
              activityLabel: stockService.activityLabel(data),
              showActivityTime: true,
              onTap: () => openProductDetails(document: document),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = sessionCutoff ?? stockService.feedCutoff(null);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stockService.allFishPostsStream,
        builder: (context, snapshot) {
          final allDocuments = snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final availableDocuments = stockService.availableStocks(
            allDocuments,
          );
          final visibleDocuments = filteredStocks(allDocuments);
          final unseenCount = stockService.unseenArrivalCount(
            allDocuments,
            cutoff,
          );

          return Column(
            children: [
              header(
                availableCount: availableDocuments.length,
                unseenCount: unseenCount,
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to load the latest fish stocks.',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (visibleDocuments.isEmpty) {
                      return emptyState(
                        hasAvailableStocks: availableDocuments.isNotEmpty,
                      );
                    }

                    return stockGrid(visibleDocuments);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
