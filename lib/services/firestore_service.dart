import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================================================
  // 1. USER & AUTHENTICATION (EXISTING - KEPT SAFE)
  // ==================================================
  
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

  // ==================================================
  // 2. BOOKING FUNCTIONS (UPDATED)
  // ==================================================

  /// Old method: keep for backward compatibility
  Future<void> bookFlightOld(Map<String, dynamic> data, {String? userId}) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      if (userId != null) data['userId'] = userId;
      await _db.collection('bookings').add(data);
      print('Booking saved successfully!');
    } catch (e) {
      print('Error saving booking: $e');
      throw e;
    }
  }

  /// Saves a flight booking (One Way or Round Trip)
  /// 🔥 UPDATED: Now supports 'status' (reserved/confirmed) and 'price'
  Future<void> bookFlight({
    required String bookingType,
    required String status, // 'reserved' or 'confirmed'
    String? fromCity,
    String? toCity,
    required DateTime departureDate,
    DateTime? returnDate,
    List<Map<String, dynamic>>? legs,
    required int passengers,
    required String flightClass,
    String? userId,
    Map<String, int>? detailedPassengers, 
    double? price, // Added price parameter
  }) async {
    try {
      Map<String, dynamic> data = {
        'type': bookingType,
        'status': status, // 👇 Saved here
        'totalPassengers': passengers,
        'passengerDetails': detailedPassengers ?? {},
        'class': flightClass,
        'departureDate': departureDate.toIso8601String(),
        'totalPrice': price ?? 0, // 👇 Saved here
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (returnDate != null) data['returnDate'] = returnDate.toIso8601String();
      if (fromCity != null) data['from'] = fromCity;
      if (toCity != null) data['to'] = toCity;
      if (legs != null) data['legs'] = legs
          .map((leg) => {
                'from': leg['from'],
                'to': leg['to'],
                'date': leg['date'].toIso8601String(),
              })
          .toList();
      if (userId != null) data['userId'] = userId;

      await _db.collection('bookings').add(data);
      print('Booking ($status) saved successfully!');
    } catch (e) {
      print('Error saving booking: $e');
      throw e;
    }
  }

  // Fetch bookings for a specific user (For 'My Trips' page)
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

  // ==================================================
  // 3. HELPER DATA (EXISTING - KEPT SAFE)
  // ==================================================

  Future<List<String>> getCities() async {
    // This returns dummy city codes/names for the UI selection
    return ['MNL', 'CEBU', 'Davao', 'Iloilo', 'Bacolod'];
  }
  
  Future<List<Map<String, dynamic>>> getAirports() async {
    try {
      QuerySnapshot snapshot = await _db.collection('airports').get();
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print("Error fetching airports: $e");
      throw e;
    }
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserBookings(String userId) {
  return _db
      .collection('bookings')
      .where('userId', isEqualTo: userId)
      .orderBy('departureDate')
      .snapshots();
}
  
  // NEW: real-time stream of bookings for a specific user
    Stream<QuerySnapshot<Map<String, dynamic>>> getAllBookings() {
    return _db.collection('bookings')
      .orderBy('timestamp', descending: false)
      .snapshots();
  }
}