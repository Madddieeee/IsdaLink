import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_card.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/app_error_message.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/search_matcher.dart';

enum _FishStockSortOption {
  newest,
  priceLowHigh,
  priceHighLow,
  mostStock,
  fishName,
}

class LatestFishStocksScreen extends StatefulWidget {
  const LatestFishStocksScreen({super.key});

  @override
  State<LatestFishStocksScreen> createState() =>
      _LatestFishStocksScreenState();
}

class _LatestFishStocksScreenState extends State<LatestFishStocksScreen> {
  final HomeStockService stockService = const HomeStockService();
  final SupplierBrowseService supplierService = const SupplierBrowseService();
  final TextEditingController searchController = TextEditingController();

  DateTime? sessionCutoff;
  String searchQuery = '';
  String selectedUnit = 'All';
  _FishStockSortOption sortOption = _FishStockSortOption.newest;

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
        // Use the safe fallback when the profile is unavailable.
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
        // The marketplace remains usable if the seen marker cannot update.
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

  Set<String> approvedSupplierIds(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> suppliers,
  ) {
    final ids = <String>{};

    for (final supplier in suppliers) {
      ids.add(supplier.id);
      final data = supplier.data();

      for (final key in const ['supplierId', 'userId', 'uid']) {
        final value = OrderHelpers.getStringValue(data, key, '');
        if (value.isNotEmpty) {
          ids.add(value);
        }
      }
    }

    return ids;
  }

  bool belongsToApprovedSupplier(
    QueryDocumentSnapshot<Map<String, dynamic>> stock,
    Set<String> approvedIds,
  ) {
    final data = stock.data();

    for (final key in const ['supplierId', 'userId', 'uid']) {
      final value = OrderHelpers.getStringValue(data, key, '');
      if (value.isNotEmpty && approvedIds.contains(value)) {
        return true;
      }
    }

    return false;
  }

  String normalizedUnitLabel(String value) {
    final unit = value.trim().toLowerCase();

    if (unit == 'kg' ||
        unit == 'kgs' ||
        unit == 'kilo' ||
        unit == 'kilos' ||
        unit == 'kilogram' ||
        unit == 'kilograms') {
      return 'Kilo';
    }

    if (unit == 'tab' || unit == 'tabs') {
      return 'Tab';
    }

    if (unit == 'ice box' ||
        unit == 'ice boxes' ||
        unit == 'icebox' ||
        unit == 'iceboxes') {
      return 'Icebox';
    }

    return value.trim();
  }

  List<String> searchableValues(Map<String, dynamic> data) {
    return [
      OrderHelpers.getStringValue(data, 'productName', ''),
      OrderHelpers.getStringValue(data, 'fishName', ''),
      OrderHelpers.getStringValue(data, 'category', ''),
      OrderHelpers.getStringValue(data, 'supplierName', ''),
      OrderHelpers.getStringValue(data, 'supplierLocation', ''),
      OrderHelpers.getStringValue(data, 'location', ''),
      OrderHelpers.getStringValue(data, 'serviceArea', ''),
      OrderHelpers.getStringValue(data, 'quantityUnit', ''),
    ];
  }

  int compareLatest(
    QueryDocumentSnapshot<Map<String, dynamic>> first,
    QueryDocumentSnapshot<Map<String, dynamic>> second,
  ) {
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final query = searchQuery.trim();
    final selectedUnitLabel = selectedUnit;
    final filtered = documents.where((document) {
      final data = document.data();
      final unit = normalizedUnitLabel(
        OrderHelpers.getStringValue(data, 'quantityUnit', ''),
      );

      if (selectedUnitLabel != 'All' && unit != selectedUnitLabel) {
        return false;
      }

      return SearchMatcher.matches(
        query: query,
        values: searchableValues(data),
      );
    }).toList();

    filtered.sort((first, second) {
      if (query.isNotEmpty) {
        final relevanceComparison = SearchMatcher.relevance(
          query: query,
          values: searchableValues(first.data()),
        ).compareTo(
          SearchMatcher.relevance(
            query: query,
            values: searchableValues(second.data()),
          ),
        );

        if (relevanceComparison != 0) {
          return relevanceComparison;
        }
      }

      final firstProduct = stockService.fishProductFromFirestore(first.data());
      final secondProduct = stockService.fishProductFromFirestore(second.data());

      return switch (sortOption) {
        _FishStockSortOption.newest => compareLatest(first, second),
        _FishStockSortOption.priceLowHigh =>
          firstProduct.price.compareTo(secondProduct.price),
        _FishStockSortOption.priceHighLow =>
          secondProduct.price.compareTo(firstProduct.price),
        _FishStockSortOption.mostStock => secondProduct.availableQuantity
            .compareTo(firstProduct.availableQuantity),
        _FishStockSortOption.fishName => firstProduct.name
            .toLowerCase()
            .compareTo(secondProduct.name.toLowerCase()),
      };
    });

    return filtered;
  }

