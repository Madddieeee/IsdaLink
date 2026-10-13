import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/screens/map/caraga_map_defaults.dart';

class SupplierProfileService {
  const SupplierProfileService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> supplierProfileRef(String uid) {
    return FirebaseFirestore.instance.collection('supplierProfiles').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> changeRequestRef(String uid) {
    return FirebaseFirestore.instance
        .collection('supplierChangeRequests')
        .doc(uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(String uid) {
    return supplierProfileRef(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> changeRequestStream(
    String uid,
  ) {
    return changeRequestRef(uid).snapshots();
  }

  Future<Map<String, dynamic>> loadPrivateSupplierApplication(
    String uid,
  ) async {
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final rawApplication = userDocument.data()?['supplierApplication'];

    if (rawApplication is Map<String, dynamic>) {
      return rawApplication;
    }

    if (rawApplication is Map) {
      return Map<String, dynamic>.from(rawApplication);
    }

    return <String, dynamic>{};
  }

  Future<void> updatePublicStoreInformation({
    required String uid,
    required String contactNumber,
    required String primaryMarketArea,
    required String description,
  }) async {
    final contact = contactNumber.trim();
    final marketArea = primaryMarketArea.trim();
    final storeDescription = description.trim();

    if (currentUser?.uid != uid) {
      throw StateError('Sign in to your supplier account before updating it.');
    }
    if (contact.length < 7 || contact.length > 30) {
      throw StateError('Enter a valid store contact number.');
    }
    if (marketArea.length < 2 || marketArea.length > 120) {
      throw StateError('Enter a valid primary market area.');
    }
    if (storeDescription.length < 8 || storeDescription.length > 240) {
      throw StateError('Use 8 to 240 characters for the store description.');
    }

    final firestore = FirebaseFirestore.instance;
    final stockSnapshot = await firestore
        .collection('fishStocks')
        .where('supplierId', isEqualTo: uid)
        .get();

    if (stockSnapshot.docs.length > 450) {
      throw StateError(
        'This store has too many saved listings to update safely. Please contact the administrator.',
      );
    }

    final batch = firestore.batch();
    batch.update(supplierProfileRef(uid), <String, dynamic>{
      'phone': contact,
      'contactNumber': contact,
      'primaryMarketArea': marketArea,
      'serviceArea': marketArea,
      'description': storeDescription,
      // Clean up the retired supplier-wide field on legacy profiles. Each
      // fish-stock post owns its own kilo, tab, or icebox selection.
      'supportedUnits': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final stockDocument in stockSnapshot.docs) {
      batch.update(stockDocument.reference, <String, dynamic>{
        'supplierContactNumber': contact,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> updateStorefrontImage({
    required String uid,
    required String imageUrl,
    required bool isCover,
  }) async {
    final url = imageUrl.trim();
    if (!url.startsWith('https://')) {
      throw StateError('A valid storefront image is required.');
    }

    final updates = <String, dynamic>{
      isCover ? 'coverImageUrl' : 'profileImageUrl': url,
      // Public storefront branding is independent from supplier verification
      // evidence. Do not mutate any verification/store-photo fields here.
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // This flag distinguishes an owner-selected cover from legacy data where
    // a verification/profile photo may have been copied into the cover field.
    if (isCover) {
      updates['coverImageSetByOwner'] = true;
    }

    await supplierProfileRef(uid).update(updates);
  }

  Future<void> removeStorefrontImage({
    required String uid,
    required bool isCover,
  }) async {
    final updates = <String, dynamic>{
      isCover ? 'coverImageUrl' : 'profileImageUrl': FieldValue.delete(),
      // Removing storefront branding must not alter verification evidence.
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isCover) {
      updates['coverImageSetByOwner'] = FieldValue.delete();
    }

    await supplierProfileRef(uid).update(updates);
  }

  Future<void> submitVerifiedChangeRequest({
    required String uid,
    required String supplierName,
    required String requestedStoreName,
    required String requestedStoreProvince,
    required String requestedStoreCityMunicipality,
    required String requestedStoreAddress,
    required double requestedStoreLatitude,
    required double requestedStoreLongitude,
    required String requestedBusinessPermitNumber,
    required String requestedBusinessPermitUrl,
    required String requestedBusinessPermitStoragePath,
    required String requestedStorePhotoUrl,
    required List<String> changedFields,
    required String reason,
  }) async {
    if (!CaragaMapDefaults.containsCoordinates(
      latitude: requestedStoreLatitude,
      longitude: requestedStoreLongitude,
      province: requestedStoreProvince,
      locality: requestedStoreCityMunicipality,
    )) {
      throw StateError(
        'Choose a business location pin within the selected city or municipality.',
      );
    }

    final location = <String>[
      requestedStoreAddress.trim(),
      requestedStoreCityMunicipality.trim(),
      requestedStoreProvince.trim(),
      'Caraga Region',
    ].where((part) => part.isNotEmpty).join(', ');

    await changeRequestRef(uid).set(<String, dynamic>{
      'supplierId': uid,
      'supplierName': supplierName.trim(),
      'requestType': 'verified_business_change',
      'status': 'pending',
      'reason': reason.trim(),
      'requestedStoreName': requestedStoreName.trim(),
      'requestedStoreProvince': requestedStoreProvince.trim(),
      'requestedStoreCityMunicipality': requestedStoreCityMunicipality.trim(),
      'requestedStoreAddress': requestedStoreAddress.trim(),
      'requestedStoreLatitude': requestedStoreLatitude,
      'requestedStoreLongitude': requestedStoreLongitude,
      'requestedLocation': location,
      'requestedBusinessPermitNumber': requestedBusinessPermitNumber.trim(),
      'requestedBusinessPermitUrl': requestedBusinessPermitUrl.trim(),
      'requestedBusinessPermitStoragePath': requestedBusinessPermitStoragePath
          .trim(),
      'requestedStorePhotoUrl': requestedStorePhotoUrl.trim(),
      'changedFields': changedFields,
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> withdrawVerifiedChangeRequest({required String uid}) async {
    await changeRequestRef(uid).update(<String, dynamic>{
      'status': 'withdrawn',
      'withdrawnAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
