import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_card.dart';
import 'package:isdalink/screens/vendor/place_order_screen.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class RecentFishPosts extends StatelessWidget {
  const RecentFishPosts({
    super.key,
    required this.onProductTap,
  });

  final void Function(
    Supplier supplier,
    FishProduct product,
    String stockId,
    String supplierId,
  ) onProductTap;

  HomeStockService get stockService => const HomeStockService();

  void showFishPreviewSheet({
    required BuildContext context,
    required Supplier supplier,
    required FishProduct product,
    required String stockId,
    required String supplierId,
  }) {
    final navigator = Navigator.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(95),
      builder: (sheetContext) {
        return HomeFishPreviewSheet(
          supplier: supplier,
          product: product,
          supplierId: supplierId,
          onMoreInfo: () {
            Navigator.pop(sheetContext);

            Future.microtask(
              () => onProductTap(
                supplier,
                product,
                stockId,
                supplierId,
              ),
            );
          },
          onOrderNow: () {
            Navigator.pop(sheetContext);

            Future.microtask(
              () {
                if (!navigator.mounted) {
                  return;
                }

                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => PlaceOrderScreen(
                      supplier: supplier,
                      product: product,
                      stockId: stockId,
                      supplierId: supplierId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget supplierUnavailableCard(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Supplier information is not available yet.',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: Text(
            'Supplier information is not available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget errorList(
    Object error,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        'Unable to load recent fish posts: $error',
        style: const TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget loadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget emptyList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF146BFF),
            size: 38,
          ),
          SizedBox(height: 10),
          Text(
            'No recent fish posts yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Supplier fish stocks will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget cardForDocument(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    bool isWide = false,
  }) {
    final data = document.data();

    final product = stockService.fishProductFromFirestore(data);
    final supplier = stockService.supplierForStock(data);

    final stockSupplierId = OrderHelpers.getStringValue(
      data,
      'supplierId',
      '',
    );

    if (supplier == null) {
      return supplierUnavailableCard(context);
    }

    return RecentFishCard(
      product: product,
      supplierName: supplier.name,
      isWide: isWide,
      onTap: () => showFishPreviewSheet(
        context: context,
        supplier: supplier,
        product: product,
        stockId: document.id,
        supplierId: stockSupplierId,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stockService.recentFishPostsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorList(snapshot.error!);
        }

        if (!snapshot.hasData) {
          return loadingGrid();
        }

        final documents =
            snapshot.data!.docs.where(stockService.isAvailableStock).toList();

        if (documents.isEmpty) {
          return emptyList();
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            return cardForDocument(
              context,
              documents[index],
            );
          },
        );
      },
    );
  }
}

class HomeFishPreviewSheet extends StatelessWidget {
  const HomeFishPreviewSheet({
    super.key,
    required this.supplier,
    required this.product,
    required this.supplierId,
    required this.onMoreInfo,
    required this.onOrderNow,
  });

  final Supplier supplier;
  final FishProduct product;
  final String supplierId;
  final VoidCallback onMoreInfo;
  final VoidCallback onOrderNow;

  bool hasNetworkImage(
    String value,
  ) {
    final text = value.trim();

    return text.startsWith('http://') || text.startsWith('https://');
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
        lowerText == 'asdf') {
      return fallback;
    }

    return text;
  }

  String getStringValue(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    if (data == null) {
      return fallback;
    }

    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String profileImageFromData(
    Map<String, dynamic>? data,
  ) {
    final profileImageUrl = getStringValue(
      data,
      'profileImageUrl',
      '',
    );

    if (profileImageUrl.isNotEmpty) {
      return profileImageUrl;
    }

    final photoUrl = getStringValue(
      data,
      'photoUrl',
      '',
    );

    if (photoUrl.isNotEmpty) {
      return photoUrl;
    }

    final storePhotoUrl = getStringValue(
      data,
      'storePhotoUrl',
      '',
    );

    if (storePhotoUrl.isNotEmpty) {
      return storePhotoUrl;
    }

    final application = data?['supplierApplication'];

    if (application is Map<String, dynamic>) {
      return getStringValue(
        application,
        'storePhotoUrl',
        '',
      );
    }

    return supplier.profileImageUrl;
  }

  Supplier supplierFromData(
    Map<String, dynamic>? data,
  ) {
    return Supplier(
      name: getStringValue(
        data,
        'supplierName',
        getStringValue(
          data,
          'storeName',
          getStringValue(
            data,
            'businessName',
            supplier.name,
          ),
        ),
      ),
      location: getStringValue(
        data,
        'location',
        getStringValue(
          data,
          'storeLocation',
          supplier.location,
        ),
      ),
      contactNumber: getStringValue(
        data,
        'phone',
        getStringValue(
          data,
          'contactNumber',
          supplier.contactNumber,
        ),
      ),
      description: getStringValue(
        data,
        'description',
        supplier.description,
      ),
      rating: supplier.rating,
      reviews: supplier.reviews,
      products: supplier.products,
      profileImageUrl: profileImageFromData(data),
    );
  }

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  Widget sheetHandle(
    BuildContext context,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFDCE6EF),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF7B8FA3),
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget supplierAvatar(
    Supplier activeSupplier,
  ) {
    final imageUrl = activeSupplier.profileImageUrl.trim();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hasNetworkImage(imageUrl)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.storefront,
                    color: Color(0xFF146BFF),
                    size: 28,
                  );
                },
              )
            : const Icon(
                Icons.storefront,
                color: Color(0xFF146BFF),
                size: 28,
              ),
      ),
    );
  }

  Widget productImage() {
    final imageUrl = product.imageUrl.trim();

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withAlpha(170),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: hasNetworkImage(imageUrl)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ProductSheetEmojiFallback(
                    emoji: product.emoji,
                  );
                },
              )
            : ProductSheetEmojiFallback(
                emoji: product.emoji,
              ),
      ),
    );
  }

  Widget compactPill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget combinedPreviewCard(
    BuildContext context,
    Supplier activeSupplier,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF102C44),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -44,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -44,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B7D4).withAlpha(35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      supplierAvatar(activeSupplier),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available from',
                              style: TextStyle(
                                color: Color(0xFFBFD1E3),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              cleanText(
                                value: activeSupplier.name,
                                fallback: 'Verified Supplier',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFFDCE9F5),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cleanText(
                                      value: activeSupplier.location,
                                      fallback: 'Caraga Region',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFDCE9F5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38D39F).withAlpha(36),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Color(0xFF38D39F),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    height: 1,
                    color: Colors.white.withAlpha(30),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      productImage(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected fish',
                              style: TextStyle(
                                color: Color(0xFFBFD1E3),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              cleanText(
                                value: product.name,
                                fallback: 'Fresh Fish Stock',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                compactPill(
                                  icon: Icons.payments_outlined,
                                  text: 'COD only',
                                  color: const Color(0xFF8EDBFF),
                                ),
                                compactPill(
                                  icon: Icons.check_circle,
                                  text: product.stockStatus,
                                  color: const Color(0xFF38D39F),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget detailBox({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5FAFE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE1EEF6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 10.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 12.7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget notesBox() {
    final notes = product.description.trim();

    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1EEF6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Notes',
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            notes,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget sheetContent(
    BuildContext context,
    Supplier activeSupplier,
  ) {
    final canOrder = product.availableQuantity > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sheetHandle(context),
            const SizedBox(height: 12),
            combinedPreviewCard(
              context,
              activeSupplier,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                detailBox(
                  label: 'Price',
                  value: '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
                ),
                const SizedBox(width: 10),
                detailBox(
                  label: 'Available Stock',
                  value:
                      '${formatNumber(product.availableQuantity)} ${product.quantityUnit}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            notesBox(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMoreInfo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF146BFF),
                      side: const BorderSide(
                        color: Color(0xFF146BFF),
                      ),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'More Info',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canOrder ? onOrderNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF146BFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCAD6E0),
                      disabledForegroundColor: const Color(0xFF7B8FA3),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      canOrder ? 'Order Now' : 'Out of Stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (supplierId.trim().isEmpty) {
      return sheetContent(
        context,
        supplier,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(supplierId.trim())
          .snapshots(),
      builder: (context, snapshot) {
        final activeSupplier = supplierFromData(
          snapshot.data?.data(),
        );

        return sheetContent(
          context,
          activeSupplier,
        );
      },
    );
  }
}

class ProductSheetEmojiFallback extends StatelessWidget {
  const ProductSheetEmojiFallback({
    super.key,
    required this.emoji,
  });

  final String emoji;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFEAF7FB),
      child: Center(
        child: Text(
          emoji.trim().isEmpty ? '🐟' : emoji,
          style: const TextStyle(
            fontSize: 36,
          ),
        ),
      ),
    );
  }
}
