import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_header.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_status_cards.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_product_card.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_reviews_section.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/services/supplier_details_service.dart';
import 'package:isdalink/utils/app_error_message.dart';


class _SupplierBusinessMapViewer
    extends StatelessWidget {
  const _SupplierBusinessMapViewer({
    required this.storeName,
    required this.locationLabel,
    required this.position,
  });

  final String storeName;
  final String locationLabel;
  final LatLng position;

  static final LatLngBounds _caragaBounds =
      LatLngBounds(
    southwest: const LatLng(
      7.55,
      124.65,
    ),
    northeast: const LatLng(
      10.75,
      126.85,
    ),
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                15,
                10,
                15,
                11,
              ),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(
                      0xFFE1EBF2,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: const Color(
                      0xFFEAF3FF,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      onTap: () =>
                          Navigator.pop(
                        context,
                      ),
                      child:
                          const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons
                              .arrow_back_rounded,
                          color: Color(
                            0xFF146BFF,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          '$storeName Location',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: Color(
                              0xFF102C44,
                            ),
                            fontSize: 16.2,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        if (locationLabel
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            locationLabel,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color: Color(
                                0xFF7B8FA3,
                              ),
                              fontSize: 9.4,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(
                      target: position,
                      zoom: 16,
                    ),
                    cameraTargetBounds:
                        CameraTargetBounds(
                      _caragaBounds,
                    ),
                    minMaxZoomPreference:
                        const MinMaxZoomPreference(
                      7.6,
                      20,
                    ),
                    markers: {
                      Marker(
                        markerId:
                            const MarkerId(
                          'supplier_business_location',
                        ),
                        position: position,
                        draggable: false,
                        infoWindow:
                            InfoWindow(
                          title:
                              '$storeName Location',
                          snippet:
                              locationLabel
                                      .isEmpty
                                  ? null
                                  : locationLabel,
                        ),
                      ),
                    },
                    myLocationEnabled:
                        false,
                    myLocationButtonEnabled:
                        false,
                    zoomControlsEnabled:
                        true,
                    compassEnabled: true,
                    mapToolbarEnabled:
                        false,
                    rotateGesturesEnabled:
                        true,
                    scrollGesturesEnabled:
                        true,
                    zoomGesturesEnabled:
                        true,
                    tiltGesturesEnabled:
                        true,
                    trafficEnabled:
                        false,
                    indoorViewEnabled:
                        false,
                    buildingsEnabled:
                        true,
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 14,
                    child: IgnorePointer(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          11,
                          9,
                          11,
                          9,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.95,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFFDCE8F1,
                            ),
                          ),
                          boxShadow:
                              const [
                            BoxShadow(
                              color: Color(
                                0x1800152A,
                              ),
                              blurRadius:
                                  12,
                              offset:
                                  Offset(
                                0,
                                5,
                              ),
                            ),
                          ],
                        ),
                        child:
                            const Row(
                          children: [
                            Icon(
                              Icons
                                  .open_with_rounded,
                              color: Color(
                                0xFF146BFF,
                              ),
                              size: 18,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                'Drag and zoom the map to explore the area. '
                                'The supplier business pin remains fixed.',
                                style:
                                    TextStyle(
                                  color: Color(
                                    0xFF52677A,
                                  ),
                                  fontSize:
                                      9.2,
                                  height:
                                      1.3,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class SupplierDetailsScreen extends StatefulWidget {
  const SupplierDetailsScreen({
    super.key,
    required this.supplier,
    this.supplierId,
    this.isOwnerView = false,
  });

  final Supplier supplier;
  final String? supplierId;
  final bool isOwnerView;

  @override
  State<SupplierDetailsScreen> createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  final SupplierDetailsService detailsService =
      const SupplierDetailsService();
  final FavoriteSupplierService favoriteService = FavoriteSupplierService();

  final TextEditingController searchController =
      TextEditingController();

  String searchQuery = '';
  String selectedUnit = 'all';
  String sortMode = 'latest';
  int selectedTab = 0;
  bool favoriteBusy = false;
  bool compactStoreHeader = false;

  Supplier get supplier => widget.supplier;
  String? get supplierId => widget.supplierId;

  bool get ownerMode {
    if (widget.isOwnerView) {
      return true;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final storeUid = supplierId?.trim() ?? '';

    return currentUid != null &&
        storeUid.isNotEmpty &&
        currentUid == storeUid;
  }

  Future<void> toggleFavorite({
    required bool currentlyFavorite,
  }) async {
    final storeUid = supplierId?.trim() ?? '';

    if (favoriteBusy || storeUid.isEmpty || ownerMode) {
      return;
    }

    setState(() {
      favoriteBusy = true;
    });

    try {
      await favoriteService.toggleFavorite(
        supplierId: storeUid,
        currentlyFavorite: currentlyFavorite,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              currentlyFavorite
                  ? 'Supplier removed from Favorites.'
                  : 'Supplier added to Favorites.',
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
          favoriteBusy = false;
        });
      }
    }
  }

  Widget supplierHeader(
    SupplierDetailsStats stats,
  ) {
    return SupplierDetailsHeader(
      supplier: supplier,
      stats: stats,
      onBack: () => Navigator.pop(context),
      businessLocationPreview: supplierBusinessLocationPreview(),
      includeSystemTopPadding: false,
      showNavigationHeader: false,
    );
  }

  Widget compactStoreAvatar() {
    final imageUrl = supplier.profileImageUrl.trim();
    final hasImage = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    final name = supplier.name.trim();
    final initial = name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase();

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withAlpha(44)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }

  Widget storeTopAction({
    required bool canFavorite,
    required bool isFavorite,
  }) {
    if (ownerMode) {
      return Tooltip(
        message: 'Manage products',
        child: Material(
          color: Colors.white.withAlpha(24),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: openManageProducts,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ),
      );
    }

    if (!canFavorite) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
      child: Material(
        color: isFavorite
            ? const Color(0xFFFFF0F3)
            : Colors.white.withAlpha(24),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: favoriteBusy
              ? null
              : () => toggleFavorite(currentlyFavorite: isFavorite),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: favoriteBusy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: isFavorite
                            ? const Color(0xFFE94C72)
                            : Colors.white,
                      ),
                    )
                  : Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE94C72)
                          : Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget storeTopBarContent({
    required double statusBarHeight,
    required bool canFavorite,
    required bool isFavorite,
  }) {
    final storeName = supplier.name.trim().isEmpty ? 'Supplier' : supplier.name.trim();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06355F),
            Color(0xFF075FAE),
          ],
        ),
      ),
      padding: EdgeInsets.only(top: statusBarHeight),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Material(
                color: Colors.white.withAlpha(25),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (compactStoreHeader) ...[
                compactStoreAvatar(),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    key: ValueKey<bool>(compactStoreHeader),
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compactStoreHeader ? storeName : 'Supplier Store',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.15,
                        ),
                      ),
                      if (!compactStoreHeader)
                        const Text(
                          'Verified IsdaLink supplier',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFCFE9F8),
                            fontSize: 8.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withAlpha(28)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              storeTopAction(
                canFavorite: canFavorite,
                isFavorite: isFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget storeTopBar(double statusBarHeight) {
    final storeUid = supplierId?.trim() ?? '';
    final canFavorite = FirebaseAuth.instance.currentUser != null &&
        !ownerMode &&
        storeUid.isNotEmpty;

    if (!canFavorite) {
      return storeTopBarContent(
        statusBarHeight: statusBarHeight,
        canFavorite: false,
        isFavorite: false,
      );
    }

    return StreamBuilder<bool>(
      stream: favoriteService.isFavoriteStream(storeUid),
      initialData: false,
      builder: (context, snapshot) {
        return storeTopBarContent(
          statusBarHeight: statusBarHeight,
          canFavorite: true,
          isFavorite: snapshot.data ?? false,
        );
      },
    );
  }

  bool handleStoreScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final shouldCompact = notification.metrics.pixels > 92;
    if (shouldCompact != compactStoreHeader && mounted) {
      setState(() {
        compactStoreHeader = shouldCompact;
      });
    }

    return false;
  }

  double? mapCoordinate(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  Widget supplierBusinessLocationPreview() {
    final storeUid = supplierId?.trim() ?? '';

    if (storeUid.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(storeUid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (data == null) {
          return const SizedBox.shrink();
        }

        final latitude = mapCoordinate(data['storeLatitude']);
        final longitude = mapCoordinate(data['storeLongitude']);

        if (latitude == null || longitude == null) {
          return const SizedBox.shrink();
        }

        final province = detailsService.getStringValue(
          data,
          'storeProvince',
          '',
        );
        final locality = detailsService.getStringValue(
          data,
          'storeCityMunicipality',
          '',
        );

        final locationParts = <String>[
          if (locality.trim().isNotEmpty) locality.trim(),
          if (province.trim().isNotEmpty) province.trim(),
        ];

        final locationLabel = locationParts.isEmpty
            ? supplier.location.trim()
            : locationParts.join(', ');

        final storeName = supplier.name.trim().isEmpty
            ? 'Supplier'
            : supplier.name.trim();

        final position = LatLng(latitude, longitude);

        void openFullMap() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _SupplierBusinessMapViewer(
                storeName: storeName,
                locationLabel: locationLabel,
                position: position,
              ),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openFullMap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(24),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withAlpha(34),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 13,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'View location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openManageProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupplierManageProductsScreen(),
      ),
    );
  }

  Widget ownerPreviewBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(
        11,
        9,
        9,
        9,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFE7F8F2),
            Color(0xFFEAF7FF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCBE7DC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF0875D1),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Your Store',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 7),
                    _OwnerPreviewBadge(),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Vendor preview · Ordering disabled for your own store.',
                  style: TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 8.8,
                    height: 1.22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          TextButton.icon(
            onPressed: openManageProducts,
            icon: Icon(
              Icons.inventory_2_outlined,
              size: 15,
            ),
            label: Text(
              'Manage',
              style: TextStyle(
                fontSize: 9.7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (ownerMode) {
      openManageProducts();
      return;
    }

    final data = document.data();

    final product = detailsService.fishProductFromFirestore(
      data,
    );

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

  Widget storeTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 7),
      child: Container(
        height: 42,
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
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF102C44)
                      : const Color(0xFF7B8FA3),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showSortSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(150),
      builder: (sheetContext) {
        const options = <(String, String, String, IconData)>[
          (
            'latest',
            'Latest activity',
            'Newest posts and recently restocked fish first.',
            Icons.schedule_rounded,
          ),
          (
            'price_low',
            'Price: low to high',
            'Show the lowest-priced listings first.',
            Icons.south_rounded,
          ),
          (
            'price_high',
            'Price: high to low',
            'Show the highest-priced listings first.',
            Icons.north_rounded,
          ),
          (
            'stock_high',
            'Most stock available',
            'Prioritize listings with more available quantity.',
            Icons.inventory_2_outlined,
          ),
          (
            'name',
            'Fish name',
            'Sort alphabetically by fish name.',
            Icons.sort_by_alpha_rounded,
          ),
        ];

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
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
                    Icon(
                      Icons.swap_vert_rounded,
                      color: Color(0xFF087AC0),
                      size: 21,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sort fish listings',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...options.map((option) {
                  final selectedOption = sortMode == option.$1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(sheetContext, option.$1),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedOption
                                ? const Color(0xFFEAF7FD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedOption
                                  ? const Color(0xFF9DDCF3)
                                  : const Color(0xFFE3ECF2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F7FB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  option.$4,
                                  color: const Color(0xFF087AC0),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.$2,
                                      style: const TextStyle(
                                        color: Color(0xFF102C44),
                                        fontSize: 11.6,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.$3,
                                      style: const TextStyle(
                                        color: Color(0xFF7B8FA3),
                                        fontSize: 9.1,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                selectedOption
                                    ? Icons.check_circle_rounded
                                    : Icons.chevron_right_rounded,
                                color: selectedOption
                                    ? const Color(0xFF159C74)
                                    : const Color(0xFF9DB0BE),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      sortMode = selected;
    });
  }

  Widget searchAndFilterCard(
    List<String> units,
  ) {
    final unitOptions = [
      'all',
      ...units,
    ];

    final effectiveSelectedUnit = unitOptions.contains(selectedUnit)
        ? selectedUnit
        : 'all';

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: const Color(0xFF087AC0),
            cursorHeight: 18,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
            onChanged: (value) {
              setState(
                () {
                  searchQuery = value;
                },
              );
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

                        setState(
                          () {
                            searchQuery = '';
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: Color(0xFF7B8FA3),
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: unitOptions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final unit = unitOptions[index];
                      final selected = effectiveSelectedUnit == unit;

                      return ChoiceChip(
                        selected: selected,
                        onSelected: (_) {
                          setState(
                            () {
                              selectedUnit = unit;
                            },
                          );
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
                          fontSize: 10.3,
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: showSortSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD5EEF7),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          color: Color(0xFF087AC0),
                          size: 17,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sort',
                          style: TextStyle(
                            color: Color(0xFF087AC0),
                            fontSize: 10.3,
                            fontWeight: FontWeight.w900,
                          ),
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

  Widget productCardForDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
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
  }

  Widget productsHeading(
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Available Fish',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FD),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count listing${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Color(0xFF087AC0),
                    fontSize: 9.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ownerMode
                ? 'Active listings currently visible to vendors.'
                : 'Fresh stock currently available from ${supplier.name}.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.6,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget reviewsBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SupplierReviewsSection(
        supplierId: supplierId,
        supplierName: supplier.name,
      ),
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
    final orderable = detailsService.orderableStocks(documents);
    final units = detailsService.availableUnits(orderable);
    final effectiveSelectedUnit = units.contains(selectedUnit)
        ? selectedUnit
        : 'all';
    final visibleProducts = detailsService.filterAndSortProducts(
      documents: orderable,
      query: searchQuery,
      selectedUnit: effectiveSelectedUnit,
      sortMode: sortMode,
    );
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 330 ? 1 : 2;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: supplierHeader(stats),
        ),
        if (ownerMode)
          SliverToBoxAdapter(
            child: ownerPreviewBanner(),
          ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StoreTabsHeaderDelegate(
            child: storeTabs(),
          ),
        ),
        if (selectedTab == 0) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            sliver: SliverToBoxAdapter(
              child: searchAndFilterCard(units),
            ),
          ),
          SliverToBoxAdapter(
            child: productsHeading(visibleProducts.length),
          ),
          if (orderable.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              sliver: SliverToBoxAdapter(
                child: SupplierDetailsEmptyCard(
                  title: 'No fish available right now',
                  subtitle: ownerMode
                      ? 'You currently have no active listings visible to vendors.'
                      : 'This supplier has no active fish stock for ordering at the moment.',
                ),
              ),
            )
          else if (visibleProducts.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
              sliver: SliverToBoxAdapter(
                child: SupplierDetailsEmptyCard(
                  title: 'No matching fish found',
                  subtitle:
                      'Try another fish name, spelling, or unit filter.',
                  icon: Icons.search_off_rounded,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => productCardForDocument(
                    visibleProducts[index],
                  ),
                  childCount: visibleProducts.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  mainAxisExtent: columns == 1 ? 226 : 250,
                ),
              ),
            ),
        ] else
          SliverToBoxAdapter(
            child: reviewsBody(),
          ),
      ],
    );
  }

  Widget loadingBody() {
    final stats = detailsService.calculateStats(
      const [],
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        supplierHeader(stats),
        if (ownerMode)
          ownerPreviewBanner(),
        storeTabs(),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: SupplierDetailsLoadingCard(),
        ),
      ],
    );
  }

  Widget errorBody(
    Object error,
  ) {
    final stats = detailsService.calculateStats(
      const [],
    );
    final message = AppErrorMessage.from(
      error,
      fallback: 'The supplier store could not be loaded right now. Please try again.',
      allowBusinessMessage: true,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        supplierHeader(stats),
        if (ownerMode)
          ownerPreviewBanner(),
        storeTabs(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: SupplierDetailsErrorCard(
            message: message,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // This fixed marine bar paints behind the edge-to-edge Android
            // status area and becomes the compact store identity on scroll.
            storeTopBar(statusBarHeight),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: handleStoreScroll,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: detailsService.fishStocksStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return errorBody(snapshot.error!);
                    }

                    if (!snapshot.hasData) {
                      return loadingBody();
                    }

                    return loadedBody(
                      snapshot.data!.docs,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StoreTabsHeaderDelegate({
    required this.child,
  });

  final Widget child;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? const [
                BoxShadow(
                  color: Color(0x1200152A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StoreTabsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _OwnerPreviewBadge extends StatelessWidget {
  const _OwnerPreviewBadge();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5EC),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'OWNER VIEW',
        style: TextStyle(
          color: Color(0xFF147D64),
          fontSize: 7.1,
          letterSpacing: 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

