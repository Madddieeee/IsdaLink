import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/services/push_notification_service.dart';

class UserProfileService {
  const UserProfileService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<
    DocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >?
  profileStream() {
    final user = currentUser;

    if (user ==
        null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          user.uid,
        )
        .snapshots();
  }

  Future<
    void
  >
  updateProfileImageUrl({
    required String imageUrl,
    required bool isApprovedSupplier,
  }) async {
    final user = currentUser;

    if (user ==
        null) {
      throw Exception(
        'Please log in first.',
      );
    }

    await FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          user.uid,
        )
        .set(
          {
            'profileImageUrl': imageUrl,
            'photoUrl': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

    await user.updatePhotoURL(
      imageUrl,
    );

    if (isApprovedSupplier) {
      await FirebaseFirestore.instance
          .collection(
            'supplierProfiles',
          )
          .doc(
            user.uid,
          )
          .set(
            {
              'profileImageUrl': imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
    }
  }

  Future<
    void
  >
  removeProfileImageUrl({
    required bool isApprovedSupplier,
  }) async {
    final user = currentUser;

    if (user ==
        null) {
      throw Exception(
        'Please log in first.',
      );
    }

    await FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          user.uid,
        )
        .set(
          {
            'profileImageUrl': FieldValue.delete(),
            'photoUrl': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

    await user.updatePhotoURL(
      null,
    );

    if (isApprovedSupplier) {
      await FirebaseFirestore.instance
          .collection(
            'supplierProfiles',
          )
          .doc(
            user.uid,
          )
          .set(
            {
              'profileImageUrl': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
    }
  }

  Future<
    void
  >
  logout() async {
    await PushNotificationService.instance.signOut();
  }

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
}
