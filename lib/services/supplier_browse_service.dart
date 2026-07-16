import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class SupplierBrowseService {
  const SupplierBrowseService();

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get suppliersStream {
    return FirebaseFirestore.instance
        .collection(
          'supplierProfiles',
        )
        .snapshots();
  }

  String getStringValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value ==
        null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  double getDoubleValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    double fallback,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value.toDouble();
    }

    if (value
        is double) {
      return value;
    }

    if (value
        is String) {
      return double.tryParse(
            value,
          ) ??
          fallback;
    }

    return fallback;
  }

  int getIntValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    int fallback,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value;
    }

    if (value
        is double) {
      return value.toInt();
    }

    if (value
        is String) {
      return int.tryParse(
            value,
          ) ??
          fallback;
    }

    return fallback;
  }

  Supplier supplierFromProfile(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final supplierName = getStringValue(
      data,
      'supplierName',
      getStringValue(
        data,
        'name',
        'Registered Supplier',
      ),
    );

    return Supplier(
      name: supplierName,
      location: getStringValue(
        data,
        'location',
        'Caraga Region',
      ),
      contactNumber: getStringValue(
        data,
        'phone',
        getStringValue(
          data,
          'contactNumber',
          'No contact number',
        ),
      ),
      description: getStringValue(
        data,
        'description',
        'Registered fish supplier in the IsdaLink platform for vendor-supplier coordination.',
      ),
      rating: getDoubleValue(
        data,
        'rating',
        4.5,
      ),
      reviews: getIntValue(
        data,
        'reviews',
        0,
      ),
      products:
          <
            FishProduct
          >[],
    );
  }

  bool isApprovedSupplier(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final status = getStringValue(
      document.data(),
      'status',
      'approved',
    ).toLowerCase();

    return status ==
            'approved' ||
        status ==
            'active';
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  approvedSuppliers(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final approved = documents
        .where(
          isApprovedSupplier,
        )
        .toList();

    approved.sort(
      (
        a,
        b,
      ) {
        final firstName = getStringValue(
          a.data(),
          'supplierName',
          'Supplier',
        ).toLowerCase();

        final secondName = getStringValue(
          b.data(),
          'supplierName',
          'Supplier',
        ).toLowerCase();

        return firstName.compareTo(
          secondName,
        );
      },
    );

    return approved;
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  searchSuppliers({
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
    required String query,
  }) {
    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      return documents;
    }

    return documents.where(
      (
        document,
      ) {
        final data = document.data();

        final supplierName = getStringValue(
          data,
          'supplierName',
          '',
        ).toLowerCase();

        final ownerName = getStringValue(
          data,
          'ownerName',
          '',
        ).toLowerCase();

        final location = getStringValue(
          data,
          'location',
          '',
        ).toLowerCase();

        final description = getStringValue(
          data,
          'description',
          '',
        ).toLowerCase();

        final paymentMethod = getStringValue(
          data,
          'paymentMethod',
          'COD',
        ).toLowerCase();

        return supplierName.contains(
              searchText,
            ) ||
            ownerName.contains(
              searchText,
            ) ||
            location.contains(
              searchText,
            ) ||
            description.contains(
              searchText,
            ) ||
            paymentMethod.contains(
              searchText,
            );
      },
    ).toList();
  }
}
