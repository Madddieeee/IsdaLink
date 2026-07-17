import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/utils/order_helpers.dart';

class FishStockInput {
  const FishStockInput({
    required this.productName,
    required this.description,
    required this.category,
    required this.unit,
    required this.emoji,
    required this.price,
    required this.quantity,
    required this.lowStockLevel,
  });

  final String productName;
  final String description;
  final String category;
  final String unit;
  final String emoji;
  final double price;
  final double quantity;
  final double lowStockLevel;
}

class FishStockService {
  const FishStockService();

  Future<
    void
  >
  createFishStockPost({
    required User user,
    required FishStockInput input,
  }) async {
    final userDocument = await FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          user.uid,
        )
        .get();

    final supplierProfileDocument = await FirebaseFirestore.instance
        .collection(
          'supplierProfiles',
        )
        .doc(
          user.uid,
        )
        .get();

    final userData =
        userDocument.data() ??
        <
          String,
          dynamic
        >{};
    final supplierProfileData =
        supplierProfileDocument.data() ??
        <
          String,
          dynamic
        >{};

    final role = OrderHelpers.getStringValue(
      userData,
      'role',
      'vendor',
    ).toLowerCase();

    final supplierStatus = OrderHelpers.getStringValue(
      userData,
      'supplierStatus',
      'not_applicable',
    ).toLowerCase();

    if (role !=
            'supplier' &&
        supplierStatus !=
            'approved') {
      throw Exception(
        'Supplier approval is required before posting fish stock.',
      );
    }

    final supplierName = OrderHelpers.getStringValue(
      supplierProfileData,
      'supplierName',
      OrderHelpers.getStringValue(
        userData,
        'name',
        user.displayName ??
            user.email ??
            'Registered Supplier',
      ),
    );

    final supplierLocation = OrderHelpers.getStringValue(
      supplierProfileData,
      'location',
      'Caraga Region',
    );

    final supplierContactNumber = OrderHelpers.getStringValue(
      supplierProfileData,
      'phone',
      OrderHelpers.getStringValue(
        supplierProfileData,
        'contactNumber',
        OrderHelpers.getStringValue(
          userData,
          'phone',
          '',
        ),
      ),
    );

    await FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .add(
          {
            'productName': input.productName,
            'category': input.category,
            'description': input.description,
            'emoji': input.emoji,
            'price': input.price,
            'priceUnit': 'per ${input.unit}',
            'quantity': input.quantity,
            'quantityUnit': input.unit,
            'lowStockLevel': input.lowStockLevel,
            'paymentMethod': 'COD',
            'supplierId': user.uid,
            'supplierName': supplierName,
            'supplierLocation': supplierLocation,
            'supplierContactNumber': supplierContactNumber,
            'region': 'Caraga Region',
            'status': 'available',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
  }
}
