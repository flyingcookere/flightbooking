import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DatabaseSeeder {
 final FirebaseFirestore _db = FirebaseFirestore.instance;

 // 1. Seed Airports (For the dropdowns)
 Future<void> seedAirports() async {
 final airports = [
 {'code': 'MNL', 'city': 'Manila', 'name': 'Ninoy Aquino Intl'},
 {'code': 'CEBU', 'city': 'Cebu', 'name': 'Mactan-Cebu Intl'},
 {'code': 'DVO', 'city': 'Davao', 'name': 'Francisco Bangoy Intl'},
 {'code': 'PPS', 'city': 'Puerto Princesa', 'name': 'Puerto Princesa Intl'},
 {'code': 'MPH', 'city': 'Boracay', 'name': 'Caticlan'},
 ];

 for (var airport in airports) {
 await _db.collection('airports').doc(airport['code']).set({
 'code': airport['code'],
 'city': airport['city'],
 'displayName': '${airport['city']} (${airport['code']})',
 });
 }
 print("✅ Airports added!");
 }

 // 2. Seed Flights (For the booking list)
 Future<void> seedFlights() async {
 final routes = [
 ['MNL', 'CEBU'], ['CEBU', 'MNL'],
 ['MNL', 'DVO'], ['DVO', 'MNL'],
 ['MNL', 'PPS'], ['PPS', 'MNL'],
 ];

 final times = ['08:00 AM', '10:30 AM', '02:00 PM', '06:45 PM'];
 final random = Random();

 // Generate flights for the next 7 days
 for (int i = 0; i < 7; i++) {
 DateTime flightDate = DateTime.now().add(Duration(days: i));
 
 for (var route in routes) {
 String origin = route[0];
 String dest = route[1];
 String collectionPath = '$origin-to-$dest'; 

 // Create 2 flights per day per route
 for (int j = 0; j < 2; j++) {
 int price = 2500 + random.nextInt(4000); 
 String time = times[random.nextInt(times.length)];

 // 1. Seed One-Way flights (FIXED PATH)
 await _db
 .collection('flightbooking')
 .doc('all-one-way-schedules') // Correct Document ID
 .collection(collectionPath) 
 .add({
 'origin': origin,
 'destination': dest,
 'date': flightDate,
 'time': time,
 'price': price,
 'seatAvailable': 20 + random.nextInt(50), 
 'seatTotal': 100,
 'class': 'Economy',
 });
 
 // 2. Seed Round-Trip flights (FIXED PATH)
await _db
 .collection('flightbooking')
 .doc('all-round-trip-schedules') // Correct Document ID
 .collection(collectionPath) 
 .add({
 'origin': origin,
 'destination': dest,
 'date': flightDate,
 'time': time,
 'price': price,
 'seatAvailable': 20 + random.nextInt(50), 
 'seatTotal': 100,
 'class': 'Economy',
 });
 }
 }
 }
 print("✅ Flights for next 7 days added!");
 }
}