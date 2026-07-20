import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/utils/order_helpers.dart';

class HomeStockService {
  const HomeStockService();

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
          6,
        )
        .snapshots();
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
    final data = document.data();

    final status = OrderHelpers.getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );

    return (status ==
                'available' ||
            status ==
                'active') &&
        quantity >
            0;
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
