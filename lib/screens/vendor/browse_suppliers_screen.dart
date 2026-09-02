import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_header.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_status_cards.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/supplier_profile_card.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

enum _SupplierSortOption {
  recommended,
  newest,
  highestRated,
  mostAvailable,
}

class BrowseSuppliersScreen extends StatefulWidget {
  const BrowseSuppliersScreen({
    super.key,
  });

  @override
  State<BrowseSuppliersScreen> createState() => _BrowseSuppliersScreenState();
}

class _BrowseSuppliersScreenState extends State<BrowseSuppliersScreen> {
  final searchController = TextEditingController();

  final SupplierBrowseService supplierService = const SupplierBrowseService();
  final FavoriteSupplierService favoriteService = FavoriteSupplierService();
  final HomeStockService stockService = const HomeStockService();

  String searchQuery = '';
  bool showFavoritesOnly = false;
  String? favoriteActionSupplierId;
  _SupplierSortOption sortOption = _SupplierSortOption.recommended;

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

  Future<void> toggleFavorite({
    required String supplierId,
    required bool currentlyFavorite,
  }) async {
    if (favoriteActionSupplierId != null) {
      return;
    }

    setState(() {
      favoriteActionSupplierId = supplierId;
    });

    try {
      await favoriteService.toggleFavorite(
        supplierId: supplierId,
        currentlyFavorite: currentlyFavorite,
      );

      if (!mounted) {
        return;
      }

      final added = !currentlyFavorite;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              added
                  ? 'Supplier added to Favorites.'
                  : 'Supplier removed from Favorites.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              AppErrorMessage.from(
                error,
                fallback: 'Favorite could not be updated. Please try again.',
                allowBusinessMessage: true,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          favoriteActionSupplierId = null;
        });
      }
    }
  }



  String get sortLabel {
    return switch (sortOption) {
      _SupplierSortOption.recommended => 'Recommended',
      _SupplierSortOption.newest => 'Newest',
      _SupplierSortOption.highestRated => 'Highest rated',
      _SupplierSortOption.mostAvailable => 'Most available',
    };
  }

  IconData get sortIcon {
    return switch (sortOption) {
      _SupplierSortOption.recommended => Icons.auto_awesome_rounded,
      _SupplierSortOption.newest => Icons.schedule_rounded,
      _SupplierSortOption.highestRated => Icons.star_rounded,
      _SupplierSortOption.mostAvailable => Icons.inventory_2_rounded,
    };
  }

  Future<void> showSortSheet() async {
    final selected = await showModalBottomSheet<_SupplierSortOption>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(150),
      builder: (sheetContext) {
        Widget option({
          required _SupplierSortOption value,
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
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEAF7FC) : Colors.white,
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
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: isSelected
                          ? const Color(0xFF11A87A)
                          : const Color(0xFFA3B3BE),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(top: 80),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
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
                  color: const Color(0xFFC4D3DD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort suppliers',
                          style: TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Choose how supplier stores are ordered.',
                          style: TextStyle(
                            color: Color(0xFF748A9B),
                            fontSize: 10.2,
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
                value: _SupplierSortOption.recommended,
                icon: Icons.auto_awesome_rounded,
                title: 'Recommended',
                subtitle: 'New suppliers first, then rating and reviews.',
              ),
              const SizedBox(height: 8),
              option(
                value: _SupplierSortOption.newest,
                icon: Icons.schedule_rounded,
                title: 'Newest',
                subtitle: 'Recently registered approved suppliers first.',
              ),
              const SizedBox(height: 8),
              option(
                value: _SupplierSortOption.highestRated,
                icon: Icons.star_rounded,
                title: 'Highest rated',
                subtitle: 'Higher store rating, then more reviews.',
              ),
              const SizedBox(height: 8),
              option(
                value: _SupplierSortOption.mostAvailable,
                icon: Icons.inventory_2_rounded,
                title: 'Most available',
                subtitle: 'Suppliers with more orderable fish listings first.',
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted || selected == sortOption) {
      return;
    }

    setState(() {
      sortOption = selected;
    });
  }

  Widget supplierModeSelector({
    required int favoriteCount,
  }) {
    Widget option({
      required bool selected,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 45,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x12002B4D),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
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
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF102C44)
                            : const Color(0xFF71889B),
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

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDCE8F0),
        ),
      ),
      child: Row(
        children: [
          option(
            selected: !showFavoritesOnly,
            icon: Icons.storefront_rounded,
            label: 'All Suppliers',
            onTap: () {
              if (showFavoritesOnly) {
                setState(() {
                  showFavoritesOnly = false;
                });
              }
            },
          ),
          const SizedBox(width: 4),
          option(
            selected: showFavoritesOnly,
            icon: showFavoritesOnly
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: 'Favorites ($favoriteCount)',
            onTap: () {
              if (!showFavoritesOnly) {
                setState(() {
                  showFavoritesOnly = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget favoritesEmptyBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFF087AC0),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorite suppliers yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF102C44),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Save suppliers you frequently buy from so you can return to their stores faster.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 17),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  showFavoritesOnly = false;
                });
              },
              icon: const Icon(
                Icons.storefront_rounded,
                size: 17,
              ),
              label: const Text('Browse Suppliers'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF087AC0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget supplierListBody({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stockDocuments,
    required Set<String> favoriteSupplierIds,
  }) {
    final approvedDocuments = supplierService.approvedSuppliers(documents);
    final approvedSupplierIds = approvedDocuments.map((document) => document.id).toSet();
    final activeFavoriteIds = favoriteSupplierIds.intersection(approvedSupplierIds);

    final availableStockDocuments = stockDocuments
        .where(stockService.isAvailableStock)
        .toList();

    final availableCountsBySupplier = <String, int>{};
    for (final stock in availableStockDocuments) {
      final data = stock.data();
      final supplierId = (data['supplierId'] ?? '').toString().trim();
      if (supplierId.isEmpty) {
        continue;
      }
      availableCountsBySupplier.update(
        supplierId,
        (currentCount) => currentCount + 1,
        ifAbsent: () => 1,
      );
    }

    final baseSearchedDocuments = supplierService.searchSuppliers(
      documents: approvedDocuments,
      query: searchQuery,
    );

    final normalizedQuery = searchQuery.trim().toLowerCase();
    final fishMatchedSupplierIds = <String>{};
    if (normalizedQuery.isNotEmpty) {
      for (final stock in availableStockDocuments) {
        final data = stock.data();
        final searchable = [
          data['productName'],
          data['fishName'],
          data['category'],
        ].whereType<Object>().map((value) => value.toString().toLowerCase()).join(' ');

        if (searchable.contains(normalizedQuery)) {
          final supplierId = (data['supplierId'] ?? '').toString().trim();
          if (supplierId.isNotEmpty) {
            fishMatchedSupplierIds.add(supplierId);
          }
        }
      }
    }

    final searchedIds = baseSearchedDocuments.map((document) => document.id).toSet();
    final searchedDocuments = normalizedQuery.isEmpty
        ? approvedDocuments
        : approvedDocuments.where((document) {
            return searchedIds.contains(document.id) ||
                fishMatchedSupplierIds.contains(document.id);
          }).toList();

    final filteredDocuments = showFavoritesOnly
        ? searchedDocuments
            .where((document) => activeFavoriteIds.contains(document.id))
            .toList()
        : searchedDocuments;

    final displayedDocuments = [...filteredDocuments];
    displayedDocuments.sort((first, second) {
      final firstSupplier = supplierService.supplierFromProfile(first.data());
      final secondSupplier = supplierService.supplierFromProfile(second.data());

      int nameFallback() => firstSupplier.name
          .toLowerCase()
          .compareTo(secondSupplier.name.toLowerCase());

      switch (sortOption) {
        case _SupplierSortOption.recommended:
          final firstIndex = approvedDocuments.indexWhere((item) => item.id == first.id);
          final secondIndex = approvedDocuments.indexWhere((item) => item.id == second.id);
          return firstIndex.compareTo(secondIndex);
        case _SupplierSortOption.newest:
          final firstDate = firstSupplier.accountCreatedAt;
          final secondDate = secondSupplier.accountCreatedAt;
          if (firstDate == null && secondDate == null) return nameFallback();
          if (firstDate == null) return 1;
          if (secondDate == null) return -1;
          final dateComparison = secondDate.compareTo(firstDate);
          return dateComparison != 0 ? dateComparison : nameFallback();
        case _SupplierSortOption.highestRated:
          final ratingComparison = secondSupplier.rating.compareTo(firstSupplier.rating);
          if (ratingComparison != 0) return ratingComparison;
          final reviewComparison = secondSupplier.reviews.compareTo(firstSupplier.reviews);
          return reviewComparison != 0 ? reviewComparison : nameFallback();
        case _SupplierSortOption.mostAvailable:
          final firstCount = availableCountsBySupplier[first.id] ?? 0;
          final secondCount = availableCountsBySupplier[second.id] ?? 0;
          final countComparison = secondCount.compareTo(firstCount);
          if (countComparison != 0) return countComparison;
          final ratingComparison = secondSupplier.rating.compareTo(firstSupplier.rating);
          return ratingComparison != 0 ? ratingComparison : nameFallback();
      }
    });

    if (approvedDocuments.isEmpty) {
      return const BrowseSuppliersEmptyBody(
        title: 'No supplier profiles yet',
        subtitle: 'Approved supplier stores will appear here when available.',
      );
    }

    if (showFavoritesOnly && activeFavoriteIds.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: supplierModeSelector(
              favoriteCount: activeFavoriteIds.length,
            ),
          ),
          Expanded(
            child: favoritesEmptyBody(),
          ),
        ],
      );
    }

    if (filteredDocuments.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: supplierModeSelector(
              favoriteCount: activeFavoriteIds.length,
            ),
          ),
          Expanded(
            child: BrowseSuppliersEmptyBody(
              title: showFavoritesOnly
                  ? 'No matching favorites found'
                  : 'No matching suppliers found',
              subtitle: showFavoritesOnly
                  ? 'Try another supplier name, fish, or location within your Favorites.'
                  : 'Try another supplier name, fish, or location.',
            ),
          ),
        ],
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      children: [
        supplierModeSelector(
          favoriteCount: activeFavoriteIds.length,
        ),
        const SizedBox(height: 17),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    normalizedQuery.isNotEmpty && fishMatchedSupplierIds.isNotEmpty
                        ? 'Suppliers selling “${searchQuery.trim()}”'
                        : normalizedQuery.isNotEmpty
                            ? 'Results for “${searchQuery.trim()}”'
                            : showFavoritesOnly
                                ? 'Favorite Suppliers'
                                : 'All Suppliers',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 18.2,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    normalizedQuery.isNotEmpty
                        ? '${displayedDocuments.length} matching supplier${displayedDocuments.length == 1 ? '' : 's'} found.'
                        : showFavoritesOnly
                            ? '${displayedDocuments.length} saved supplier${displayedDocuments.length == 1 ? '' : 's'} ready to revisit.'
                            : '${displayedDocuments.length} verified supplier${displayedDocuments.length == 1 ? '' : 's'} across Caraga.',
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: showSortSheet,
                borderRadius: BorderRadius.circular(13),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FC),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFCFE7F1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sortIcon, size: 14, color: const Color(0xFF087AC0)),
                      const SizedBox(width: 5),
                      Text(
                        sortLabel,
                        style: const TextStyle(
                          color: Color(0xFF087AC0),
                          fontSize: 8.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: Color(0xFF087AC0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...displayedDocuments.map((document) {
          final data = document.data();
          final supplier = supplierService.supplierFromProfile(data);
          final isFavorite = activeFavoriteIds.contains(document.id);
          final availableListingCount = availableCountsBySupplier[document.id] ?? 0;
          final currentUid = favoriteService.currentUserId?.trim() ?? '';
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
          final ownStore = currentUid.isNotEmpty && supplierIds.contains(currentUid);

          return SupplierProfileCard(
            supplier: supplier,
            availableListingCount: availableListingCount,
            isFavorite: isFavorite,
            favoriteBusy: favoriteActionSupplierId == document.id,
            showFavoriteAction: !ownStore,
            onFavoriteToggle: () => toggleFavorite(
              supplierId: document.id,
              currentlyFavorite: isFavorite,
            ),
            onTap: () => openSupplierDetails(
              context: context,
              supplierId: document.id,
              data: data,
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: supplierService.suppliersStream,
        builder: (context, supplierSnapshot) {
          final documents = supplierSnapshot.data?.docs ?? [];
          final approvedDocuments = supplierService.approvedSuppliers(documents);
          final approvedSupplierIds = approvedDocuments.map((document) => document.id).toSet();
          final approvedCount = approvedDocuments.length;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stockService.allFishPostsStream,
            builder: (context, stockSnapshot) {
              final stockDocuments = stockSnapshot.data?.docs ?? [];
              final availableStockCount = stockDocuments.where((document) {
                if (!stockService.isAvailableStock(document)) {
                  return false;
                }
                final supplierId =
                    (document.data()['supplierId'] ?? '').toString().trim();
                return approvedSupplierIds.contains(supplierId);
              }).length;

              return Column(
                children: [
                  BrowseSuppliersHeader(
                    approvedCount: approvedCount,
                    availableStockCount: availableStockCount,
                    searchController: searchController,
                    onSearchChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (supplierSnapshot.hasError) {
                          return BrowseSuppliersErrorBody(
                            error: supplierSnapshot.error!,
                          );
                        }

                        if (stockSnapshot.hasError) {
                          return BrowseSuppliersErrorBody(
                            error: stockSnapshot.error!,
                          );
                        }

                        if (!supplierSnapshot.hasData || !stockSnapshot.hasData) {
                          return const BrowseSuppliersLoadingBody();
                        }

                        return StreamBuilder<Set<String>>(
                          stream: favoriteService.favoriteSupplierIdsStream,
                          initialData: const <String>{},
                          builder: (context, favoriteSnapshot) {
                            if (favoriteSnapshot.hasError) {
                              return BrowseSuppliersErrorBody(
                                error: favoriteSnapshot.error!,
                              );
                            }

                            return supplierListBody(
                              context: context,
                              documents: documents,
                              stockDocuments: stockDocuments,
                              favoriteSupplierIds:
                                  favoriteSnapshot.data ?? const <String>{},
                            );
                          },
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