  String get sortLabel {
    return switch (sortOption) {
      _FishStockSortOption.newest => 'Newest',
      _FishStockSortOption.priceLowHigh => 'Price: low to high',
      _FishStockSortOption.priceHighLow => 'Price: high to low',
      _FishStockSortOption.mostStock => 'Most stock',
      _FishStockSortOption.fishName => 'Fish name',
    };
  }

  IconData get sortIcon {
    return switch (sortOption) {
      _FishStockSortOption.newest => Icons.schedule_rounded,
      _FishStockSortOption.priceLowHigh => Icons.south_rounded,
      _FishStockSortOption.priceHighLow => Icons.north_rounded,
      _FishStockSortOption.mostStock => Icons.inventory_2_rounded,
      _FishStockSortOption.fishName => Icons.sort_by_alpha_rounded,
    };
  }

  Future<void> showSortSheet() async {
    final selected = await showModalBottomSheet<_FishStockSortOption>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(150),
      builder: (sheetContext) {
        Widget option({
          required _FishStockSortOption value,
          required IconData icon,
          required String title,
          required String subtitle,
        }) {
          final isSelected = sortOption == value;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(sheetContext, value),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEAF7FC)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF9EDAF1)
                        : const Color(0xFFE3EDF3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF087AC0).withAlpha(18)
                            : const Color(0xFFF2F6F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 19,
                        color: isSelected
                            ? const Color(0xFF087AC0)
                            : const Color(0xFF6F8798),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 12.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFF748A9B),
                              fontSize: 9.4,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF159C74),
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBED0DC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort fish stocks',
                          style: TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Choose how marketplace listings are ordered.',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              option(
                value: _FishStockSortOption.newest,
                icon: Icons.schedule_rounded,
                title: 'Newest',
                subtitle: 'Recently posted or restocked listings first.',
              ),
              const SizedBox(height: 7),
              option(
                value: _FishStockSortOption.priceLowHigh,
                icon: Icons.south_rounded,
                title: 'Price: low to high',
                subtitle: 'Lower listed prices appear first.',
              ),
              const SizedBox(height: 7),
              option(
                value: _FishStockSortOption.priceHighLow,
                icon: Icons.north_rounded,
                title: 'Price: high to low',
                subtitle: 'Higher listed prices appear first.',
              ),
              const SizedBox(height: 7),
              option(
                value: _FishStockSortOption.mostStock,
                icon: Icons.inventory_2_rounded,
                title: 'Most stock available',
                subtitle: 'Listings with more available quantity first.',
              ),
              const SizedBox(height: 7),
              option(
                value: _FishStockSortOption.fishName,
                icon: Icons.sort_by_alpha_rounded,
                title: 'Fish name',
                subtitle: 'Browse listings alphabetically by fish name.',
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      sortOption = selected;
    });
  }

  Widget metric({
    required String value,
    required String label,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withAlpha(28)),
          ),
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: accent.withAlpha(32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD8ECF4),
                        fontSize: 8.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget header({
    required int availableCount,
    required int activeSupplierCount,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.paddingOf(context).top + 12,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06355F),
            Color(0xFF0875D1),
            Color(0xFF12B6D6),
          ],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 48,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withAlpha(28),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 21,
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
                          'Fish Stocks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Fresh available listings across Caraga',
                          style: TextStyle(
                            color: Color(0xFFD9F0F6),
                            fontSize: 9.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFE6FAFC),
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Caraga',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE0EDF4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18002A47),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF8FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF087AC0),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.center,
                        cursorColor: const Color(0xFF087AC0),
                        cursorHeight: 18,
                        style: const TextStyle(
                          color: Color(0xFF18374E),
                          fontSize: 11.8,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search fish, supplier, or location',
                          hintStyle: const TextStyle(
                            color: Color(0xFF8296A6),
                            fontSize: 11.5,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixIcon: searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF7990A0),
                                    size: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  metric(
                    value: '$availableCount',
                    label: 'Fish stocks',
                    icon: Icons.inventory_2_outlined,
                    accent: const Color(0xFF8BE3FF),
                  ),
                  metric(
                    value: '$activeSupplierCount',
                    label: 'Suppliers',
                    icon: Icons.storefront_outlined,
                    accent: const Color(0xFF8BE3FF),
                  ),
                  metric(
                    value: 'COD',
                    label: 'Payment',
                    icon: Icons.payments_outlined,
                    accent: const Color(0xFFFFD867),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget unitSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8EF)),
      ),
      child: Row(
        children: units.map((label) {
          final selected = selectedUnit == label;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedUnit = label;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: const Color(0xFFD7E7F0))
                        : null,
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x1000152A),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label == 'All' ? 'All units' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF087AC0)
                          : const Color(0xFF71889A),
                      fontSize: 9.7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget sectionHeader({
    required int visibleCount,
    required int totalCount,
    required int unseenCount,
  }) {
    final query = searchQuery.trim();
    final title = query.isEmpty
        ? 'Available Fish Stocks'
        : 'Results for “$query”';
    final subtitle = query.isEmpty
        ? '$totalCount available listing${totalCount == 1 ? '' : 's'} from verified suppliers across Caraga.'
        : '$visibleCount matching listing${visibleCount == 1 ? '' : 's'} found.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          unitSelector(),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7C91A2),
                        fontSize: 9.7,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (query.isEmpty && unseenCount > 0) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.fiber_new_rounded,
                            color: Color(0xFF0A8FD8),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$unseenCount new or restocked since your last visit',
                            style: const TextStyle(
                              color: Color(0xFF087AC0),
                              fontSize: 8.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: showSortSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF8FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCDE8F3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sortIcon,
                          color: const Color(0xFF087AC0),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 92),
                          child: Text(
                            sortLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF087AC0),
                              fontSize: 8.7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF087AC0),
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emptyState({
    required bool hasAvailableStocks,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0EBF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B00152A),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF7FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.set_meal_outlined,
                color: Color(0xFF087AC0),
                size: 28,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              hasAvailableStocks
                  ? 'No matching fish stocks found'
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
                  : 'Fresh listings from verified suppliers will appear here automatically.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 10.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget loadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 12,
        childAspectRatio: 1.02,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFE1EBF1)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9F1F5),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 9,
                      width: 78,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4ECF1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 8,
                      width: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 7,
                      width: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget stockGrid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    Map<String, String> supplierImageUrlsById,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
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
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = sessionCutoff ?? stockService.feedCutoff(null);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: supplierService.suppliersStream,
        builder: (context, supplierSnapshot) {
          if (supplierSnapshot.hasError) {
            return Column(
              children: [
                header(availableCount: 0, activeSupplierCount: 0),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        AppErrorMessage.from(
                          supplierSnapshot.error!,
                          fallback:
                              'The fish marketplace could not be loaded. Please try again.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF60798B),
                          fontSize: 11,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final supplierDocuments = supplierSnapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final approvedIds = approvedSupplierIds(supplierDocuments);
          final supplierImageUrlsById =
              stockService.supplierImageUrlsById(supplierDocuments);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stockService.allFishPostsStream,
            builder: (context, stockSnapshot) {
              final allDocuments = stockSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final availableDocuments = stockService
                  .availableStocks(allDocuments)
                  .where(
                    (stock) => belongsToApprovedSupplier(stock, approvedIds),
                  )
                  .toList();
              final visibleDocuments = filteredStocks(availableDocuments);
              final unseenCount = stockService.unseenArrivalCount(
                availableDocuments,
                cutoff,
              );
              final activeSupplierIds = <String>{};

              for (final stock in availableDocuments) {
                final supplierId = OrderHelpers.getStringValue(
                  stock.data(),
                  'supplierId',
                  '',
                );
                if (supplierId.isNotEmpty) {
                  activeSupplierIds.add(supplierId);
                }
              }

              return Column(
                children: [
                  header(
                    availableCount: availableDocuments.length,
                    activeSupplierCount: activeSupplierIds.length,
                  ),
                  if (stockSnapshot.hasData)
                    sectionHeader(
                      visibleCount: visibleDocuments.length,
                      totalCount: availableDocuments.length,
                      unseenCount: unseenCount,
                    ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (stockSnapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Text(
                                AppErrorMessage.from(
                                  stockSnapshot.error!,
                                  fallback:
                                      'The latest fish stocks could not be loaded. Please try again.',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF60798B),
                                  fontSize: 11,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }

                        if (!stockSnapshot.hasData ||
                            !supplierSnapshot.hasData) {
                          return loadingSkeleton();
                        }

                        if (visibleDocuments.isEmpty) {
                          return ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              emptyState(
                                hasAvailableStocks:
                                    availableDocuments.isNotEmpty,
                              ),
                            ],
                          );
                        }

                        return stockGrid(
                          visibleDocuments,
                          supplierImageUrlsById,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
