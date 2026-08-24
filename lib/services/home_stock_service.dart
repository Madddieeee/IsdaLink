import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_state.dart';

class HomeStockService {
  const HomeStockService();

  static const Duration defaultNewWindow = Duration(hours: 48);

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get recentFishPostsStream {
    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(
          100,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get allFishPostsStream {
    return FirebaseFirestore.instance
        .collection('fishStocks')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> vendorFeedStateStream(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  Future<void> markFishFeedViewed(String userId) async {
    if (userId.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(
          {
            'lastFishFeedViewedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  Map<String, String> supplierImageUrlsById(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    const supplierService = SupplierBrowseService();
    final imageUrls = <String, String>{};

    for (final document in documents) {
      final data = document.data();
      final imageUrl = supplierService.profileImageFromProfile(data).trim();

      if (imageUrl.isEmpty) {
        continue;
      }

      imageUrls[document.id] = imageUrl;

      for (final key in const ['supplierId', 'userId', 'uid']) {
        final supplierId = OrderHelpers.getStringValue(data, key, '');

        if (supplierId.isNotEmpty) {
          imageUrls[supplierId] = imageUrl;
        }
      }
    }

    return imageUrls;
  }

  String supplierImageUrlForStock(
    Map<String, dynamic> data,
    Map<String, String> imageUrlsById,
  ) {
    for (final key in const [
      'supplierStorePhotoUrl',
      'supplierProfileImageUrl',
      'supplierImageUrl',
      'storePhotoUrl',
      'profileImageUrl',
    ]) {
      final imageUrl = OrderHelpers.getStringValue(data, key, '');

      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }

    final supplierId = OrderHelpers.getStringValue(data, 'supplierId', '');
    return imageUrlsById[supplierId] ?? '';
  }

  DateTime? dateTimeValue(dynamic value) {
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

  DateTime feedCutoff(Map<String, dynamic>? userData) {
    return dateTimeValue(userData?['lastFishFeedViewedAt']) ??
        DateTime.now().subtract(defaultNewWindow);
  }

  DateTime? createdAt(Map<String, dynamic> data) {
    return dateTimeValue(data['createdAt']);
  }

  DateTime? restockedAt(Map<String, dynamic> data) {
    return dateTimeValue(data['restockedAt']);
  }

  DateTime? latestActivityAt(Map<String, dynamic> data) {
    final created = createdAt(data);
    final restocked = restockedAt(data);

    if (created == null) {
      return restocked;
    }

    if (restocked == null || !restocked.isAfter(created)) {
      return created;
    }

    return restocked;
  }

  bool isNewListing(
    Map<String, dynamic> data,
    DateTime cutoff,
  ) {
    final created = createdAt(data);
    return created != null && created.isAfter(cutoff);
  }

  bool isRestockedListing(
    Map<String, dynamic> data,
    DateTime cutoff,
  ) {
    final restocked = restockedAt(data);
    final created = createdAt(data);

    return restocked != null &&
        restocked.isAfter(cutoff) &&
        (created == null || restocked.isAfter(created));
  }

  bool isRecentlyNewListing(Map<String, dynamic> data) {
    final recentCutoff = DateTime.now().subtract(defaultNewWindow);
    return isNewListing(data, recentCutoff);
  }

  bool isRecentlyRestockedListing(Map<String, dynamic> data) {
    final recentCutoff = DateTime.now().subtract(defaultNewWindow);
    return isRestockedListing(data, recentCutoff);
  }

  String arrivalBadge(Map<String, dynamic> data) {
    if (isRecentlyRestockedListing(data)) {
      return 'RESTOCKED';
    }

    if (isRecentlyNewListing(data)) {
      return 'NEW';
    }

    return '';
  }

  String activityLabel(Map<String, dynamic> data) {
    final isRestocked = isRecentlyRestockedListing(data);
    final timestamp = isRestocked
        ? restockedAt(data)
        : createdAt(data);
    final prefix = isRestocked ? 'Restocked' : 'Posted';

    if (timestamp == null) {
      return prefix;
    }

    return '$prefix ${relativeTime(timestamp)}';
  }

  String relativeTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> availableStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents, {
    int? limit,
  }) {
    final available = documents.where(isAvailableStock).toList();

    available.sort((first, second) {
      final firstActivity = latestActivityAt(first.data());
      final secondActivity = latestActivityAt(second.data());

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
    });

    if (limit == null || available.length <= limit) {
      return available;
    }

    return available.take(limit).toList();
  }

  int unseenArrivalCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    DateTime cutoff,
  ) {
    return documents.where((document) {
      if (!isAvailableStock(document)) {
        return false;
      }

      final data = document.data();
      return isNewListing(data, cutoff) ||
          isRestockedListing(data, cutoff);
    }).length;
  }

  bool isAvailableStock(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    return StockState.isMarketplaceOrderable(
      document.data(),
    );
  }

  Supplier? supplierForStock(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final supplierName = OrderHelpers.getStringValue(
      data,
      'supplierName',
      'Registered Supplier',
    );
    final supplierLocation = OrderHelpers.getStringValue(
      data,
      'supplierLocation',
      OrderHelpers.getStringValue(
        data,
        'location',
        'Caraga Region',
      ),
    );
    final supplierContactNumber = OrderHelpers.getStringValue(
      data,
      'supplierContactNumber',
      OrderHelpers.getStringValue(
        data,
        'contactNumber',
        'No contact number',
      ),
    );

    return Supplier(
      name: supplierName,
      location: supplierLocation,
      contactNumber: supplierContactNumber,
      description: 'Registered fish supplier in the IsdaLink platform for vendor-supplier coordination.',
      rating: 4.5,
      reviews: 0,
      products: const [],
    );
  }

  FishProduct fishProductFromFirestore(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return FishProduct(
      name: OrderHelpers.getStringValue(
        data,
        'productName',
        'Fish Product',
      ),
      category: OrderHelpers.getStringValue(
        data,
        'category',
        'Fresh Fish',
      ),
      description: OrderHelpers.getStringValue(
        data,
        'description',
        'Fresh fish stock available for vendor orders.',
      ),
      emoji: OrderHelpers.getStringValue(
        data,
        'emoji',
        '🐟',
      ),
      imageUrl: OrderHelpers.getStringValue(
        data,
        'productImageUrl',
        '',
      ),
      price: OrderHelpers.getDoubleValue(
        data,
        'price',
      ),
      priceUnit: OrderHelpers.getStringValue(
        data,
        'priceUnit',
        'per kilo',
      ),
      availableQuantity: OrderHelpers.getDoubleValue(
        data,
        'quantity',
      ),
      quantityUnit: OrderHelpers.getStringValue(
        data,
        'quantityUnit',
        'kilo',
      ),
      lowStockThreshold: OrderHelpers.getDoubleValue(
        data,
        'lowStockLevel',
      ),
    );
  }
}
