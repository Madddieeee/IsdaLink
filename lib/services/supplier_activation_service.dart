import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupplierApplicationInput {
  const SupplierApplicationInput({
    required this.ownerName,
    required this.ownerAddress,
    required this.email,
    required this.contactNumber,
    required this.businessName,
    required this.storeLocation,
    required this.serviceArea,
    required this.storeDescription,
    required this.supportedUnits,
    required this.businessPermitNumber,
    required this.businessPermitUrl,
    required this.storePhotoUrl,
  });

  final String ownerName;
  final String ownerAddress;
  final String email;
  final String contactNumber;
  final String businessName;
  final String storeLocation;
  final String serviceArea;
  final String storeDescription;
  final List<String> supportedUnits;
  final String businessPermitNumber;
  final String businessPermitUrl;
  final String storePhotoUrl;
}

class SupplierActivationService {
  const SupplierActivationService();

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

  Future<void> submitSupplierApplication({
    required User user,
    required SupplierApplicationInput input,
  }) async {
    final userReference = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final supplierProfileReference = FirebaseFirestore.instance
        .collection('supplierProfiles')
        .doc(user.uid);

    final userDocument = await userReference.get();
    final userData = userDocument.data();

    final currentSupplierStatus = getStringValue(
      userData,
      'supplierStatus',
      'not_applicable',
    ).toLowerCase();

    if (currentSupplierStatus == 'approved') {
      throw Exception(
        'This account is already approved as a supplier.',
      );
    }

    if (currentSupplierStatus == 'pending') {
      throw Exception(
        'This account already has a pending supplier application.',
      );
    }

    final applicationData = {
      'ownerName': input.ownerName,
      'ownerAddress': input.ownerAddress,
      'email': input.email,
      'contactNumber': input.contactNumber,
      'phone': input.contactNumber,
      'storeName': input.businessName,
      'supplierName': input.businessName,
      'businessName': input.businessName,
      'supplierType': 'Fish Supplier',
      'location': input.storeLocation,
      'storeLocation': input.storeLocation,
      'serviceArea': input.serviceArea,
      'description': input.storeDescription,
      'supportedUnits': input.supportedUnits,
      'businessPermitNumber': input.businessPermitNumber,
      'businessPermitUrl': input.businessPermitUrl,
      'storePhotoUrl': input.storePhotoUrl,
      'profileImageUrl': input.storePhotoUrl,
      'hasBusinessPermit': true,
      'hasStorePhoto': true,
      'verificationStatus': 'pending',
      'paymentMethod': 'COD',
      'submittedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        transaction.set(
          supplierProfileReference,
          {
            'uid': user.uid,
            'supplierName': input.businessName,
            'storeName': input.businessName,
            'businessName': input.businessName,
            'supplierType': 'Fish Supplier',
            'ownerName': input.ownerName,
            'ownerAddress': input.ownerAddress,
            'email': input.email,
            'phone': input.contactNumber,
            'contactNumber': input.contactNumber,
            'location': input.storeLocation,
            'storeLocation': input.storeLocation,
            'serviceArea': input.serviceArea,
            'description': input.storeDescription,
            'supportedUnits': input.supportedUnits,
            'businessPermitNumber': input.businessPermitNumber,
            'businessPermitUrl': input.businessPermitUrl,
            'storePhotoUrl': input.storePhotoUrl,
            'profileImageUrl': input.storePhotoUrl,
            'hasBusinessPermit': true,
            'hasStorePhoto': true,
            'verificationStatus': 'pending',
            'paymentMethod': 'COD',
            'status': 'pending',
            'submittedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          userReference,
          {
            'name': input.ownerName,
            'email': input.email,
            'phone': input.contactNumber,
            'location': input.storeLocation,
            'region': 'Caraga Region',
            'supplierStatus': 'pending',
            'supplierApplication': applicationData,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      },
    );
  }
}
