import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  logout() async {
    await FirebaseAuth.instance.signOut();
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
