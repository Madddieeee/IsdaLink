import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_header.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_status_cards.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_product_card.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_reviews_section.dart';
import 'package:isdalink/services/supplier_details_service.dart';

class SupplierDetailsScreen extends StatefulWidget {
  const SupplierDetailsScreen({
    super.key,
    required this.supplier,
    this.supplierId,
  });

  final Supplier supplier;
  final String? supplierId;

  @override
  State<SupplierDetailsScreen> createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  final SupplierDetailsService detailsService =
      const SupplierDetailsService();

  final TextEditingController searchController =
      TextEditingController();

  String searchQuery = '';
  String selectedUnit = 'all';
  String sortMode = 'latest';
  int selectedTab = 0;

  Supplier get supplier => widget.supplier;
  String? get supplierId => widget.supplierId;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final product = detailsService.fishProductFromFirestore(data);

    final stockSupplierId = detailsService.getStringValue(
      data,
      'supplierId',
      supplierId ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          supplier: supplier,
          product: product,
          stockId: document.id,
          supplierId: stockSupplierId,
        ),
      ),
    );
  }

  String sortLabel(
    String value,
  ) {
    switch (value) {
      case 'price_low':
        return 'Price: low to high';
      case 'price_high':
        return 'Price: high to low';
      case 'name':
        return 'Fish name';
      case 'latest':
      default:
        return 'Latest posts';
    }
  }

  Widget storeTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: storeTabButton(
                label: 'Fish Listings',
                icon: Icons.set_meal_outlined,
                index: 0,
              ),
            ),
            Expanded(
              child: storeTabButton(
                label: 'Store Reviews',
                icon: Icons.star_outline_rounded,
                index: 1,
                count: supplier.reviews,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget storeTabButton({
    required String label,
    required IconData icon,
    required int index,
    int? count,
  }) {
    final selected = selectedTab == index;

    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(13),
        child: Container(
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? const Color(0xFF087AC0)
                    : const Color(0xFF7B8FA3),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  count == null ? label : '$label ($count)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF102C44)
                        : const Color(0xFF7B8FA3),
                    fontSize: 11.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget searchAndFilterCard(
    List<String> units,
  ) {
    final unitOptions = ['all', ...units];

    if (!unitOptions.contains(selectedUnit)) {
      selectedUnit = 'all';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE0EEF5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search fish in this store',
              hintStyle: const TextStyle(
                color: Color(0xFF9AAEBD),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF6E90A6),
              ),
              suffixIcon: searchQuery.trim().isEmpty
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
                        size: 19,
                        color: Color(0xFF7B8FA3),
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFFE1EEF6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFF16A9D1),
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: unitOptions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final unit = unitOptions[index];
                      final selected = selectedUnit == unit;

                      return ChoiceChip(
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            selectedUnit = unit;
                          });
                        },
                        label: Text(
                          unit == 'all'
                              ? 'All units'
                              : unit[0].toUpperCase() +
                                  unit.substring(1),
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF52677A),
                          fontSize: 10.2,
                          fontWeight: FontWeight.w900,
                        ),
                        selectedColor: const Color(0xFF087AC0),
                        backgroundColor: const Color(0xFFF0F6FA),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF087AC0)
                              : const Color(0xFFE0EEF5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: sortMode,
                onSelected: (value) {
                  setState(() {
                    sortMode = value;
                  });
                },
                tooltip: 'Sort fish listings',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'latest',
                      child: Text('Latest posts'),
                    ),
                    PopupMenuItem(
                      value: 'price_low',
                      child: Text('Price: low to high'),
                    ),
                    PopupMenuItem(
                      value: 'price_high',
                      child: Text('Price: high to low'),
                    ),
                    PopupMenuItem(
                      value: 'name',
                      child: Text('Fish name'),
                    ),
                  ];
                },
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD5EEF7),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swap_vert_rounded,
                        color: Color(0xFF087AC0),
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sort',
                        style: const TextStyle(
                          color: Color(0xFF087AC0),
                          fontSize: 10.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget productGrid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 360 ? 1 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: columns == 1 ? 226 : 236,
      ),
      itemBuilder: (context, index) {
        final document = documents[index];
        final data = document.data();

        final productName = detailsService.getStringValue(
          data,
          'productName',
          'Fish Product',
        );

        final category = detailsService.getStringValue(
          data,
          'category',
          'Fresh Fish',
        );

        final emoji = detailsService.getStringValue(
          data,
          'emoji',
          '🐟',
        );

        final imageUrl = detailsService.productImageUrl(data);
        final price = detailsService.getDoubleValue(data, 'price');

        final priceUnit = detailsService.getStringValue(
          data,
          'priceUnit',
          'per kilo',
        );

        final quantity = detailsService.getDoubleValue(data, 'quantity');

        final quantityUnit = detailsService.getStringValue(
          data,
          'quantityUnit',
          'kilo',
        );

        final lowStockLevel = detailsService.getDoubleValue(
          data,
          'lowStockLevel',
        );

        final stockColor = detailsService.getStockColor(
          quantity: quantity,
          lowStockLevel: lowStockLevel,
        );

        final stockStatus = detailsService.getStockStatus(
          quantity: quantity,
          lowStockLevel: lowStockLevel,
        );

        return SupplierProductCard(
          productName: productName,
          category: category,
          emoji: emoji,
          imageUrl: imageUrl,
          price: price,
          priceUnit: priceUnit,
          quantity: quantity,
          quantityUnit: quantityUnit,
          stockColor: stockColor,
          stockStatus: stockStatus,
          onTap: () => openProduct(document),
        );
      },
    );
  }

  Widget productsBody({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) {
    final orderable = detailsService.orderableStocks(documents);
    final units = detailsService.availableUnits(orderable);

    final visibleProducts = detailsService.filterAndSortProducts(
      documents: orderable,
      query: searchQuery,
      selectedUnit: selectedUnit,
      sortMode: sortMode,
    );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        searchAndFilterCard(units),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Available Fish',
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8FD),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${visibleProducts.length} listing'
                '${visibleProducts.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF087AC0),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sortLabel(sortMode),
          style: const TextStyle(
            color: Color(0xFF7B8FA3),
            fontSize: 10.7,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (orderable.isEmpty)
          const SupplierDetailsEmptyCard(
            title: 'No fish available right now',
            subtitle:
                'This supplier has no active fish stock for ordering at the moment.',
          )
        else if (visibleProducts.isEmpty)
          const SupplierDetailsEmptyCard(
            title: 'No matching fish found',
            subtitle:
                'Try another fish name or change the selected unit filter.',
            icon: Icons.search_off_rounded,
          )
        else
          productGrid(visibleProducts),
      ],
    );
  }

  Widget reviewsBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        SupplierReviewsSection(
          supplierId: supplierId,
          supplierName: supplier.name,
        ),
      ],
    );
  }

  Widget loadedBody(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocuments,
  ) {
    final documents = detailsService.filterSupplierStocks(
      documents: allDocuments,
      supplier: supplier,
      supplierId: supplierId,
    );

    final stats = detailsService.calculateStats(documents);

    return Column(
      children: [
        SupplierDetailsHeader(
          supplier: supplier,
          stats: stats,
          onBack: () => Navigator.pop(context),
        ),
        storeTabs(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: selectedTab == 0
                ? KeyedSubtree(
                    key: const ValueKey('products'),
                    child: productsBody(documents: documents),
                  )
                : KeyedSubtree(
                    key: const ValueKey('reviews'),
                    child: reviewsBody(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget loadingBody() {
    final stats = detailsService.calculateStats(const []);

    return Column(
      children: [
        SupplierDetailsHeader(
          supplier: supplier,
          stats: stats,
          onBack: () => Navigator.pop(context),
        ),
        storeTabs(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              const SupplierDetailsLoadingCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorBody() {
    final stats = detailsService.calculateStats(const []);

    return Column(
      children: [
        SupplierDetailsHeader(
          supplier: supplier,
          stats: stats,
          onBack: () => Navigator.pop(context),
        ),
        storeTabs(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              const SupplierDetailsErrorCard(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: detailsService.fishStocksStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return errorBody();
          }

          if (!snapshot.hasData) {
            return loadingBody();
          }

          return loadedBody(snapshot.data!.docs);
        },
      ),
    );
  }
}
