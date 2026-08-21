import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class SupplierBrowseService {
  const SupplierBrowseService();

  Stream<QuerySnapshot<Map<String, dynamic>>> get suppliersStream {
    return FirebaseFirestore.instance
        .collection('supplierProfiles')
        // Firestore Rules keep pending/rejected verification records private.
        // Marketplace queries must therefore request approved profiles only.
        .where('status', isEqualTo: 'approved')
        .snapshots();
  }

  String getStringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
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

  double getDoubleValue(
    Map<String, dynamic> data,
    String key,
    double fallback,
  ) {
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
    Map<String, dynamic> data,
    String key,
    int fallback,
  ) {
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

  bool getBoolValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      return normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'approved' ||
          normalized == 'verified';
    }

    return false;
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

    if (value is int) {
      final isMilliseconds = value.abs() >= 100000000000;

      return isMilliseconds
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }

    if (value is double) {
      final integerValue = value.toInt();
      final isMilliseconds = integerValue.abs() >= 100000000000;

      return isMilliseconds
          ? DateTime.fromMillisecondsSinceEpoch(integerValue)
          : DateTime.fromMillisecondsSinceEpoch(integerValue * 1000);
    }

    if (value is String) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }

  DateTime? firstAvailableDateTime(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final parsed = getDateTimeValue(data[key]);

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  Map<String, dynamic>? nestedApplication(
    Map<String, dynamic> data,
  ) {
    final value = data['supplierApplication'];

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  String firstAvailableText(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = getStringValue(data, key, '');

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  String supplierNameFromProfile(
    Map<String, dynamic> data,
  ) {
    final application = nestedApplication(data);

    final directName = firstAvailableText(
      data,
      const [
        'supplierName',
        'storeName',
        'businessName',
        'shopName',
        'name',
      ],
    );

    if (directName.isNotEmpty) {
      return directName;
    }

    if (application != null) {
      return firstAvailableText(
        application,
        const [
          'supplierName',
          'storeName',
          'businessName',
          'shopName',
        ],
        fallback: 'Registered Supplier',
      );
    }

    return 'Registered Supplier';
  }

  String supplierLocationFromProfile(
    Map<String, dynamic> data,
  ) {
    final application = nestedApplication(data);

    final directLocation = firstAvailableText(
      data,
      const [
        'storeLocation',
        'location',
        'businessAddress',
        'storeAddress',
        'address',
        'serviceArea',
      ],
    );

    if (directLocation.isNotEmpty) {
      return directLocation;
    }

    if (application != null) {
      return firstAvailableText(
        application,
        const [
          'location',
          'storeLocation',
          'businessAddress',
          'storeAddress',
          'address',
          'serviceArea',
        ],
        fallback: 'Caraga Region',
      );
    }

    return 'Caraga Region';
  }

  String profileImageFromProfile(
    Map<String, dynamic> data,
  ) {
    final application = nestedApplication(data);

    final directImage = firstAvailableText(
      data,
      const [
        'storePhotoUrl',
        'profileImageUrl',
        'businessPhotoUrl',
        'photoUrl',
        'imageUrl',
      ],
    );

    if (directImage.isNotEmpty) {
      return directImage;
    }

    if (application != null) {
      return firstAvailableText(
        application,
        const [
          'profileImageUrl',
          'storePhotoUrl',
          'businessPhotoUrl',
          'photoUrl',
          'imageUrl',
        ],
      );
    }

    return '';
  }

  double ratingFromProfile(
    Map<String, dynamic> data,
  ) {
    final primary = getDoubleValue(data, 'rating', -1);

    if (primary >= 0) {
      return primary.clamp(0, 5).toDouble();
    }

    final average = getDoubleValue(data, 'averageRating', 0);

    return average.clamp(0, 5).toDouble();
  }

  int reviewCountFromProfile(
    Map<String, dynamic> data,
  ) {
    final reviews = getIntValue(data, 'reviews', -1);

    if (reviews >= 0) {
      return reviews;
    }

    final reviewCount = getIntValue(data, 'reviewCount', -1);

    if (reviewCount >= 0) {
      return reviewCount;
    }

    return getIntValue(data, 'totalReviews', 0);
  }

  Supplier supplierFromProfile(
    Map<String, dynamic> data,
  ) {
    final application = nestedApplication(data);

    final directDescription = firstAvailableText(
      data,
      const [
        'description',
        'storeDescription',
        'businessDescription',
      ],
    );

    final applicationDescription = application == null
        ? ''
        : firstAvailableText(
            application,
            const [
              'description',
              'storeDescription',
              'businessDescription',
            ],
          );

    return Supplier(
      name: supplierNameFromProfile(data),
      location: supplierLocationFromProfile(data),
      contactNumber: firstAvailableText(
        data,
        const [
          'phone',
          'contactNumber',
          'mobileNumber',
        ],
        fallback: application == null
            ? 'No contact number'
            : firstAvailableText(
                application,
                const [
                  'phone',
                  'contactNumber',
                  'mobileNumber',
                ],
                fallback: 'No contact number',
              ),
      ),
      description: directDescription.isNotEmpty
          ? directDescription
          : applicationDescription.isNotEmpty
              ? applicationDescription
              : 'Verified fish supplier serving vendors through IsdaLink.',
      rating: ratingFromProfile(data),
      reviews: reviewCountFromProfile(data),
      products: const <FishProduct>[],
      profileImageUrl: profileImageFromProfile(data),
      accountCreatedAt: firstAvailableDateTime(
        data,
        const [
          'accountCreatedAt',
          'userCreatedAt',
          'registeredAt',
          'createdAt',
        ],
      ),
    );
  }

  bool isApprovedSupplier(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final status = getStringValue(
      data,
      'status',
      '',
    ).toLowerCase();

    final verificationStatus = getStringValue(
      data,
      'verificationStatus',
      '',
    ).toLowerCase();

    return status == 'approved' ||
        status == 'active' ||
        status == 'verified' ||
        verificationStatus == 'approved' ||
        verificationStatus == 'verified' ||
        getBoolValue(data, 'isApproved') ||
        getBoolValue(data, 'isVerified');
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> approvedSuppliers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final approved = documents.where(isApprovedSupplier).toList();

    approved.sort(
      (first, second) {
        final firstSupplier = supplierFromProfile(first.data());
        final secondSupplier = supplierFromProfile(second.data());

        if (firstSupplier.isNewSupplier != secondSupplier.isNewSupplier) {
          return firstSupplier.isNewSupplier ? -1 : 1;
        }

        final ratingComparison =
            secondSupplier.rating.compareTo(firstSupplier.rating);

        if (ratingComparison != 0) {
          return ratingComparison;
        }

        final reviewComparison =
            secondSupplier.reviews.compareTo(firstSupplier.reviews);

        if (reviewComparison != 0) {
          return reviewComparison;
        }

        return firstSupplier.name
            .toLowerCase()
            .compareTo(secondSupplier.name.toLowerCase());
      },
    );

    return approved;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> searchSuppliers({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required String query,
  }) {
    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      return documents;
    }

    return documents.where(
      (document) {
        final data = document.data();
        final supplier = supplierFromProfile(data);
        final ownerName = getStringValue(data, 'ownerName', '');
        final serviceArea = getStringValue(data, 'serviceArea', '');
        final paymentMethod = getStringValue(
          data,
          'paymentMethod',
          'COD',
        );

        final newStatusMatch =
            supplier.isNewSupplier && 'new supplier'.contains(searchText);

        return supplier.name.toLowerCase().contains(searchText) ||
            supplier.location.toLowerCase().contains(searchText) ||
            supplier.description.toLowerCase().contains(searchText) ||
            ownerName.toLowerCase().contains(searchText) ||
            serviceArea.toLowerCase().contains(searchText) ||
            paymentMethod.toLowerCase().contains(searchText) ||
            newStatusMatch;
      },
    ).toList();
  }
}
