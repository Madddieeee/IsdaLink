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

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _mobilePattern = RegExp(r'^(09\d{9}|\+639\d{9})$');
  static final RegExp _permitPattern = RegExp(r'^[A-Za-z0-9-]+$');

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
    final supplierDocument = await firestore
        .collection('supplierProfiles')
        .doc(user.uid)
        .get();
    final supplierData = supplierDocument.data();

    if (!supplierDocument.exists ||
        supplierData == null ||
        getStringValue(supplierData, 'status', '').toLowerCase() !=
            'rejected') {
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

    final unseenRejections =
        notificationSnapshot.docs
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
          ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));

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
    final belongsToActiveRejection =
        activeReason == reason &&
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

    await notificationReference.update(<String, dynamic>{
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'rejectionReasonViewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitSupplierApplication({
    required User user,
    required SupplierApplicationInput input,
  }) async {
    // Refresh the Firebase Auth token before Firestore evaluates the
    // application transaction. This is especially important after an admin
    // rejection because the app may still hold an older cached ID token.
    await user.getIdToken(true);

    _validateApplication(user: user, input: input);

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
    final supplierReference = firestore
        .collection('supplierProfiles')
        .doc(user.uid);

    await firestore.runTransaction((transaction) async {
      final userDocument = await transaction.get(userReference);
      final supplierDocument = await transaction.get(supplierReference);
      final userData = userDocument.data();

      if (!userDocument.exists || userData == null) {
        throw StateError(
          'Your account profile could not be found. Sign out, sign in again, and retry.',
        );
      }

      final currentStatus = getStringValue(
        userData,
        'supplierStatus',
        'not_applicable',
      ).toLowerCase();
      final currentProfileStatus = getStringValue(
        supplierDocument.data(),
        'status',
        'not_applicable',
      ).toLowerCase();

      if (currentStatus == 'approved') {
        throw StateError('This account is already approved as a supplier.');
      }

      if (currentStatus == 'pending') {
        throw StateError(
          'This account already has a pending supplier application.',
        );
      }

      if (currentProfileStatus == 'approved') {
        throw StateError('This supplier profile is already approved.');
      }

      if (currentProfileStatus == 'pending') {
        throw StateError(
          'This account already has a pending supplier application.',
        );
      }

      final accountCreatedAt = userData['createdAt'];
      final supplierCreatedAt = supplierDocument.data()?['createdAt'];
      final accountEmail = user.email!.trim();
      final applicationData = <String, dynamic>{
        'ownerName': input.ownerName.trim(),
        'ownerAddress': input.ownerAddress.trim(),
        // Store the exact authenticated address. Firestore rules compare this
        // value with the email claim in the current authentication token.
        'email': accountEmail,
        'contactNumber': input.contactNumber.trim(),
        'phone': input.contactNumber.trim(),
        'storeName': input.businessName.trim(),
        'supplierName': input.businessName.trim(),
        'businessName': input.businessName.trim(),
        'supplierType': 'Fish Supplier',
        'region': 'Caraga Region',
        'storeProvince': input.storeProvince?.trim(),
        'storeCityMunicipality': input.storeCityMunicipality.trim(),
        'storeAddress': input.storeAddress.trim(),
        'storeLatitude': input.storeLatitude,
        'storeLongitude': input.storeLongitude,
        'location': input.storeLocation,
        'storeLocation': input.storeLocation,
        'primaryMarketArea': input.primaryMarketArea.trim(),
        'serviceArea': input.primaryMarketArea.trim(),
        'description': input.storeDescription.trim(),
        'businessPermitNumber': input.businessPermitNumber.trim(),
        'businessPermitUrl': input.businessPermitUrl.trim(),
        'businessPermitStoragePath': input.businessPermitStoragePath.trim(),
        // Verification evidence only. Public storefront branding is set by
        // the approved supplier later from their own store page.
        'storePhotoUrl': input.storePhotoUrl.trim(),
        'hasBusinessPermit': true,
        'hasStorePhoto': true,
        'verificationStatus': 'pending',
        'paymentMethod': 'COD',
        'applicationVersion': 6,
        // Some older/test accounts may have createdAt in a legacy format.
        // Firestore rules accept accountCreatedAt only when it is a Timestamp,
        // so omit it rather than copying an incompatible value.
        if (accountCreatedAt is Timestamp) 'accountCreatedAt': accountCreatedAt,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      transaction.set(supplierReference, <String, dynamic>{
        'uid': user.uid,
        ...applicationData,
        // Remove the retired supplier-wide preference from older applications.
        // Selling units now belong only to individual fish-stock posts.
        'supportedUnits': FieldValue.delete(),
        'status': 'pending',
        if (currentStatus == 'rejected' ||
            currentStatus == 'declined') ...<String, dynamic>{
          'rejectionReason': FieldValue.delete(),
          'rejectedBy': FieldValue.delete(),
          'rejectedAt': FieldValue.delete(),
        },
        // Normalize legacy supplier drafts whose createdAt value is
        // missing or is not a Firestore Timestamp.
        if (!supplierDocument.exists || supplierCreatedAt is! Timestamp)
          'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(userReference, <String, dynamic>{
        'name': input.ownerName.trim(),
        'email': accountEmail,
        'phone': input.contactNumber.trim(),
        'supplierLocation': input.storeLocation,
        'region': 'Caraga Region',
        'supplierStatus': 'pending',
        'supplierApplication': applicationData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void _validateApplication({
    required User user,
    required SupplierApplicationInput input,
  }) {
    final email = input.email.trim();
    final authenticatedEmail = user.email?.trim() ?? '';
    final contact = input.contactNumber.trim();
    final permitUrl = input.businessPermitUrl.trim();
    final permitPath = input.businessPermitStoragePath.trim();
    final expectedPermitPrefix = 'supplier_verification/${user.uid}/permits/';

    if (input.ownerName.trim().length < 2 ||
        input.ownerName.trim().length > 80) {
      throw StateError('Enter a valid owner name using 2 to 80 characters.');
    }
    if (input.ownerAddress.trim().length < 5 ||
        input.ownerAddress.trim().length > 180) {
      throw StateError('Enter a valid owner address.');
    }
    if (!_emailPattern.hasMatch(email) ||
        authenticatedEmail.isEmpty ||
        email.toLowerCase() != authenticatedEmail.toLowerCase()) {
      throw StateError('Use the email address registered to this account.');
    }
    if (!_mobilePattern.hasMatch(contact)) {
      throw StateError('Enter a valid Philippine mobile number.');
    }
    if (input.businessName.trim().length < 2 ||
        input.businessName.trim().length > 100) {
      throw StateError('Enter a valid business or store name.');
    }
    if (input.storeAddress.trim().length < 5 ||
        input.storeAddress.trim().length > 180) {
      throw StateError('Enter a valid store address.');
    }
    if (input.primaryMarketArea.trim().length < 2 ||
        input.primaryMarketArea.trim().length > 100) {
      throw StateError('Enter a valid primary market area.');
    }
    if (input.storeDescription.trim().length < 8 ||
        input.storeDescription.trim().length > 240) {
      throw StateError('Use 8 to 240 characters for the store description.');
    }
    final permitNumber = input.businessPermitNumber.trim();
    if (permitNumber.length < 6 ||
        permitNumber.length > 30 ||
        !_permitPattern.hasMatch(permitNumber)) {
      throw StateError('Enter a valid business permit number.');
    }
    if (permitPath.isEmpty && !permitUrl.startsWith('https://')) {
      throw StateError('Upload a valid business permit photo.');
    }
    if (permitPath.isNotEmpty && !permitPath.startsWith(expectedPermitPrefix)) {
      throw StateError('Upload the business permit again for this account.');
    }
    if (!input.storePhotoUrl.trim().startsWith('https://')) {
      throw StateError('Upload a valid verification store photo.');
    }
  }
}
