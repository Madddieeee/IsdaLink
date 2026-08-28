import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_header.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_status_cards.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/supplier_profile_card.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

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

  String searchQuery = '';
  bool showFavoritesOnly = false;
  String? favoriteActionSupplierId;

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
    required Set<String> favoriteSupplierIds,
  }) {
    final approvedDocuments = supplierService.approvedSuppliers(documents);
    final approvedSupplierIds = approvedDocuments.map((document) => document.id).toSet();
    final activeFavoriteIds = favoriteSupplierIds.intersection(approvedSupplierIds);

    final searchedDocuments = supplierService.searchSuppliers(
      documents: approvedDocuments,
      query: searchQuery,
    );

    final filteredDocuments = showFavoritesOnly
        ? searchedDocuments
            .where((document) => activeFavoriteIds.contains(document.id))
            .toList()
        : searchedDocuments;

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
        const SizedBox(height: 18),
        Text(
          showFavoritesOnly ? 'Favorite Suppliers' : 'Recommended Suppliers',
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          showFavoritesOnly
              ? 'Your saved suppliers for faster access to their stores.'
              : 'Tap the heart to save suppliers you want to revisit.',
          style: const TextStyle(
            color: Color(0xFF7B8FA3),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 18),
        ...filteredDocuments.map((document) {
          final data = document.data();
          final supplier = supplierService.supplierFromProfile(data);
          final paymentMethod = supplierService.getStringValue(
            data,
            'paymentMethod',
            'COD',
          );
          final status = supplierService.getStringValue(
            data,
            'status',
            'approved',
          );
          final isFavorite = activeFavoriteIds.contains(document.id);

          return SupplierProfileCard(
            supplier: supplier,
            paymentMethod: paymentMethod,
            status: status,
            isFavorite: isFavorite,
            favoriteBusy: favoriteActionSupplierId == document.id,
            showFavoriteAction: favoriteService.currentUserId != document.id,
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
          final approvedCount = supplierService.approvedSuppliers(documents).length;

          return Column(
            children: [
              BrowseSuppliersHeader(
                approvedCount: approvedCount,
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

                    if (!supplierSnapshot.hasData) {
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
      ),
    );
  }
}
