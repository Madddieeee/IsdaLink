import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/screens/map/caraga_map_defaults.dart';

class SupplierProfileService {
  const SupplierProfileService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> supplierProfileRef(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('supplierProfiles')
        .doc(uid);
  }

  DocumentReference<Map<String, dynamic>> changeRequestRef(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('supplierChangeRequests')
        .doc(uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(
    String uid,
  ) {
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
    required List<String> supportedUnits,
  }) async {
    await supplierProfileRef(uid).update(
      <String, dynamic>{
        'phone': contactNumber.trim(),
        'contactNumber': contactNumber.trim(),
        'primaryMarketArea': primaryMarketArea.trim(),
        'serviceArea': primaryMarketArea.trim(),
        'description': description.trim(),
        'supportedUnits': supportedUnits,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
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

    await changeRequestRef(uid).set(
      <String, dynamic>{
        'supplierId': uid,
        'supplierName': supplierName.trim(),
        'requestType': 'verified_business_change',
        'status': 'pending',
        'reason': reason.trim(),
        'requestedStoreName': requestedStoreName.trim(),
        'requestedStoreProvince': requestedStoreProvince.trim(),
        'requestedStoreCityMunicipality':
            requestedStoreCityMunicipality.trim(),
        'requestedStoreAddress': requestedStoreAddress.trim(),
        'requestedStoreLatitude': requestedStoreLatitude,
        'requestedStoreLongitude': requestedStoreLongitude,
        'requestedLocation': location,
        'requestedBusinessPermitNumber':
            requestedBusinessPermitNumber.trim(),
        'requestedBusinessPermitUrl': requestedBusinessPermitUrl.trim(),
        'requestedBusinessPermitStoragePath':
            requestedBusinessPermitStoragePath.trim(),
        'requestedStorePhotoUrl': requestedStorePhotoUrl.trim(),
        'changedFields': changedFields,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> withdrawVerifiedChangeRequest({
    required String uid,
  }) async {
    await changeRequestRef(uid).update(
      <String, dynamic>{
        'status': 'withdrawn',
        'withdrawnAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
