import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_header.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_status_cards.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_product_card.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_reviews_section.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/config/cloudinary_config.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/services/supplier_profile_service.dart';
import 'package:isdalink/services/supplier_details_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class _SupplierBusinessMapViewer extends StatelessWidget {
  const _SupplierBusinessMapViewer({
    required this.storeName,
    required this.locationLabel,
    required this.position,
  });

  final String storeName;
  final String locationLabel;
  final LatLng position;

  static final LatLngBounds _caragaBounds = LatLngBounds(
    southwest: const LatLng(7.55, 124.65),
    northeast: const LatLng(10.75, 126.85),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 11),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE1EBF2))),
              ),
              child: Row(
                children: [
                  Material(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF146BFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$storeName Location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 16.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (locationLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7B8FA3),
                              fontSize: 9.4,
                              fontWeight: FontWeight.w600,
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
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: 16,
                    ),
                    cameraTargetBounds: CameraTargetBounds(_caragaBounds),
                    minMaxZoomPreference: const MinMaxZoomPreference(7.6, 20),
                    markers: {
                      Marker(
                        markerId: const MarkerId('supplier_business_location'),
                        position: position,
                        draggable: false,
                        infoWindow: InfoWindow(
                          title: '$storeName Location',
                          snippet: locationLabel.isEmpty ? null : locationLabel,
                        ),
                      ),
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    trafficEnabled: false,
                    indoorViewEnabled: false,
                    buildingsEnabled: true,
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 14,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCE8F1)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1800152A),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.open_with_rounded,
                              color: Color(0xFF146BFF),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Drag and zoom the map to explore the area. '
                                'The supplier business pin remains fixed.',
                                style: TextStyle(
                                  color: Color(0xFF52677A),
                                  fontSize: 9.2,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
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
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  final SupplierDetailsService detailsService = const SupplierDetailsService();
  final FavoriteSupplierService favoriteService = FavoriteSupplierService();
  final ImagePicker imagePicker = ImagePicker();
  final CloudinaryUploadService uploadService = const CloudinaryUploadService();
  final SupplierProfileService profileService = const SupplierProfileService();

  final TextEditingController searchController = TextEditingController();
  final ScrollController storeScrollController = ScrollController();

  late String storefrontProfileImageUrl;
  late String storefrontCoverImageUrl;
  bool uploadingProfileImage = false;
  bool uploadingCoverImage = false;

  String searchQuery = '';
  String selectedUnit = 'all';
  String sortMode = 'latest';
  int selectedTab = 0;
  bool favoriteBusy = false;
  bool showCompactStoreHeader = false;

  @override
  void initState() {
    super.initState();
    storefrontProfileImageUrl = widget.supplier.profileImageUrl.trim();
    storefrontCoverImageUrl = widget.supplier.coverImageUrl.trim();
    storeScrollController.addListener(handleStoreScroll);
  }

  void handleStoreScroll() {
    if (!storeScrollController.hasClients) {
      return;
    }

    // The full hero scrolls normally. Once the user starts moving through
    // the store, a compact identity bar takes over so the large cover does
    // not permanently consume screen space.
    final shouldShow = storeScrollController.offset > 72;

    if (shouldShow != showCompactStoreHeader && mounted) {
      setState(() {
        showCompactStoreHeader = shouldShow;
      });
    }
  }

  Supplier get supplier => widget.supplier;
  String? get supplierId => widget.supplierId;

  bool get ownerMode {
    if (widget.isOwnerView) {
      return true;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final storeUid = supplierId?.trim() ?? '';

    return currentUid != null && storeUid.isNotEmpty && currentUid == storeUid;
  }

  Future<void> toggleFavorite({required bool currentlyFavorite}) async {
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

  Widget supplierHeader(SupplierDetailsStats stats) {
    final storeUid = supplierId?.trim() ?? '';
    final canFavorite =
        FirebaseAuth.instance.currentUser != null &&
        !ownerMode &&
        storeUid.isNotEmpty;

    Widget buildHeader({required bool isFavorite}) {
      return SupplierDetailsHeader(
        supplier: supplier,
        stats: stats,
        onBack: () => Navigator.pop(context),
        businessLocationPreview: supplierBusinessLocationPreview(),
        showFavoriteAction: canFavorite,
        isFavorite: isFavorite,
        favoriteBusy: favoriteBusy,
        onFavoriteToggle: canFavorite
            ? () => toggleFavorite(currentlyFavorite: isFavorite)
            : null,
        isOwnerView: ownerMode,
        profileImageUrlOverride: storefrontProfileImageUrl,
        coverImageUrlOverride: storefrontCoverImageUrl,
        profileImageBusy: uploadingProfileImage,
        coverImageBusy: uploadingCoverImage,
        onEditProfileImage: ownerMode
            ? () => showStorefrontImageActions(isCover: false)
            : null,
        onEditCoverImage: ownerMode
            ? () => showStorefrontImageActions(isCover: true)
            : null,
        onProfileImageTap: () => openStorefrontImageViewer(
          imageUrl: storefrontProfileImageUrl,
          title: '${supplier.name} profile photo',
        ),
        onCoverImageTap: () => openStorefrontImageViewer(
          imageUrl: storefrontCoverImageUrl,
          title: '${supplier.name} cover photo',
        ),
      );
    }

    if (!canFavorite) {
      return buildHeader(isFavorite: false);
    }

    return StreamBuilder<bool>(
      stream: favoriteService.isFavoriteStream(storeUid),
      initialData: false,
      builder: (context, snapshot) {
        return buildHeader(isFavorite: snapshot.data ?? false);
      },
    );
  }

  void openStorefrontImageViewer({
    required String imageUrl,
    required String title,
  }) {
    final value = imageUrl.trim();
    final isNetworkImage =
        value.startsWith('http://') || value.startsWith('https://');

    if (!isNetworkImage) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StorefrontImageViewer(imageUrl: value, title: title),
      ),
    );
  }

  Future<void> showStorefrontImageActions({required bool isCover}) async {
    if (!ownerMode || uploadingProfileImage || uploadingCoverImage) {
      return;
    }

    final currentUrl = isCover
        ? storefrontCoverImageUrl
        : storefrontProfileImageUrl;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4DFE7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isCover ? 'Store Cover Photo' : 'Store Profile Photo',
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Storefront photos update immediately and do not require admin approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF718699),
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: const Color(0xFFF2F8FC),
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF087AC0),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'gallery'),
                ),
                if (currentUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: const Color(0xFFFFF2F2),
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFD94A45),
                    ),
                    title: const Text(
                      'Remove photo',
                      style: TextStyle(
                        color: Color(0xFFD94A45),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () => Navigator.pop(sheetContext, 'remove'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (action == 'gallery') {
      await pickAndUploadStorefrontImage(isCover: isCover);
    } else if (action == 'remove') {
      await removeStorefrontImage(isCover: isCover);
    }
  }

  Future<void> pickAndUploadStorefrontImage({required bool isCover}) async {
    final uid = supplierId?.trim() ?? '';
    if (uid.isEmpty || FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }

    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: isCover ? 1800.0 : 1000.0,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      if (isCover) {
        uploadingCoverImage = true;
      } else {
        uploadingProfileImage = true;
      }
    });

    try {
      final imageUrl = await uploadService.uploadImage(
        image,
        folder:
            '${CloudinaryConfig.supplierStorefrontFolder}/$uid/${isCover ? 'cover' : 'profile'}',
      );

      await profileService.updateStorefrontImage(
        uid: uid,
        imageUrl: imageUrl,
        isCover: isCover,
      );

      if (!mounted) return;
      setState(() {
        if (isCover) {
          storefrontCoverImageUrl = imageUrl;
        } else {
          storefrontProfileImageUrl = imageUrl;
        }
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              isCover
                  ? 'Store cover photo updated.'
                  : 'Store profile photo updated.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              AppErrorMessage.from(
                error,
                fallback:
                    'The storefront photo could not be updated. Please try again.',
                allowBusinessMessage: true,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          if (isCover) {
            uploadingCoverImage = false;
          } else {
            uploadingProfileImage = false;
          }
        });
      }
    }
  }

  Future<void> removeStorefrontImage({required bool isCover}) async {
    final uid = supplierId?.trim() ?? '';
    if (uid.isEmpty || FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }

    setState(() {
      if (isCover) {
        uploadingCoverImage = true;
      } else {
        uploadingProfileImage = true;
      }
    });

    try {
      await profileService.removeStorefrontImage(uid: uid, isCover: isCover);

      if (!mounted) return;
      setState(() {
        if (isCover) {
          storefrontCoverImageUrl = '';
        } else {
          storefrontProfileImageUrl = '';
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            AppErrorMessage.from(
              error,
              fallback:
                  'The storefront photo could not be removed. Please try again.',
              allowBusinessMessage: true,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isCover) {
            uploadingCoverImage = false;
          } else {
            uploadingProfileImage = false;
          }
        });
      }
    }
  }

  double? mapCoordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  Widget supplierBusinessLocationPreview() {
    final storeUid = supplierId?.trim() ?? '';

    if (storeUid.isEmpty) {
      return const _StoreMapSummaryButton();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(storeUid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final latitude = mapCoordinate(data?['storeLatitude']);
        final longitude = mapCoordinate(data?['storeLongitude']);

        if (data == null || latitude == null || longitude == null) {
          return const _StoreMapSummaryButton();
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

        return _StoreMapSummaryButton(
          enabled: true,
          onTap: () {
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
          },
        );
      },
    );
  }

  Widget storeSummaryMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7FD),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: const Color(0xFF0A6094), size: 15),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF103B5C),
                      fontSize: 11.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B91A3),
                fontSize: 8.1,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatMemberSinceDate(DateTime createdAt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final local = createdAt.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  Widget storeSummaryPanel(SupplierDetailsStats stats) {
    final createdAt = supplier.accountCreatedAt;
    final localCreatedAt = createdAt?.toLocal();
    const memberMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final memberValue = localCreatedAt == null
        ? '${stats.availableListings}'
        : '${memberMonths[localCreatedAt.month - 1]} ${localCreatedAt.day}';
    final memberLabel = localCreatedAt == null
        ? 'Available'
        : 'Member Since · ${localCreatedAt.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 7),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F9FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0EBF2)),
        ),
        child: Row(
          children: [
            storeSummaryMetric(
              icon: Icons.inventory_2_outlined,
              value: '${stats.totalListings}',
              label: 'Fish Stocks',
            ),
            Container(width: 1, height: 34, color: const Color(0xFFDDEAF2)),
            storeSummaryMetric(
              icon: Icons.groups_2_outlined,
              value: memberValue,
              label: memberLabel,
            ),
            Container(width: 1, height: 34, color: const Color(0xFFDDEAF2)),
            Expanded(child: supplierBusinessLocationPreview()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    storeScrollController
      ..removeListener(handleStoreScroll)
      ..dispose();
    searchController.dispose();
    super.dispose();
  }

  void openManageProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupplierManageProductsScreen()),
    );
  }

  void openProduct(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    if (ownerMode) {
      openManageProducts();
      return;
    }

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

  Widget storeTabs() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
        children: [
          Expanded(child: storeTabButton(label: 'Fish Stocks', index: 0)),
          Expanded(child: storeTabButton(label: 'About', index: 1)),
          Expanded(
            child: storeTabButton(
              label: supplier.reviews > 0
                  ? 'Reviews (${supplier.reviews})'
                  : 'Reviews',
              index: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget storeTabButton({required String label, required int index}) {
    final selected = selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? const Color(0xFF087AC0)
                  : const Color(0xFFE5EEF4),
              width: selected ? 2.5 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? const Color(0xFF087AC0) : const Color(0xFF45647C),
            fontSize: 10.6,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget storeControlsCard(List<String> units) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0EBF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12001325),
              blurRadius: 11,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            storeTabs(),
            if (selectedTab == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
                child: searchAndFilterCard(units, embedded: true),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> showSortSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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

        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBED0DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
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
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selectedOption = sortMode == option.$1;

                      return Material(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      );
                    },
                  ),
                ),
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

  Widget searchAndFilterCard(List<String> units, {bool embedded = false}) {
    final unitOptions = ['all', ...units];

    final effectiveSelectedUnit = unitOptions.contains(selectedUnit)
        ? selectedUnit
        : 'all';

    return Container(
      padding: embedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: embedded
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0EEF5)),
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
          SizedBox(
            height: 40,
            child: TextField(
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
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
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
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFE1EEF6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFF16A9D1),
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: unitOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final unit = unitOptions[index];
                      final selected = effectiveSelectedUnit == unit;

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
                              : unit[0].toUpperCase() + unit.substring(1),
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF52677A),
                          fontSize: 9.8,
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
                          borderRadius: BorderRadius.circular(11),
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
                  borderRadius: BorderRadius.circular(11),
                  child: Ink(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8FD),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFD5EEF7)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          color: Color(0xFF087AC0),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sort',
                          style: TextStyle(
                            color: Color(0xFF087AC0),
                            fontSize: 9.8,
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
    final emoji = detailsService.getStringValue(data, 'emoji', '🐟');
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
    final lowStockLevel = detailsService.getDoubleValue(data, 'lowStockLevel');
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

  Widget productsHeading(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
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
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
              fontSize: 10.1,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget aboutBody() {
    final memberSince = supplier.accountCreatedAt == null
        ? 'Not available'
        : formatMemberSinceDate(supplier.accountCreatedAt!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store Information',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Public details for this verified IsdaLink supplier.',
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          _StoreAboutCard(
            children: [
              _StoreAboutRow(
                icon: Icons.phone_outlined,
                label: 'Store contact',
                value: supplier.contactNumber,
              ),
              _StoreAboutRow(
                icon: Icons.location_on_outlined,
                label: 'Business location',
                value: supplier.location,
              ),
              _StoreAboutRow(
                icon: Icons.calendar_month_outlined,
                label: 'Member since',
                value: memberSince,
              ),
              const _StoreAboutRow(
                icon: Icons.payments_outlined,
                label: 'Payment method',
                value: 'Cash on Delivery (COD)',
                showDivider: false,
              ),
            ],
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

  Widget compactStoreHeaderForState({required bool isFavorite}) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final storeUid = supplierId?.trim() ?? '';
    final canFavorite =
        FirebaseAuth.instance.currentUser != null &&
        !ownerMode &&
        storeUid.isNotEmpty;
    final profileUrl = storefrontProfileImageUrl.trim();
    final hasProfile =
        profileUrl.startsWith('http://') || profileUrl.startsWith('https://');
    final storeName = supplier.name.trim().isEmpty
        ? 'Supplier'
        : supplier.name.trim();

    Widget compactAction({
      required IconData icon,
      required VoidCallback? onTap,
      bool busy = false,
      Color foreground = Colors.white,
    }) {
      return Material(
        color: Colors.white.withAlpha(34),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  : Icon(icon, color: foreground, size: 20),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        height: topPadding + 58,
        padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0A4F78), Color(0xFF0873A9)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x26001325),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            compactAction(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 9),
            GestureDetector(
              onTap: hasProfile
                  ? () => openStorefrontImageViewer(
                      imageUrl: profileUrl,
                      title: '$storeName profile photo',
                    )
                  : null,
              child: Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: hasProfile
                      ? Image.network(
                          profileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFE8F8FD),
                            alignment: Alignment.center,
                            child: Text(
                              storeName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF087AC0),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE8F8FD),
                          alignment: Alignment.center,
                          child: Text(
                            storeName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF087AC0),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(242),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF0B8FC4),
                size: 18,
              ),
            ),
            const SizedBox(width: 7),
            if (ownerMode)
              compactAction(
                icon: Icons.photo_camera_back_outlined,
                onTap: () => showStorefrontImageActions(isCover: true),
                busy: uploadingCoverImage,
              )
            else if (canFavorite)
              compactAction(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                onTap: () => toggleFavorite(currentlyFavorite: isFavorite),
                busy: favoriteBusy,
                foreground: isFavorite ? const Color(0xFFFFB3C6) : Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget compactStickyStoreHeader() {
    final storeUid = supplierId?.trim() ?? '';
    final canFavorite =
        FirebaseAuth.instance.currentUser != null &&
        !ownerMode &&
        storeUid.isNotEmpty;

    if (!canFavorite) {
      return compactStoreHeaderForState(isFavorite: false);
    }

    return StreamBuilder<bool>(
      stream: favoriteService.isFavoriteStream(storeUid),
      initialData: false,
      builder: (context, snapshot) {
        return compactStoreHeaderForState(isFavorite: snapshot.data ?? false);
      },
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

    final hasPublicCover =
        storefrontCoverImageUrl.trim().startsWith('http://') ||
        storefrontCoverImageUrl.trim().startsWith('https://');
    final heroHeight =
        MediaQuery.paddingOf(context).top + (hasPublicCover ? 246.0 : 224.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomScrollView(
          controller: storeScrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const ClampingScrollPhysics(),
          slivers: [
            // The large storefront identity is part of the normal scroll now.
            // The actual hero remains behind the curved white body so its
            // cover/blue background is visible at the rounded corners.
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  supplierHeader(stats),
                  Padding(
                    padding: EdgeInsets.only(top: heroHeight - 20),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x16001B2D),
                            blurRadius: 14,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          storeSummaryPanel(stats),
                          storeControlsCard(units),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selectedTab == 0) ...[
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: productsHeading(visibleProducts.length),
                ),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          productCardForDocument(visibleProducts[index]),
                      childCount: visibleProducts.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: columns == 1 ? 202 : 194,
                    ),
                  ),
                ),
            ] else if (selectedTab == 1)
              SliverToBoxAdapter(
                child: Container(color: Colors.white, child: aboutBody()),
              )
            else
              SliverToBoxAdapter(
                child: Container(color: Colors.white, child: reviewsBody()),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),

        // Only the compact bar remains pinned while browsing.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            ignoring: !showCompactStoreHeader,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              offset: showCompactStoreHeader
                  ? Offset.zero
                  : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: showCompactStoreHeader ? 1 : 0,
                child: compactStickyStoreHeader(),
              ),
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
        supplierHeader(stats),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              storeControlsCard(const []),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: SupplierDetailsLoadingCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorBody(Object error) {
    final stats = detailsService.calculateStats(const []);
    final message = AppErrorMessage.from(
      error,
      fallback:
          'The supplier store could not be loaded right now. Please try again.',
      allowBusinessMessage: true,
    );

    return Column(
      children: [
        supplierHeader(stats),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              storeControlsCard(const []),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: SupplierDetailsErrorCard(message: message),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: detailsService.fishStocksStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return errorBody(snapshot.error!);
            }

            if (!snapshot.hasData) {
              return loadingBody();
            }

            return loadedBody(snapshot.data!.docs);
          },
        ),
      ),
    );
  }
}

