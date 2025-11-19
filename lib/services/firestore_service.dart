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

  /// New method: named parameters for easy integration with BookPage
  Future<void> bookFlight({
    required String bookingType,
    String? fromCity,
    String? toCity,
    required DateTime departureDate,
    DateTime? returnDate,
    List<Map<String, dynamic>>? legs,
    required int passengers,
    required String flightClass,
    String? userId,
    // 👇 ADDED PARAMETER: Detailed breakdown map
    Map<String, int>? detailedPassengers, 
  }) async {
    try {
      Map<String, dynamic> data = {
        'type': bookingType,
        'totalPassengers': passengers, // Use totalPassengers for clarity
        'class': flightClass,
        'departureDate': departureDate.toIso8601String(),
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
      
      // 👇 ADDED LOGIC: Save the detailed breakdown if provided
      if (detailedPassengers != null) {
        data['passengerDetails'] = detailedPassengers;
      }

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
  
  // ------------------- AIRPORTS/CITIES -------------------

  // 👇 FIX for the 'getCities' error in book_multicity_page.dart
  Future<List<String>> getCities() async {
    // This returns dummy city codes/names for the UI selection
    // You can replace this with a real Firestore query later.
    return ['MNL', 'CEBU', 'Davao', 'Iloilo', 'Bacolod'];
  }
  
  // Existing getAirports moved inside the class for clarity
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
} // End of FirestoreService class