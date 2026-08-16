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
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.lowStockLevel,
    this.lowStockPercentage = 20,
  });

  final String productName;
  final String description;
  final String category;
  final String unit;
  final String emoji;
  final String imageUrl;
  final double price;
  final double quantity;
  final double lowStockLevel;
  final double lowStockPercentage;
}

class FishStockService {
  const FishStockService();

  Future<void> createFishStockPost({
    required User user,
    required FishStockInput input,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final userDocument = await firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final supplierProfileDocument = await firestore
        .collection('supplierProfiles')
        .doc(user.uid)
        .get();

    final userData = userDocument.data() ?? <String, dynamic>{};
    final supplierProfileData =
        supplierProfileDocument.data() ?? <String, dynamic>{};

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

    if (role != 'supplier' && supplierStatus != 'approved') {
      throw StateError(
        'Supplier approval is required before posting fish stock.',
      );
    }

    final supplierName = OrderHelpers.getStringValue(
      supplierProfileData,
      'supplierName',
      OrderHelpers.getStringValue(
        userData,
        'name',
        user.displayName ?? user.email ?? 'Registered Supplier',
      ),
    );

    final supplierLocation = OrderHelpers.getStringValue(
      supplierProfileData,
      'location',
      OrderHelpers.getStringValue(
        userData,
        'location',
        'Caraga Region',
      ),
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

    final percentage =
        input.lowStockPercentage.clamp(1, 100).toDouble();
    final computedLevel =
        input.lowStockLevel.clamp(0, input.quantity).toDouble();

    final stockStatus = input.quantity <= 0
        ? 'outOfStock'
        : input.quantity <= computedLevel
            ? 'lowStock'
            : 'available';

    await firestore.collection('fishStocks').add({
      'productName': input.productName,
      'category': input.category,
      'description': input.description,
      'emoji': input.emoji,
      'imageUrl': input.imageUrl,
      'productImageUrl': input.imageUrl,
      'price': input.price,
      'priceUnit': 'per ${input.unit}',
      'quantity': input.quantity,
      'quantityUnit': input.unit,
      'referenceStockQuantity': input.quantity,
      'lowStockPercentage': percentage,
      'lowStockLevel': computedLevel,
      'lowStockAlertEnabled': true,
      'lowStockNotificationEnabled': true,
      'lastLowStockNotificationAt': null,
      'lastLowStockNotificationStatus': null,
      'stockStatus': stockStatus,
      'paymentMethod': 'COD',
      'supplierId': user.uid,
      'supplierName': supplierName,
      'supplierLocation': supplierLocation,
      'supplierContactNumber': supplierContactNumber,
      'region': 'Caraga Region',
      'status': 'available',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
