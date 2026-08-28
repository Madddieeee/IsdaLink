import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteSupplierService {
  FavoriteSupplierService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId {
    final uid = _auth.currentUser?.uid.trim();

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return uid;
  }

  CollectionReference<Map<String, dynamic>> _favoritesCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteSuppliers');
  }

  Stream<Set<String>> get favoriteSupplierIdsStream {
    final userId = currentUserId;

    if (userId == null) {
      return Stream.value(<String>{});
    }

    return _favoritesCollection(userId).snapshots().map(
      (snapshot) => snapshot.docs.map((document) => document.id).toSet(),
    );
  }

  Stream<bool> isFavoriteStream(String supplierId) {
    final userId = currentUserId;
    final cleanSupplierId = supplierId.trim();

    if (userId == null ||
        cleanSupplierId.isEmpty ||
        cleanSupplierId == userId) {
      return Stream.value(false);
    }

    return _favoritesCollection(userId)
        .doc(cleanSupplierId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> setFavorite({
    required String supplierId,
    required bool isFavorite,
  }) async {
    final userId = currentUserId;
    final cleanSupplierId = supplierId.trim();

    if (userId == null) {
      throw StateError('Please sign in again to manage favorite suppliers.');
    }

    if (cleanSupplierId.isEmpty) {
      throw StateError('This supplier could not be identified.');
    }

    if (cleanSupplierId == userId) {
      throw StateError('Your own supplier store cannot be added to favorites.');
    }

    final reference = _favoritesCollection(userId).doc(cleanSupplierId);

    if (!isFavorite) {
      await reference.delete();
      return;
    }

    await reference.set({
      'vendorId': userId,
      'supplierId': cleanSupplierId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleFavorite({
    required String supplierId,
    required bool currentlyFavorite,
  }) {
    return setFavorite(
      supplierId: supplierId,
      isFavorite: !currentlyFavorite,
    );
  }
}
