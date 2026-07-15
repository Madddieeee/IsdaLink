import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupplierApplicationInput {
  const SupplierApplicationInput({
    required this.businessName,
    required this.marketLocation,
    required this.contactNumber,
    required this.supplierType,
    required this.supportedUnits,
  });

  final String businessName;
  final String marketLocation;
  final String contactNumber;
  final String supplierType;
  final List<
    String
  >
  supportedUnits;
}

class SupplierActivationService {
  const SupplierActivationService();

  String getStringValue(
    Map<
      String,
      dynamic
    >?
    data,
    String key,
    String fallback,
  ) {
    if (data ==
        null) {
      return fallback;
    }

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

  Future<
    void
  >
  submitSupplierApplication({
    required User user,
    required SupplierApplicationInput input,
  }) async {
    final userReference = FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          user.uid,
        );

    final supplierProfileReference = FirebaseFirestore.instance
        .collection(
          'supplierProfiles',
        )
        .doc(
          user.uid,
        );

    final userDocument = await userReference.get();
    final userData = userDocument.data();

    final currentSupplierStatus = getStringValue(
      userData,
      'supplierStatus',
      'not_applicable',
    ).toLowerCase();

    if (currentSupplierStatus ==
        'approved') {
      throw Exception(
        'This account is already approved as a supplier.',
      );
    }

    final ownerName = getStringValue(
      userData,
      'name',
      user.displayName ??
          user.email ??
          'Registered User',
    );

    final email = getStringValue(
      userData,
      'email',
      user.email ??
          '',
    );

    final applicationData = {
      'storeName': input.businessName,
      'supplierName': input.businessName,
      'supplierType': input.supplierType,
      'contactNumber': input.contactNumber,
      'phone': input.contactNumber,
      'location': input.marketLocation,
      'description': '${input.supplierType} applying to sell fish supply through IsdaLink.',
      'supportedUnits': input.supportedUnits,
      'paymentMethod': 'COD',
      'submittedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.runTransaction(
      (
        transaction,
      ) async {
        transaction.set(
          supplierProfileReference,
          {
            'uid': user.uid,
            'supplierName': input.businessName,
            'ownerName': ownerName,
            'email': email,
            'phone': input.contactNumber,
            'contactNumber': input.contactNumber,
            'location': input.marketLocation,
            'description': '${input.supplierType} applying to sell fish supply through IsdaLink.',
            'supplierType': input.supplierType,
            'supportedUnits': input.supportedUnits,
            'paymentMethod': 'COD',
            'status': 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        transaction.set(
          userReference,
          {
            'supplierStatus': 'pending',
            'supplierApplication': applicationData,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      },
    );
  }
}
