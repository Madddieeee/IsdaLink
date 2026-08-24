import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/services/push_notification_service.dart';

class AdminDashboardService {
  const AdminDashboardService();

  Stream<QuerySnapshot<Map<String, dynamic>>> get usersStream {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get supplierProfilesStream {
    return FirebaseFirestore.instance
        .collection('supplierProfiles')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get supplierChangeRequestsStream {
    return FirebaseFirestore.instance
        .collection('supplierChangeRequests')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get fishStocksStream {
    return FirebaseFirestore.instance.collection('fishStocks').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get ordersStream {
    return FirebaseFirestore.instance.collection('orders').snapshots();
  }

  Future<void> logout() async {
    await PushNotificationService.instance.signOut();
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingSuppliers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> suppliers,
  ) {
    return suppliers.where(
      (document) {
        final status = getStringValue(
          document.data(),
          'status',
          'pending',
        ).toLowerCase();

        return status == 'pending';
      },
    ).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> approvedSuppliers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> suppliers,
  ) {
    return suppliers.where(
      (document) {
        final status = getStringValue(
          document.data(),
          'status',
          'pending',
        ).toLowerCase();

        return status == 'approved' || status == 'active';
      },
    ).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingChangeRequests(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> requests,
  ) {
    final pending = requests.where(
      (document) {
        final status = getStringValue(
          document.data(),
          'status',
          '',
        ).toLowerCase();

        return status == 'pending';
      },
    ).toList();

    pending.sort(
      (a, b) {
        final aValue = a.data()['submittedAt'];
        final bValue = b.data()['submittedAt'];
        final aDate = aValue is Timestamp
            ? aValue.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = bValue is Timestamp
            ? bValue.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      },
    );

    return pending;
  }

  Future<void> approveSupplierChangeRequest(
    String supplierId, {
    String adminNote = '',
  }) async {
    final firestore = FirebaseFirestore.instance;
    final requestRef = firestore
        .collection('supplierChangeRequests')
        .doc(supplierId);
    final supplierRef = firestore
        .collection('supplierProfiles')
        .doc(supplierId);
    final userRef = firestore.collection('users').doc(supplierId);

    final requestSnapshot = await requestRef.get();
    final supplierSnapshot = await supplierRef.get();
    final userSnapshot = await userRef.get();

    final requestData = requestSnapshot.data();
    final supplierData = supplierSnapshot.data();
    final userData = userSnapshot.data();

    if (requestData == null ||
        getStringValue(requestData, 'status', '').toLowerCase() != 'pending') {
      throw StateError('This supplier change request is no longer pending.');
    }

    if (supplierData == null ||
        getStringValue(supplierData, 'status', '').toLowerCase() != 'approved') {
      throw StateError('The supplier profile is not currently approved.');
    }

    final rawChangedFields = requestData['changedFields'];
    final changedFields = rawChangedFields is List
        ? rawChangedFields
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toSet()
        : <String>{};
    final changesStoreName = changedFields.contains('Store name');
    final changesLocation = changedFields.contains('Business location');
    final changesStorePhoto = changedFields.contains('Store photo');
    final changesPermit = changedFields.contains('Business permit');

    if (!changesStoreName &&
        !changesLocation &&
        !changesStorePhoto &&
        !changesPermit) {
      throw StateError('This request does not contain a valid change.');
    }

    final requestedStoreName = getStringValue(
      requestData,
      'requestedStoreName',
      getStringValue(supplierData, 'storeName', 'Fish Supplier'),
    );
    final requestedProvince = getStringValue(
      requestData,
      'requestedStoreProvince',
      getStringValue(supplierData, 'storeProvince', ''),
    );
    final requestedCity = getStringValue(
      requestData,
      'requestedStoreCityMunicipality',
      getStringValue(supplierData, 'storeCityMunicipality', ''),
    );
    final requestedAddress = getStringValue(
      requestData,
      'requestedStoreAddress',
      getStringValue(supplierData, 'storeAddress', ''),
    );
    final requestedLocation = getStringValue(
      requestData,
      'requestedLocation',
      getStringValue(supplierData, 'storeLocation', ''),
    );
    final requestedPermitNumber = getStringValue(
      requestData,
      'requestedBusinessPermitNumber',
      '',
    );
    final requestedPermitUrl = getStringValue(
      requestData,
      'requestedBusinessPermitUrl',
      '',
    );
    final requestedStorePhotoUrl = getStringValue(
      requestData,
      'requestedStorePhotoUrl',
      getStringValue(supplierData, 'storePhotoUrl', ''),
    );
    final requestedLatitude = requestData['requestedStoreLatitude'];
    final requestedLongitude = requestData['requestedStoreLongitude'];

    if (changesLocation &&
        (requestedLatitude is! num || requestedLongitude is! num)) {
      throw StateError('The requested business pin is invalid.');
    }

    final existingApplicationRaw = userData?['supplierApplication'];
    final existingApplication = existingApplicationRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(existingApplicationRaw)
        : existingApplicationRaw is Map
            ? Map<String, dynamic>.from(existingApplicationRaw)
            : <String, dynamic>{};

    final updatedApplication = <String, dynamic>{
      ...existingApplication,
      if (changesStoreName) ...<String, dynamic>{
        'storeName': requestedStoreName,
        'supplierName': requestedStoreName,
        'businessName': requestedStoreName,
      },
      if (changesLocation) ...<String, dynamic>{
        'storeProvince': requestedProvince,
        'storeCityMunicipality': requestedCity,
        'storeAddress': requestedAddress,
        'storeLatitude': (requestedLatitude as num).toDouble(),
        'storeLongitude': (requestedLongitude as num).toDouble(),
        'location': requestedLocation,
        'storeLocation': requestedLocation,
      },
      if (changesPermit) ...<String, dynamic>{
        'businessPermitNumber': requestedPermitNumber,
        'businessPermitUrl': requestedPermitUrl,
        'hasBusinessPermit': true,
      },
      if (changesStorePhoto) ...<String, dynamic>{
        'storePhotoUrl': requestedStorePhotoUrl,
        'coverImageUrl': requestedStorePhotoUrl,
        'profileImageUrl': requestedStorePhotoUrl,
        'photoUrl': requestedStorePhotoUrl,
        'hasStorePhoto': true,
      },
      'verificationStatus': 'approved',
    };

    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = firestore.batch();

    batch.update(
      supplierRef,
      <String, dynamic>{
        if (changesStoreName) ...<String, dynamic>{
          'storeName': requestedStoreName,
          'supplierName': requestedStoreName,
          'businessName': requestedStoreName,
        },
        if (changesLocation) ...<String, dynamic>{
          'storeProvince': requestedProvince,
          'storeCityMunicipality': requestedCity,
          'storeAddress': requestedAddress,
          'storeLatitude': (requestedLatitude as num).toDouble(),
          'storeLongitude': (requestedLongitude as num).toDouble(),
          'location': requestedLocation,
          'storeLocation': requestedLocation,
        },
        if (changesStorePhoto) ...<String, dynamic>{
          'storePhotoUrl': requestedStorePhotoUrl,
          'coverImageUrl': requestedStorePhotoUrl,
          'profileImageUrl': requestedStorePhotoUrl,
          'photoUrl': requestedStorePhotoUrl,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      userRef,
      <String, dynamic>{
        if (changesLocation) 'supplierLocation': requestedLocation,
        'supplierApplication': updatedApplication,
        if (changesStorePhoto) ...<String, dynamic>{
          'profileImageUrl': requestedStorePhotoUrl,
          'photoUrl': requestedStorePhotoUrl,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      requestRef,
      <String, dynamic>{
        'status': 'approved',
        'adminNote': adminNote.trim(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    final notificationRef = firestore.collection('notifications').doc();
    batch.set(
      notificationRef,
      <String, dynamic>{
        'userId': supplierId,
        'supplierId': supplierId,
        'title': 'Supplier profile change approved',
        'message':
            'Your verified supplier business change request was approved and is now visible to vendors.',
        'type': 'supplier_profile_change',
        'status': 'approved',
        'requestId': supplierId,
        'changedFields': changedFields.toList(),
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> rejectSupplierChangeRequest(
    String supplierId, {
    required String adminNote,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final requestRef = firestore
        .collection('supplierChangeRequests')
        .doc(supplierId);
    final requestSnapshot = await requestRef.get();
    final requestData = requestSnapshot.data();

    if (requestData == null ||
        getStringValue(requestData, 'status', '').toLowerCase() != 'pending') {
      throw StateError('This supplier change request is no longer pending.');
    }

    final note = adminNote.trim();

    if (note.length < 3) {
      throw StateError('Add a short rejection reason.');
    }

    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = firestore.batch();

    batch.update(
      requestRef,
      <String, dynamic>{
        'status': 'rejected',
        'adminNote': note,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    final notificationRef = firestore.collection('notifications').doc();
    batch.set(
      notificationRef,
      <String, dynamic>{
        'userId': supplierId,
        'supplierId': supplierId,
        'title': 'Supplier profile change needs revision',
        'message': 'Admin note: $note',
        'type': 'supplier_profile_change',
        'status': 'rejected',
        'requestId': supplierId,
        'changedFields': requestData['changedFields'] is List
            ? List<dynamic>.from(requestData['changedFields'] as List)
            : const <dynamic>[],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> approveSupplier(
    QueryDocumentSnapshot<Map<String, dynamic>> supplierDocument,
  ) async {
    final data = supplierDocument.data();

    final uid = getStringValue(
      data,
      'uid',
      supplierDocument.id,
    );

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid);

    final supplierRef = FirebaseFirestore.instance
        .collection('supplierProfiles')
        .doc(uid);

    final userSnapshot = await userRef.get();
    final accountCreatedAt = userSnapshot.data()?['createdAt'];

    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      userRef,
      {
        'role': 'supplier',
        'supplierStatus': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      supplierRef,
      {
        'status': 'approved',
        'verificationStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'accountCreatedAt': ?accountCreatedAt,

        // Supplier verification evidence remains in the private
        // users/{uid}.supplierApplication record for owner/admin access.
        // It is removed from the approved public supplier profile before
        // marketplace users are allowed to read that profile.
        'ownerAddress': FieldValue.delete(),
        'email': FieldValue.delete(),
        'businessPermitNumber': FieldValue.delete(),
        'businessPermitUrl': FieldValue.delete(),

        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final notificationRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc();

    batch.set(
      notificationRef,
      <String, dynamic>{
        'userId': uid,
        'supplierId': uid,
        'title': 'Supplier application approved',
        'message':
            'Your supplier application was approved. Supplier tools are now available on your account.',
        'type': 'supplier_application_status',
        'status': 'approved',
        'applicationId': uid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> rejectSupplier(
    QueryDocumentSnapshot<Map<String, dynamic>> supplierDocument,
  ) async {
    final data = supplierDocument.data();

    final uid = getStringValue(
      data,
      'uid',
      supplierDocument.id,
    );

    final batch = FirebaseFirestore.instance.batch();

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid);

    final supplierRef = FirebaseFirestore.instance
        .collection('supplierProfiles')
        .doc(uid);

    batch.set(
      userRef,
      {
        'role': 'vendor',
        'supplierStatus': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      supplierRef,
      {
        'status': 'rejected',
        'verificationStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final notificationRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc();

    batch.set(
      notificationRef,
      <String, dynamic>{
        'userId': uid,
        'supplierId': uid,
        'title': 'Supplier application needs revision',
        'message':
            'Your supplier application was not approved. Review your business details before submitting again.',
        'type': 'supplier_application_status',
        'status': 'rejected',
        'applicationId': uid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
}
