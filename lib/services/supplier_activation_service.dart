import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupplierApplicationInput {
  const SupplierApplicationInput({
    required this.ownerName,
    required this.ownerAddress,
    required this.email,
    required this.contactNumber,
    required this.businessName,
    required this.storeProvince,
    required this.storeCityMunicipality,
    required this.storeAddress,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.primaryMarketArea,
    required this.storeDescription,
    required this.supportedUnits,
    required this.businessPermitNumber,
    required this.businessPermitUrl,
    required this.businessPermitStoragePath,
    required this.storePhotoUrl,
  });

  final String ownerName;
  final String ownerAddress;
  final String email;
  final String contactNumber;
  final String businessName;
  final String? storeProvince;
  final String storeCityMunicipality;
  final String storeAddress;
  final double storeLatitude;
  final double storeLongitude;
  final String primaryMarketArea;
  final String storeDescription;
  final List<String> supportedUnits;
  final String businessPermitNumber;
  final String businessPermitUrl;
  final String businessPermitStoragePath;
  final String storePhotoUrl;

  String get storeLocation {
    final parts = <String>[
      storeAddress.trim(),
      storeCityMunicipality.trim(),
      if (storeProvince != null && storeProvince!.trim().isNotEmpty)
        storeProvince!.trim(),
      'Caraga Region',
    ];

    return parts.where((part) => part.isNotEmpty).join(', ');
  }
}

class SupplierActivationService {
  const SupplierActivationService();

  String getStringValue(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    final text = data?[key]?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Future<Map<String, dynamic>> loadApplicationDefaults(User user) async {
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final supplierDocument = await FirebaseFirestore.instance
        .collection('supplierProfiles')
        .doc(user.uid)
        .get();

    return <String, dynamic>{
      ...?userDocument.data(),
      ...?supplierDocument.data(),
    };
  }

  Future<void> submitSupplierApplication({
    required User user,
    required SupplierApplicationInput input,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final userReference = firestore.collection('users').doc(user.uid);
    final supplierReference =
        firestore.collection('supplierProfiles').doc(user.uid);

    final userDocument = await userReference.get();
    final userData = userDocument.data();
    final currentStatus = getStringValue(
      userData,
      'supplierStatus',
      'not_applicable',
    ).toLowerCase();

    if (currentStatus == 'approved') {
      throw StateError('This account is already approved as a supplier.');
    }

    if (currentStatus == 'pending') {
      throw StateError('This account already has a pending supplier application.');
    }

    final accountCreatedAt = userData?['createdAt'];
    final applicationData = <String, dynamic>{
      'ownerName': input.ownerName,
      'ownerAddress': input.ownerAddress,
      'email': input.email,
      'contactNumber': input.contactNumber,
      'phone': input.contactNumber,
      'storeName': input.businessName,
      'supplierName': input.businessName,
      'businessName': input.businessName,
      'supplierType': 'Fish Supplier',
      'region': 'Caraga Region',
      'storeProvince': input.storeProvince,
      'storeCityMunicipality': input.storeCityMunicipality,
      'storeAddress': input.storeAddress,
      'storeLatitude': input.storeLatitude,
      'storeLongitude': input.storeLongitude,
      'location': input.storeLocation,
      'storeLocation': input.storeLocation,
      'primaryMarketArea': input.primaryMarketArea,
      'serviceArea': input.primaryMarketArea,
      'description': input.storeDescription,
      'supportedUnits': input.supportedUnits,
      'businessPermitNumber': input.businessPermitNumber,
      'businessPermitUrl': input.businessPermitUrl,
      'businessPermitStoragePath': input.businessPermitStoragePath,
      'storePhotoUrl': input.storePhotoUrl,
      'coverImageUrl': input.storePhotoUrl,
      // Preserved for the current supplier cards and profile model.
      'profileImageUrl': input.storePhotoUrl,
      'hasBusinessPermit': true,
      'hasStorePhoto': true,
      'verificationStatus': 'pending',
      'paymentMethod': 'COD',
      'applicationVersion': 4,
      'accountCreatedAt': ?accountCreatedAt,
      'submittedAt': FieldValue.serverTimestamp(),
    };

    await firestore.runTransaction((transaction) async {
      transaction.set(
        supplierReference,
        <String, dynamic>{
          'uid': user.uid,
          ...applicationData,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        userReference,
        <String, dynamic>{
          'name': input.ownerName,
          'email': input.email,
          'phone': input.contactNumber,
          'supplierLocation': input.storeLocation,
          'region': 'Caraga Region',
          'supplierStatus': 'pending',
          'supplierApplication': applicationData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