class _StorefrontImageViewer extends StatelessWidget {
  const _StorefrontImageViewer({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 44,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Unable to display this photo.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 10,
                child: Row(
                  children: [
                    Material(
                      color: Colors.black.withAlpha(115),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
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
}

class _StoreMapSummaryButton extends StatelessWidget {
  const _StoreMapSummaryButton({this.enabled = false, this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7FD),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: enabled
                          ? const Color(0xFF087AC0)
                          : const Color(0xFF9DB2C0),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    enabled ? 'View Map' : 'No Map',
                    maxLines: 1,
                    style: TextStyle(
                      color: enabled
                          ? const Color(0xFF087AC0)
                          : const Color(0xFF7B91A3),
                      fontSize: 9.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(width: 1),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF087AC0),
                      size: 14,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                enabled ? 'Location' : 'No location',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7B91A3),
                  fontSize: 8.1,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreAboutCard extends StatelessWidget {
  const _StoreAboutCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C00182A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _StoreAboutRow extends StatelessWidget {
  const _StoreAboutRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF087AC0), size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value.trim().isEmpty ? 'Not provided' : value,
                      style: const TextStyle(
                        color: Color(0xFF173A54),
                        fontSize: 11.6,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE8EFF4)),
      ],
    );
  }
}

// Retained for the sticky-tab layout variant.
// ignore: unused_element
class _StoreTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StoreTabsHeaderDelegate({required this.child});

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

// Retained for supplier-owner preview mode.
// ignore: unused_element
class _OwnerPreviewBadge extends StatelessWidget {
  const _OwnerPreviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
