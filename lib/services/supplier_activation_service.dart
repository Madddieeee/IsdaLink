import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/screens/map/caraga_map_defaults.dart';

class SupplierRejectionNotice {
  const SupplierRejectionNotice({
    required this.notificationId,
    required this.reason,
    required this.createdAtMillis,
  });

  final String notificationId;
  final String reason;
  final int createdAtMillis;
}

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

  Future<SupplierRejectionNotice?> loadUnseenRejectionNotice({
    required User user,
    String notificationId = '',
  }) async {
    final firestore = FirebaseFirestore.instance;
    final supplierDocument =
        await firestore.collection('supplierProfiles').doc(user.uid).get();
    final supplierData = supplierDocument.data();

    if (!supplierDocument.exists ||
        supplierData == null ||
        getStringValue(supplierData, 'status', '').toLowerCase() != 'rejected') {
      return null;
    }

    final activeReason = getStringValue(supplierData, 'rejectionReason', '');
    final rejectedAt = supplierData['rejectedAt'];
    final rejectedAtMillis = rejectedAt is Timestamp
        ? rejectedAt.millisecondsSinceEpoch
        : 0;

    if (activeReason.isEmpty) {
      return null;
    }

    final requestedNotificationId = notificationId.trim();

    if (requestedNotificationId.isNotEmpty) {
      final requestedDocument = await firestore
          .collection('notifications')
          .doc(requestedNotificationId)
          .get();
      final requestedNotice = _rejectionNoticeFromDocument(
        user: user,
        document: requestedDocument,
        activeReason: activeReason,
        rejectedAtMillis: rejectedAtMillis,
      );

      if (requestedNotice != null) {
        return requestedNotice;
      }
    }

    // Manual navigation to the Supplier Application screen does not carry a
    // notification id. Load the user's Firestore notifications and find the
    // newest unseen supplier-application rejection locally so this works from
    // both the in-app Review Application entry point and a push notification.
    final notificationSnapshot = await firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .get();

    final unseenRejections = notificationSnapshot.docs
        .map(
          (document) => _rejectionNoticeFromDocument(
            user: user,
            document: document,
            activeReason: activeReason,
            rejectedAtMillis: rejectedAtMillis,
          ),
        )
        .whereType<SupplierRejectionNotice>()
        .toList()
      ..sort(
        (a, b) => b.createdAtMillis.compareTo(a.createdAtMillis),
      );

    return unseenRejections.isEmpty ? null : unseenRejections.first;
  }

  SupplierRejectionNotice? _rejectionNoticeFromDocument({
    required User user,
    required DocumentSnapshot<Map<String, dynamic>> document,
    required String activeReason,
    required int rejectedAtMillis,
  }) {
    final data = document.data();

    if (!document.exists || data == null) {
      return null;
    }

    final ownerId = getStringValue(data, 'userId', '');
    final type = getStringValue(data, 'type', '').toLowerCase();
    final status = getStringValue(data, 'status', '').toLowerCase();
    final applicationId = getStringValue(data, 'applicationId', user.uid);
    final reason = getStringValue(data, 'rejectionReason', '');
    final createdAt = data['createdAt'];
    final createdAtMillis = createdAt is Timestamp
        ? createdAt.millisecondsSinceEpoch
        : 0;
    final belongsToActiveRejection = activeReason == reason &&
        (rejectedAtMillis == 0 ||
            createdAtMillis == 0 ||
            (createdAtMillis - rejectedAtMillis).abs() <= 300000);

    if (ownerId != user.uid ||
        applicationId != user.uid ||
        type != 'supplier_application_status' ||
        status != 'rejected' ||
        data['rejectionReasonViewedAt'] != null ||
        reason.isEmpty ||
        !belongsToActiveRejection) {
      return null;
    }

    return SupplierRejectionNotice(
      notificationId: document.id,
      reason: reason,
      createdAtMillis: createdAtMillis,
    );
  }

  Future<void> markRejectionReasonViewed({
    required User user,
    required String notificationId,
  }) async {
    final id = notificationId.trim();

    if (id.isEmpty) {
      return;
    }

    final notificationReference = FirebaseFirestore.instance
        .collection('notifications')
        .doc(id);
    final snapshot = await notificationReference.get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return;
    }

    final ownerId = getStringValue(data, 'userId', '');
    final type = getStringValue(data, 'type', '').toLowerCase();
    final status = getStringValue(data, 'status', '').toLowerCase();

    if (ownerId != user.uid ||
        type != 'supplier_application_status' ||
        status != 'rejected') {
      return;
    }

    await notificationReference.update(
      <String, dynamic>{
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'rejectionReasonViewedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> submitSupplierApplication({
    required User user,
    required SupplierApplicationInput input,
  }) async {
    if (!CaragaMapDefaults.containsCoordinates(
      latitude: input.storeLatitude,
      longitude: input.storeLongitude,
      province: input.storeProvince,
      locality: input.storeCityMunicipality,
    )) {
      throw StateError(
        'Choose a business location pin within the selected city or municipality.',
      );
    }

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
          if (currentStatus == 'rejected') ...<String, dynamic>{
            'rejectionReason': FieldValue.delete(),
            'rejectedBy': FieldValue.delete(),
            'rejectedAt': FieldValue.delete(),
          },
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
