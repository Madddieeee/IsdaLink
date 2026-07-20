import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardService {
  const AdminDashboardService();

  Stream<QuerySnapshot<Map<String, dynamic>>> get usersStream {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get supplierProfilesStream {
    return FirebaseFirestore.instance.collection('supplierProfiles').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get fishStocksStream {
    return FirebaseFirestore.instance.collection('fishStocks').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get ordersStream {
    return FirebaseFirestore.instance.collection('orders').snapshots();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
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

  Future<void> approveSupplier(
    QueryDocumentSnapshot<Map<String, dynamic>> supplierDocument,
  ) async {
    final data = supplierDocument.data();

    final uid = getStringValue(
      data,
      'uid',
      supplierDocument.id,
    );

    final batch = FirebaseFirestore.instance.batch();

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final supplierRef =
        FirebaseFirestore.instance.collection('supplierProfiles').doc(uid);

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
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
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

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final supplierRef =
        FirebaseFirestore.instance.collection('supplierProfiles').doc(uid);

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

    await batch.commit();
  }
}
