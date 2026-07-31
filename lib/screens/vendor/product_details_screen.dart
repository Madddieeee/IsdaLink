import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
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
      return 'Current listing';
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
      return 'Updated today';
    }

    if (difference == 1) {
      return 'Updated yesterday';
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

    return 'Updated ${months[localDate.month - 1]} '
        '${localDate.day}, ${localDate.year}';
  }

  void openCheckout(
    BuildContext context,
    Supplier activeSupplier,
    FishProduct activeProduct,
  ) {
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
    double size = 168,
  }) {
    final imageUrl = activeProduct.imageUrl.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3A001B33),
            blurRadius: 27,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
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
                    size: size * 0.30,
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
                    size: size * 0.34,
                  );
                },
              )
            : ProductEmojiFallback(
                emoji: activeProduct.emoji,
                size: size * 0.34,
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDECF4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
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
    FishProduct activeProduct,
  ) {
    final isOutOfStock =
        activeProduct.availableQuantity <= 0;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE0ECF3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1000152A),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        activeProduct.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF087AC0),
                          fontSize: 9.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      activeProduct.name,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 25,
                        height: 1.06,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              statusChip(
                icon: isOutOfStock
                    ? Icons.cancel_rounded
                    : Icons.check_circle_rounded,
                label: activeProduct.stockStatus,
                color: activeProduct.stockColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${formatNumber(activeProduct.price)}',
                style: const TextStyle(
                  color: Color(0xFF0A73D8),
                  fontSize: 31,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 3,
                ),
                child: Text(
                  cleanUnit(
                    activeProduct.priceUnit,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF1FAFF),
                  Color(0xFFF7FCFF),
                ],
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFD9EDF7),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: activeProduct.stockColor.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: activeProduct.stockColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isOutOfStock
                        ? 'This fish listing is currently unavailable.'
                        : '${formatNumber(activeProduct.availableQuantity)} '
                            '${activeProduct.quantityUnit} available for ordering',
                    style: const TextStyle(
                      color: Color(0xFF31566F),
                      fontSize: 11.6,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget listingMetaCard({
    required String updatedLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE0ECF3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00152A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: metaItem(
              icon: Icons.payments_outlined,
              label: 'Payment',
              value: 'Cash on Delivery',
              iconColor: const Color(0xFF0A73D8),
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: const Color(0xFFDDEAF1),
          ),
          Expanded(
            child: metaItem(
              icon: Icons.schedule_rounded,
              label: 'Listing status',
              value: updatedLabel,
              iconColor: const Color(0xFF11A87A),
            ),
          ),
        ],
      ),
    );
  }

  Widget metaItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8599A8),
                    fontSize: 8.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
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
        activeSupplier.rating > 0 &&
        activeSupplier.reviews > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () => openSupplierStore(
          context,
          activeSupplier,
        ),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
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
          child: Column(
            children: [
              Row(
                children: [
                  supplierImage(activeSupplier),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                activeSupplier.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF102C44),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF11A87A),
                              size: 17,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF7B8FA3),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activeSupplier.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF52677A),
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              hasReviews
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFFFB703),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasReviews
                                  ? '${activeSupplier.rating.toStringAsFixed(1)}  '
                                      '${activeSupplier.reviews} review'
                                      '${activeSupplier.reviews == 1 ? '' : 's'}'
                                  : 'No reviews yet',
                              style: const TextStyle(
                                color: Color(0xFF62798B),
                                fontSize: 10.7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8FD),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFF087AC0),
                      size: 16,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'View Supplier Store',
                      style: TextStyle(
                        color: Color(0xFF087AC0),
                        fontSize: 10.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF087AC0),
                      size: 15,
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

  Widget informationRow({
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0xFFE6EEF3),
          ),
      ],
    );
  }

  Widget productInformationCard(
    FishProduct activeProduct,
  ) {
    final description =
        activeProduct.description.trim().isEmpty
            ? 'Fresh fish stock posted by the supplier for '
                'Cash on Delivery ordering through IsdaLink.'
            : activeProduct.description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        17,
        18,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFE0ECF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF087AC0),
                size: 19,
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
          const SizedBox(height: 9),
          informationRow(
            label: 'Category',
            value: activeProduct.category,
          ),
          informationRow(
            label: 'Selling unit',
            value: cleanUnit(
              activeProduct.priceUnit,
            ),
          ),
          informationRow(
            label: 'Description',
            value: description,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget compactOrderStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF0A73D8),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 1,
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF62798B),
                  fontSize: 10.7,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: '$title  ',
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: description,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget orderingGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF2FAFF),
            Color(0xFFF8FCFF),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFD9EDF7),
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
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Cash on Delivery Process',
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          compactOrderStep(
            number: '1',
            title: 'Review checkout',
            description:
                'Confirm buyer details, quantity, and total.',
          ),
          const SizedBox(height: 12),
          compactOrderStep(
            number: '2',
            title: 'Track the order',
            description:
                'Wait for the supplier update in My Orders.',
          ),
          const SizedBox(height: 12),
          compactOrderStep(
            number: '3',
            title: 'Pay on delivery',
            description:
                'Payment is collected when the order is received.',
          ),
        ],
      ),
    );
  }

  Widget heroHeader(
    BuildContext context,
    FishProduct activeProduct,
  ) {
    final tag = stockId.isEmpty
        ? '${supplier.name}-${activeProduct.name}'
        : stockId;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 270,
      elevation: 0,
      backgroundColor: const Color(0xFF0B3554),
      foregroundColor: Colors.white,
      title: const Text(
        'Product Details',
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white.withAlpha(35),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            tooltip: 'Back',
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: 16,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(34),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: Colors.white.withAlpha(38),
                ),
              ),
              child: const Row(
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
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF073B66),
                Color(0xFF0A73D8),
                Color(0xFF12B6D6),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -52,
                top: 42,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -46,
                bottom: -60,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(14),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(
                  0,
                  0.52,
                ),
                child: Hero(
                  tag: 'product-image-$tag',
                  child: productImage(
                    activeProduct,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomOrderBar(
    BuildContext context,
    Supplier activeSupplier,
    FishProduct activeProduct,
  ) {
    final isOutOfStock =
        activeProduct.availableQuantity <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        11,
        18,
        13,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1B00152A),
            blurRadius: 18,
            offset: Offset(0, -5),
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
                    '₱${formatNumber(activeProduct.price)}',
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cleanUnit(
                      activeProduct.priceUnit,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 10.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 7,
              child: SizedBox(
                height: 53,
                child: ElevatedButton.icon(
                  onPressed: isOutOfStock
                      ? null
                      : () => openCheckout(
                            context,
                            activeSupplier,
                            activeProduct,
                          ),
                  icon: Icon(
                    isOutOfStock
                        ? Icons.block_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isOutOfStock
                        ? 'Out of Stock'
                        : 'Proceed to Checkout',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A73D8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCAD6E0),
                    disabledForegroundColor: const Color(0xFF7B8FA3),
                    elevation: 3,
                    shadowColor: const Color(0x330A73D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          heroHeader(
            context,
            activeProduct,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              17,
              18,
              17,
              28,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  productSummaryCard(
                    activeProduct,
                  ),
                  const SizedBox(height: 14),
                  listingMetaCard(
                    updatedLabel: updatedLabel,
                  ),
                  const SizedBox(height: 14),
                  supplierCard(
                    context,
                    activeSupplier,
                  ),
                  const SizedBox(height: 14),
                  productInformationCard(
                    activeProduct,
                  ),
                  const SizedBox(height: 14),
                  orderingGuideCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomOrderBar(
        context,
        activeSupplier,
        activeProduct,
      ),
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
