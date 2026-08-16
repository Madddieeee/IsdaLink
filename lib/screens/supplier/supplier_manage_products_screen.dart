import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_product_card.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_product_dialogs.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_products_header.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_products_status_cards.dart';
import 'package:isdalink/screens/supplier/post_fish_stock_screen.dart';
import 'package:isdalink/services/supplier_product_service.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_state.dart';

enum ManageProductFilter {
  all,
  available,
  lowStock,
  outOfStock,
  hidden,
}

class SupplierManageProductsScreen extends StatefulWidget {
  const SupplierManageProductsScreen({
    super.key,
  });

  @override
  State<SupplierManageProductsScreen> createState() =>
      _SupplierManageProductsScreenState();
}

class _SupplierManageProductsScreenState
    extends State<SupplierManageProductsScreen> {
  final searchController = TextEditingController();
  final productService = const SupplierProductService();
  final busyProductIds = <String>{};

  ManageProductFilter selectedFilter =
      ManageProductFilter.all;
  int streamRevision = 0;

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    searchController.addListener(
      refreshSearch,
    );
  }

  @override
  void dispose() {
    searchController.removeListener(
      refreshSearch,
    );
    searchController.dispose();
    super.dispose();
  }

  void refreshSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  String firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  bool isHidden(
    Map<String, dynamic> data,
  ) {
    return StockState.isIntentionallyHidden(data);
  }

  String filterStatus(
    Map<String, dynamic> data,
  ) {
    if (isHidden(data)) {
      return 'hidden';
    }

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );
    final lowStockLevel = OrderHelpers.getDoubleValue(
      data,
      'lowStockLevel',
    );

    if (quantity <= 0) {
      return 'outOfStock';
    }

    if (quantity <= lowStockLevel) {
      return 'lowStock';
    }

    return 'available';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      filteredDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  ) {
    final query =
        searchController.text.trim().toLowerCase();

    return documents.where(
      (
        document,
      ) {
        final data = document.data();
        final productName = OrderHelpers.getStringValue(
          data,
          'productName',
          'Fish Product',
        ).toLowerCase();
        final category = OrderHelpers.getStringValue(
          data,
          'category',
          'Fresh Fish',
        ).toLowerCase();
        final unit = OrderHelpers.getStringValue(
          data,
          'quantityUnit',
          'kilo',
        ).toLowerCase();

        final matchesSearch = query.isEmpty ||
            productName.contains(query) ||
            category.contains(query) ||
            unit.contains(query);

        if (!matchesSearch) {
          return false;
        }

        final status = filterStatus(data);

        return switch (selectedFilter) {
          ManageProductFilter.all => true,
          ManageProductFilter.available =>
            status == 'available',
          ManageProductFilter.lowStock =>
            status == 'lowStock',
          ManageProductFilter.outOfStock =>
            status == 'outOfStock',
          ManageProductFilter.hidden =>
            status == 'hidden',
        };
      },
    ).toList();
  }

  void setBusy(
    String documentId,
    bool busy,
  ) {
    setState(() {
      if (busy) {
        busyProductIds.add(documentId);
      } else {
        busyProductIds.remove(documentId);
      }
    });
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          backgroundColor: isError
              ? const Color(0xFFD94A45)
              : const Color(0xFF147D64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> editProduct(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) async {
    final input =
        await ManageProductDialogs.showEditSheet(
      context: context,
      document: document,
    );

    if (!mounted || input == null) {
      return;
    }

    setBusy(
      document.id,
      true,
    );

    try {
      await productService.updateProduct(
        documentId: document.id,
        input: input,
      );

      showMessage(
        'Product changes saved successfully.',
      );
    } on FirebaseException {
      showMessage(
        'Unable to save the product changes. Please try again.',
        isError: true,
      );
    } catch (_) {
      showMessage(
        'Something went wrong while updating this product.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setBusy(
          document.id,
          false,
        );
      }
    }
  }

  Future<void> toggleAvailability(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) async {
    final data = document.data();
    final productName = OrderHelpers.getStringValue(
      data,
      'productName',
      'Fish Product',
    );
    final currentlyHidden = isHidden(data);

    final confirmed =
        await ManageProductDialogs.showAvailabilityDialog(
      context: context,
      productName: productName,
      currentlyHidden: currentlyHidden,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setBusy(
      document.id,
      true,
    );

    try {
      final newStatus =
          await productService.toggleAvailability(
        documentId: document.id,
      );

      showMessage(
        newStatus == 'available'
            ? '$productName is visible to vendors again.'
            : '$productName is now hidden from vendors.',
      );
    } on FirebaseException {
      showMessage(
        'Unable to change product visibility. Please try again.',
        isError: true,
      );
    } catch (_) {
      showMessage(
        'Something went wrong while changing visibility.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setBusy(
          document.id,
          false,
        );
      }
    }
  }

  Future<void> archiveProduct(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) async {
    final productName = OrderHelpers.getStringValue(
      document.data(),
      'productName',
      'Fish Product',
    );

    final confirmed =
        await ManageProductDialogs.showArchiveDialog(
      context: context,
      productName: productName,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setBusy(
      document.id,
      true,
    );

    try {
      await productService.archiveProduct(
        document.id,
      );

      showMessage(
        '$productName was archived and hidden from vendors.',
      );
    } on FirebaseException {
      showMessage(
        'Unable to archive this product. Please try again.',
        isError: true,
      );
    } catch (_) {
      showMessage(
        'Something went wrong while archiving this product.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setBusy(
          document.id,
          false,
        );
      }
    }
  }

  void openPostStock() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (
          context,
        ) {
          return const PostFishStockScreen();
        },
      ),
    );
  }

  void clearSearchAndFilters() {
    searchController.clear();

    setState(() {
      selectedFilter = ManageProductFilter.all;
    });
  }

  String filterLabel(
    ManageProductFilter filter,
  ) {
    return switch (filter) {
      ManageProductFilter.all => 'All',
      ManageProductFilter.available => 'Available',
      ManageProductFilter.lowStock => 'Low Stock',
      ManageProductFilter.outOfStock => 'Out of Stock',
      ManageProductFilter.hidden => 'Hidden',
    };
  }

  IconData filterIcon(
    ManageProductFilter filter,
  ) {
    return switch (filter) {
      ManageProductFilter.all =>
        Icons.inventory_2_outlined,
      ManageProductFilter.available =>
        Icons.check_circle_outline_rounded,
      ManageProductFilter.lowStock =>
        Icons.warning_amber_rounded,
      ManageProductFilter.outOfStock =>
        Icons.remove_shopping_cart_outlined,
      ManageProductFilter.hidden =>
        Icons.visibility_off_outlined,
    };
  }

  Widget controlsCard() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D00152A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search product, category, or unit',
              hintStyle: const TextStyle(
                color: Color(0xFF8BA0B1),
                fontSize: 11.2,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF146BFF),
              ),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: searchController.clear,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF2F7FB),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFFE1EBF2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFF146BFF),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ManageProductFilter.values.length,
              separatorBuilder: (
                context,
                index,
              ) {
                return const SizedBox(width: 7);
              },
              itemBuilder: (
                context,
                index,
              ) {
                final filter =
                    ManageProductFilter.values[index];
                final selected =
                    selectedFilter == filter;

                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    filterIcon(filter),
                    size: 16,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF52677A),
                  ),
                  label: Text(
                    filterLabel(filter),
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF52677A),
                      fontSize: 9.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onSelected: (
                    _,
                  ) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  backgroundColor:
                      const Color(0xFFF2F7FB),
                  selectedColor:
                      const Color(0xFF146BFF),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF146BFF)
                        : const Color(0xFFDCE7EF),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget listingTitle(
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2,
        0,
        2,
        12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Product Listings',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Only inventory owned by this supplier account is shown.',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
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
              color: const Color(0xFFEAF7FB),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count ${count == 1 ? 'listing' : 'listings'}',
              style: const TextStyle(
                color: Color(0xFF146BFF),
                fontSize: 8.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget content({
    required List<
        QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  }) {
    final stats = productService.calculateStats(
      documents,
    );
    final visibleDocuments = filteredDocuments(
      documents,
    );

    return CustomScrollView(
      key: ValueKey(
        'manage-products-$streamRevision',
      ),
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        ManageProductsHeader(
          stats: stats,
          onBack: () {
            Navigator.pop(context);
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                controlsCard(),
                listingTitle(
                  visibleDocuments.length,
                ),
                if (documents.isEmpty)
                  ManageProductsEmptyCard(
                    onPostStock: openPostStock,
                  )
                else if (visibleDocuments.isEmpty)
                  ManageProductsFilteredEmptyCard(
                    onClear: clearSearchAndFilters,
                  )
                else
                  ...visibleDocuments.map(
                    (
                      document,
                    ) {
                      return ManageProductCard(
                        document: document,
                        isBusy: busyProductIds.contains(
                          document.id,
                        ),
                        onEdit: () {
                          editProduct(document);
                        },
                        onToggleAvailability: () {
                          toggleAvailability(document);
                        },
                        onArchive: () {
                          archiveProduct(document);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget loadingBody() {
    const emptyStats = SupplierProductStats(
      totalProducts: 0,
      activeProducts: 0,
      stockAlertCount: 0,
      hiddenCount: 0,
    );

    return CustomScrollView(
      slivers: [
        ManageProductsHeader(
          stats: emptyStats,
          onBack: () {
            Navigator.pop(context);
          },
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            18,
            16,
            28,
          ),
          sliver: SliverToBoxAdapter(
            child: ManageProductsLoadingCard(),
          ),
        ),
      ],
    );
  }

  Widget errorBody() {
    const emptyStats = SupplierProductStats(
      totalProducts: 0,
      activeProducts: 0,
      stockAlertCount: 0,
      hiddenCount: 0,
    );

    return CustomScrollView(
      slivers: [
        ManageProductsHeader(
          stats: emptyStats,
          onBack: () {
            Navigator.pop(context);
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            28,
          ),
          sliver: SliverToBoxAdapter(
            child: ManageProductsErrorCard(
              onRetry: () {
                setState(() {
                  streamRevision++;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget notLoggedInBody() {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F8FB),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Please log in first to manage supplier products.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD94A45),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user == null) {
      return notLoggedInBody();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey(streamRevision),
          stream: productService.fishStocksStream(
            user.uid,
          ),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.hasError) {
              return errorBody();
            }

            if (!snapshot.hasData) {
              return loadingBody();
            }

            final documents = productService.sortStocks(
              snapshot.data!.docs,
            );

            return content(
              documents: documents,
            );
          },
        ),
      ),
    );
  }
}
