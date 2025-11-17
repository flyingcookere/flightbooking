import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUserProfile(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'createdAt': DateTime.now(),
    });
  }
}
