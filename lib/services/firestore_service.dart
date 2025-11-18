import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------- USERS -------------------
  Future<void> addUserProfile(String uid, String email) async {
    try {
      await _db.collection('users').doc(uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User profile added successfully!');
    } catch (e) {
      print('Error adding user profile: $e');
      throw e;
    }
  }

  // ------------------- BOOKINGS -------------------
  /// Add a flight booking
  /// [data] = map containing booking details
  /// [userId] = optional, to link booking to a user
  Future<void> bookFlight(Map<String, dynamic> data, {String? userId}) async {
    try {
      // Add metadata
      data['createdAt'] = FieldValue.serverTimestamp();
      if (userId != null) data['userId'] = userId;

      await _db.collection('bookings').add(data);
      print('Booking saved successfully!');
    } catch (e) {
      print('Error saving booking: $e');
      throw e;
    }
  }

  // Optional: Fetch all bookings (for admin or user view)
  Future<List<Map<String, dynamic>>> getBookings({String? userId}) async {
    try {
      Query query = _db.collection('bookings').orderBy('createdAt', descending: true);
      if (userId != null) query = query.where('userId', isEqualTo: userId);

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      throw e;
    }
  }
}
