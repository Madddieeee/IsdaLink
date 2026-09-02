import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/vendor/place_order_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.supplier,
    required this.product,
    this.stockId = '',
    this.supplierId = '',
  });

  final Supplier supplier;
  final FishProduct product;
  final String stockId;
  final String supplierId;

  bool hasNetworkImage(
    String value,
  ) {
    final text = value.trim();

    return text.startsWith('http://') ||
        text.startsWith('https://');
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

    return text.isEmpty ? fallback : text;
  }

  double getDoubleValue(
    Map<String, dynamic>? data,
    String key,
    double fallback,
  ) {
    if (data == null) {
      return fallback;
    }

    final value = data[key];

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  int getIntValue(
    Map<String, dynamic>? data,
    String key,
    int fallback,
  ) {
    if (data == null) {
      return fallback;
    }

    final value = data[key];

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  DateTime? getDateTimeValue(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String formatPrice(
    double value,
  ) {
    var fixed = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    if (fixed.contains('.')) {
      fixed = fixed.replaceFirst(RegExp(r'0+$'), '');
      fixed = fixed.replaceFirst(RegExp(r'\.$'), '');
    }

    final parts = fixed.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();

    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(whole[index]);
    }

    return parts.length > 1
        ? '${grouped.toString()}.${parts[1]}'
        : grouped.toString();
  }

  String compactPriceUnit(
    String value,
  ) {
    var unit = cleanUnit(value).trim();

    if (unit.toLowerCase().startsWith('per ')) {
      unit = unit.substring(4).trim();
    } else if (unit.startsWith('/')) {
      unit = unit.substring(1).trim();
    }

    return unit.isEmpty ? '' : '/ $unit';
  }

  String cleanUnit(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return 'per ${product.quantityUnit}';
    }

    return normalized;
  }

  String profileImageFromData(
    Map<String, dynamic>? data,
  ) {
    final storePhotoUrl = getStringValue(
      data,
      'storePhotoUrl',
      '',
    );

    if (storePhotoUrl.isNotEmpty) {
      return storePhotoUrl;
    }

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

    final application = data?['supplierApplication'];

    if (application is Map<String, dynamic>) {
      return getStringValue(
        application,
        'storePhotoUrl',
        supplier.profileImageUrl,
      );
    }

    if (application is Map) {
      return getStringValue(
        Map<String, dynamic>.from(application),
        'storePhotoUrl',
        supplier.profileImageUrl,
      );
    }

    return supplier.profileImageUrl;
  }

  String productImageFromData(
    Map<String, dynamic>? data,
  ) {
    const keys = [
      'productImageUrl',
      'imageUrl',
      'photoUrl',
      'fishImageUrl',
    ];

    for (final key in keys) {
      final value = getStringValue(
        data,
        key,
        '',
      );

      if (value.isNotEmpty) {
        return value;
      }
    }

    return product.imageUrl;
  }

  Supplier supplierFromProfile(
    Map<String, dynamic>? data,
  ) {
    final directRating = getDoubleValue(
      data,
      'rating',
      -1,
    );

    final rating = directRating >= 0
        ? directRating
        : getDoubleValue(
            data,
            'averageRating',
            supplier.rating,
          );

    final directReviews = getIntValue(
      data,
      'reviews',
      -1,
    );

    final reviews = directReviews >= 0
        ? directReviews
        : getIntValue(
            data,
            'reviewCount',
            supplier.reviews,
          );

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
        'storeLocation',
        getStringValue(
          data,
          'location',
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
      rating: rating.clamp(0, 5).toDouble(),
      reviews: reviews < 0 ? 0 : reviews,
      products: supplier.products,
      profileImageUrl: profileImageFromData(data),
      accountCreatedAt: getDateTimeValue(
            data?['accountCreatedAt'],
          ) ??
          supplier.accountCreatedAt,
    );
  }

  FishProduct productFromStock(
    Map<String, dynamic>? data,
  ) {
    return FishProduct(
      name: getStringValue(
        data,
        'productName',
        product.name,
      ),
      category: getStringValue(
        data,
        'category',
        product.category,
      ),
      description: getStringValue(
        data,
        'description',
        product.description,
      ),
      emoji: getStringValue(
        data,
        'emoji',
        product.emoji,
      ),
      imageUrl: productImageFromData(data),
      price: getDoubleValue(
        data,
        'price',
        product.price,
      ),
      priceUnit: getStringValue(
        data,
        'priceUnit',
        product.priceUnit,
      ),
      availableQuantity: getDoubleValue(
        data,
        'quantity',
        product.availableQuantity,
      ),
      quantityUnit: getStringValue(
        data,
        'quantityUnit',
        product.quantityUnit,
      ),
      lowStockThreshold: getDoubleValue(
        data,
        'lowStockLevel',
        product.lowStockThreshold,
      ),
    );
  }

  DateTime? listingDate(
    Map<String, dynamic>? data,
  ) {
    return getDateTimeValue(
          data?['updatedAt'],
        ) ??
        getDateTimeValue(
          data?['createdAt'],
        );
  }

  String listingDateLabel(
    DateTime? value,
  ) {
    if (value == null) {
      return 'Current';
    }

    final localDate = value.toLocal();
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final date = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final difference = today.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

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

    return '${months[localDate.month - 1]} '
        '${localDate.day}, ${localDate.year}';
  }

  String listingSupplierId(
    Map<String, dynamic>? stockData,
  ) {
    return getStringValue(
      stockData,
      'supplierId',
      supplierId,
    ).trim();
  }

  bool isOwnListing(
    Map<String, dynamic>? stockData,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final ownerUid = listingSupplierId(stockData);

    return currentUid != null &&
        ownerUid.isNotEmpty &&
        currentUid == ownerUid;
  }

  void openManageProducts(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupplierManageProductsScreen(),
      ),
    );
  }

  Widget ownerListingNotice() {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFE8F8F2),
            Color(0xFFEDF8FF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCDE8DD),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(13),
                ),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: Color(0xFF147D64),
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Product Listing',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'You are viewing your own store listing. Ordering is disabled for supplier-owned products.',
                  style: TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 9.3,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void openCheckout(
    BuildContext context,
    Supplier activeSupplier,
    FishProduct activeProduct,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null &&
        supplierId.trim().isNotEmpty &&
        currentUid == supplierId.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot place an order from your own supplier store.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (activeProduct.availableQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This fish listing is currently out of stock.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(
          milliseconds: 430,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 320,
        ),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return PlaceOrderScreen(
            supplier: activeSupplier,
            product: activeProduct,
            stockId: stockId,
            supplierId: supplierId,
          );
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void openSupplierStore(
    BuildContext context,
    Supplier activeSupplier,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailsScreen(
          supplier: activeSupplier,
          supplierId: supplierId,
        ),
      ),
    );
  }

  Widget productImage(
    FishProduct activeProduct, {
    double width = 176,
    double height = 176,
    double borderRadius = 29,
    bool showShadow = true,
  }) {
    final imageUrl = activeProduct.imageUrl.trim();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x35001B33),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 4),
        child: hasNetworkImage(imageUrl)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return ProductEmojiFallback(
                    emoji: activeProduct.emoji,
                    size: (width < height ? width : height) * 0.22,
                    loading: true,
                  );
                },
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return ProductEmojiFallback(
                    emoji: activeProduct.emoji,
                    size: (width < height ? width : height) * 0.24,
                  );
                },
              )
            : ProductEmojiFallback(
                emoji: activeProduct.emoji,
                size: (width < height ? width : height) * 0.24,
              ),
      ),
    );
  }

  Widget supplierImage(
    Supplier activeSupplier,
  ) {
    final imageUrl = activeSupplier.profileImageUrl.trim();
    final initial = activeSupplier.name.trim().isEmpty
        ? 'S'
        : activeSupplier.name.trim().substring(0, 1).toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDECF4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: hasNetworkImage(imageUrl)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return SupplierInitial(
                    initial: initial,
                  );
                },
              )
            : SupplierInitial(
                initial: initial,
              ),
      ),
    );
  }

  Widget statusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withAlpha(45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }


  Widget productSummaryCard(
    FishProduct activeProduct, {
    required String updatedLabel,
  }) {
    final isOutOfStock = activeProduct.availableQuantity <= 0;
    final isLowStock = !isOutOfStock &&
        activeProduct.availableQuantity <= activeProduct.lowStockThreshold;

    final stockMessage = isOutOfStock
        ? 'Currently unavailable for ordering.'
        : isLowStock
            ? 'Only ${formatNumber(activeProduct.availableQuantity)} ${activeProduct.quantityUnit} left in stock.'
            : '${formatNumber(activeProduct.availableQuantity)} ${activeProduct.quantityUnit} ready for ordering.';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFDCEAF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1000152A),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeProduct.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 26,
              height: 1.04,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  '₱${formatPrice(activeProduct.price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0875D1),
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  compactPriceUnit(activeProduct.priceUnit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeProduct.stockColor.withAlpha(14),
                  const Color(0xFFF8FCFF),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeProduct.stockColor.withAlpha(36),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: activeProduct.stockColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: activeProduct.stockColor,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    stockMessage,
                    style: const TextStyle(
                      color: Color(0xFF31566F),
                      fontSize: 10.8,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFDFE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE1ECF2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF0875D1),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Payment',
                              style: TextStyle(
                                color: Color(0xFF8397A7),
                                fontSize: 8.7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Cash on Delivery',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 10.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFFDDEAF1),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF11A87A),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Last updated',
                              style: TextStyle(
                                color: Color(0xFF8397A7),
                                fontSize: 8.7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              updatedLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 10.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget supplierCard(
    BuildContext context,
    Supplier activeSupplier,
  ) {
    final hasReviews =
        activeSupplier.rating > 0 && activeSupplier.reviews > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: () => openSupplierStore(
          context,
          activeSupplier,
        ),
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: const Color(0xFFE0ECF3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C00152A),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              supplierImage(activeSupplier),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUPPLIED BY',
                      style: TextStyle(
                        color: Color(0xFF8CA0AE),
                        fontSize: 8.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.85,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activeSupplier.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 15.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF11A87A),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF7B8FA3),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activeSupplier.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF52677A),
                              fontSize: 10.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          hasReviews
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFB703),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasReviews
                                ? '${activeSupplier.rating.toStringAsFixed(1)} · ${activeSupplier.reviews} review${activeSupplier.reviews == 1 ? '' : 's'}'
                                : 'No reviews yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF62798B),
                              fontSize: 9.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8F8FD),
                      Color(0xFFDDF4FC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF087AC0),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget informationRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF087AC0),
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 82,
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 10.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 11.3,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 40,
            color: Color(0xFFE6EEF3),
          ),
      ],
    );
  }

  Widget productInformationCard(
    FishProduct activeProduct,
  ) {
    final rawDescription = activeProduct.description.trim();
    final productName = activeProduct.name.trim().toLowerCase();
    final normalizedDescription = rawDescription.toLowerCase();

    final hasMeaningfulDescription = rawDescription.isNotEmpty &&
        normalizedDescription != productName &&
        normalizedDescription != activeProduct.category.trim().toLowerCase() &&
        normalizedDescription != 'fresh fish';

    Widget informationTile({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6FAFD),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE5EEF4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF087AC0),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE0ECF3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0900152A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF087AC0),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Product Information',
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              informationTile(
                icon: Icons.category_outlined,
                label: 'Category',
                value: activeProduct.category,
              ),
              const SizedBox(width: 9),
              informationTile(
                icon: Icons.scale_outlined,
                label: 'Selling unit',
                value: cleanUnit(activeProduct.priceUnit),
              ),
            ],
          ),
          if (hasMeaningfulDescription) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFD),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFE5EEF4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    color: Color(0xFF087AC0),
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 8.7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rawDescription,
                          style: const TextStyle(
                            color: Color(0xFF31566F),
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget compactOrderStep({
    required String number,
    required String title,
    required String description,
    required bool showConnector,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 29,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0875D1),
                        Color(0xFF12A7D8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8DDF2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: showConnector ? 10 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF62798B),
                      fontSize: 9.7,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget orderingGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FAFF),
            Color(0xFFFAFDFF),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFD7ECF7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF087AC0),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'How ordering works',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _CodOnlyPill(),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Review your order, track updates in My Orders, then pay after delivery is completed.',
            style: TextStyle(
              color: Color(0xFF5E7688),
              fontSize: 10.2,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 13),
          compactOrderStep(
            number: '1',
            title: 'Review checkout',
            description: 'Confirm quantity and buyer details.',
            showConnector: true,
          ),
          compactOrderStep(
            number: '2',
            title: 'Track in My Orders',
            description: 'Wait for the supplier status update.',
            showConnector: true,
          ),
          compactOrderStep(
            number: '3',
            title: 'Pay on delivery',
            description: 'Pay after the order is received.',
            showConnector: false,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget productAppBar(
    BuildContext context,
    FishProduct activeProduct, {
    required bool collapsed,
  }) {
    final compactUnit = compactPriceUnit(activeProduct.priceUnit);

    return PreferredSize(
      preferredSize: const Size.fromHeight(62),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF06355F),
              Color(0xFF0875D1),
              Color(0xFF0A94E8),
            ],
            stops: [0, 0.66, 1],
          ),
        ),
        child: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 62,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF06355F),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          titleSpacing: 2,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: collapsed
                ? Text(
                    activeProduct.name,
                    key: const ValueKey('product-name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  )
                : const Text(
                    'Product Details',
                    key: ValueKey('product-details'),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(9),
            child: Material(
              color: Colors.white.withAlpha(32),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 21,
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: collapsed
                      ? Container(
                          key: const ValueKey('collapsed-price'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(28),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withAlpha(38),
                            ),
                          ),
                          child: Text(
                            '₱${formatPrice(activeProduct.price)}$compactUnit',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : Container(
                          key: const ValueKey('cod-pill'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(28),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withAlpha(38),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'COD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget productHero(
    FishProduct activeProduct,
  ) {
    final tag = stockId.isEmpty
        ? '${supplier.name}-${activeProduct.name}'
        : stockId;

    final isOutOfStock = activeProduct.availableQuantity <= 0;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 330,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF06355F),
                      Color(0xFF0875D1),
                      Color(0xFF12B6D6),
                    ],
                    stops: [0, 0.57, 1],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ProductHeaderBackdropPainter(),
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              top: 34,
              child: Hero(
                tag: 'product-image-$tag',
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    productImage(
                      activeProduct,
                      width: double.infinity,
                      height: 230,
                      borderRadius: 30,
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(238),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withAlpha(220),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2300152A),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOutOfStock
                                  ? Icons.block_rounded
                                  : Icons.check_circle_rounded,
                              color: isOutOfStock
                                  ? const Color(0xFF718391)
                                  : const Color(0xFF1976B8),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              activeProduct.stockStatus,
                              style: TextStyle(
                                color: isOutOfStock
                                    ? const Color(0xFF617381)
                                    : const Color(0xFF234D70),
                                fontSize: 10.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 33,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ProductHeaderWavePainter(),
                ),
              ),
            ),
            Positioned(
              left: 28,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2D6F9C),
                      Color(0xFF3A82AF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withAlpha(120),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2200152A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  activeProduct.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomOrderBar(
    BuildContext context,
    Supplier activeSupplier,
    FishProduct activeProduct, {
    required bool ownerListing,
  }) {
    final isOutOfStock = activeProduct.availableQuantity <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2100152A),
            blurRadius: 22,
            offset: Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${formatPrice(activeProduct.price)}',
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    compactPriceUnit(activeProduct.priceUnit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 9.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              flex: 8,
              child: SizedBox(
                height: 49,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ownerListing
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF147D64),
                              Color(0xFF1AAA82),
                            ],
                          )
                        : isOutOfStock
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFFCAD6E0),
                                  Color(0xFFB9C7D2),
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF0875D1),
                                  Color(0xFF0B88E8),
                                ],
                              ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isOutOfStock && !ownerListing
                        ? null
                        : [
                            BoxShadow(
                              color: ownerListing
                                  ? const Color(0x32147D64)
                                  : const Color(0x360875D1),
                              blurRadius: 13,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: ownerListing
                        ? () => openManageProducts(context)
                        : isOutOfStock
                            ? null
                            : () => openCheckout(
                                  context,
                                  activeSupplier,
                                  activeProduct,
                                ),
                    icon: Icon(
                      ownerListing
                          ? Icons.edit_outlined
                          : isOutOfStock
                              ? Icons.block_rounded
                              : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      ownerListing
                          ? 'Manage Product'
                          : isOutOfStock
                              ? 'Out of Stock'
                              : 'Proceed to Checkout',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFF657B8B),
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScaffold(
    BuildContext context,
    Supplier activeSupplier,
    FishProduct activeProduct,
    Map<String, dynamic>? stockData,
  ) {
    final updatedLabel = listingDateLabel(
      listingDate(stockData),
    );
    final ownerListing = isOwnListing(stockData);

    var collapsed = false;

    return StatefulBuilder(
      builder: (
        context,
        setLocalState,
      ) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FB),
          extendBodyBehindAppBar: false,
          appBar: productAppBar(
            context,
            activeProduct,
            collapsed: collapsed,
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final shouldCollapse = notification.metrics.pixels > 318;

              if (shouldCollapse != collapsed) {
                setLocalState(() {
                  collapsed = shouldCollapse;
                });
              }

              return false;
            },
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
          productHero(
            activeProduct,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (ownerListing) ...[
                    ownerListingNotice(),
                    const SizedBox(height: 11),
                  ],
                  productSummaryCard(
                    activeProduct,
                    updatedLabel: updatedLabel,
                  ),
                  const SizedBox(height: 11),
                  supplierCard(
                    context,
                    activeSupplier,
                  ),
                  const SizedBox(height: 11),
                  productInformationCard(
                    activeProduct,
                  ),
                  const SizedBox(height: 11),
                  orderingGuideCard(),
                ],
              ),
            ),
          ),
              ],
            ),
          ),
          bottomNavigationBar: bottomOrderBar(
            context,
            activeSupplier,
            activeProduct,
            ownerListing: ownerListing,
          ),
        );
      },
    );
  }

  Widget buildWithStock(
    BuildContext context,
    Supplier activeSupplier,
  ) {
    if (stockId.trim().isEmpty) {
      return buildScaffold(
        context,
        activeSupplier,
        product,
        null,
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('fishStocks')
          .doc(stockId.trim())
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        final stockData = snapshot.data?.data();
        final activeProduct = productFromStock(
          stockData,
        );

        return buildScaffold(
          context,
          activeSupplier,
          activeProduct,
          stockData,
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (supplierId.trim().isEmpty) {
      return buildWithStock(
        context,
        supplier,
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(supplierId.trim())
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        final data = snapshot.data?.data();

        final activeSupplier = data == null
            ? supplier
            : supplierFromProfile(data);

        return buildWithStock(
          context,
          activeSupplier,
        );
      },
    );
  }
}


class _CodOnlyPill extends StatelessWidget {
  const _CodOnlyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7FD),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'COD only',
        style: TextStyle(
          color: Color(0xFF087AC0),
          fontSize: 8.6,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProductHeaderBackdropPainter extends CustomPainter {
  const _ProductHeaderBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(18);

    fill.color = Colors.white.withAlpha(13);
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.23),
      size.width * 0.23,
      fill,
    );

    fill.color = Colors.white.withAlpha(8);
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.84),
      size.width * 0.18,
      fill,
    );

    fill.color = Colors.white.withAlpha(9);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.56),
      size.width * 0.08,
      fill,
    );

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.23),
      size.width * 0.15,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.23),
      size.width * 0.09,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProductHeaderWavePainter extends CustomPainter {
  const _ProductHeaderWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.08,
        size.width * 0.47,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.76,
        size.width,
        size.height * 0.26,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFF4F8FB),
    );

    final accent = Path()
      ..moveTo(0, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.23,
        size.height * 0.02,
        size.width * 0.49,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.67,
        size.width,
        size.height * 0.18,
      );

    canvas.drawPath(
      accent,
      Paint()
        ..color = Colors.white.withAlpha(115)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProductEmojiFallback extends StatelessWidget {
  const ProductEmojiFallback({
    super.key,
    required this.emoji,
    required this.size,
    this.loading = false,
  });

  final String emoji;
  final double size;
  final bool loading;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFE6F9FF),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 21,
              height: 21,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0A73D8),
              ),
            )
          : Text(
              emoji.trim().isEmpty
                  ? '🐟'
                  : emoji,
              style: TextStyle(
                fontSize: size,
              ),
            ),
    );
  }
}

class SupplierInitial extends StatelessWidget {
  const SupplierInitial({
    super.key,
    required this.initial,
  });

  final String initial;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFEAF8FC),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF087AC0),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
