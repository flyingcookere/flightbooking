import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DatabaseSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Seed Airports
  Future<void> seedAirports() async {
    print("🚀 Starting Airport Seed...");
    final airports = [
      {'code': 'MNL', 'city': 'Manila', 'name': 'Ninoy Aquino Intl'},
      {'code': 'CEBU', 'city': 'Cebu', 'name': 'Mactan-Cebu Intl'},
      {'code': 'DVO', 'city': 'Davao', 'name': 'Francisco Bangoy Intl'},
      {'code': 'PPS', 'city': 'Puerto Princesa', 'name': 'Puerto Princesa Intl'},
      {'code': 'MPH', 'city': 'Boracay', 'name': 'Godofredo P. Ramos'},
      {'code': 'BKO', 'city': 'Bicol', 'name': 'Bicol Intl'},
      {'code': 'ZAM', 'city': 'Zamboanga', 'name': 'Zamboanga Intl'},
      {'code': 'ILO', 'city': 'Iloilo', 'name': 'Iloilo Intl'},
    ];

    try {
      for (var airport in airports) {
        await _db.collection('airports').doc(airport['code']).set({
          'code': airport['code'],
          'city': airport['city'],
          'displayName': '${airport['city']} (${airport['code']})',
        });
      }
      print("✅ Airports seeded successfully!");
    } catch (e) {
      print("❌ Error seeding airports: $e");
    }
  }

  // 2. Seed Flights (30-DAY LONG RANGE VERSION)
  Future<void> seedFlights() async {
    print("🚀 Starting 30-DAY Flight Seed... (Please wait, this is a lot of data)");
    
    final airportCodes = ['MNL', 'CEBU', 'DVO', 'PPS', 'MPH', 'BKO', 'ZAM', 'ILO'];
    
    // Varied times
    final times = [
      '05:30 AM', '08:00 AM', '10:15 AM', 
      '01:45 PM', '04:20 PM', '07:30 PM', '09:45 PM'
    ];

    // Cabin Classes
    final flightClasses = ['Economy', 'Premium Economy', 'Business', 'First Class'];

    final random = Random();
    int totalCount = 0;

    try {
      // LOOP: 30 Days (Solves the "No Return Flight" issue)
      for (int i = 0; i < 30; i++) {
        DateTime flightDate = DateTime.now().add(Duration(days: i));
        
        for (String origin in airportCodes) {
          for (String dest in airportCodes) {
            if (origin == dest) continue; 

            String collectionPath = '$origin-to-$dest'; 

            // 2 flights per route per day (Keeps the total manageable but available)
            for (int j = 0; j < 2; j++) {
              int price = 2500 + random.nextInt(4000); 
              String time = times[random.nextInt(times.length)];
              String randomClass = flightClasses[random.nextInt(flightClasses.length)];

              // Adjust price for class
              if (randomClass == 'Business') price += 4000;
              if (randomClass == 'First Class') price += 8000;

              // 1. One-Way
              await _db.collection('flightbooking')
                  .doc('all-one-way-schedules')
                  .collection(collectionPath) 
                  .add({
                'origin': origin,
                'destination': dest,
                'date': flightDate,
                'time': time,
                'price': price,
                'seatAvailable': 5 + random.nextInt(60), 
                'seatTotal': 100,
                'class': randomClass,
              });

              // 2. Round-Trip
              await _db.collection('flightbooking')
                  .doc('all-round-trip-schedules')
                  .collection(collectionPath) 
                  .add({
                'origin': origin,
                'destination': dest,
                'date': flightDate,
                'time': time,
                'price': price,
                'seatAvailable': 5 + random.nextInt(60), 
                'seatTotal': 100,
                'class': randomClass,
              });
              
              totalCount++;
            }
          }
        }
        // Print progress every day so you know it's alive
        print("📅 Day ${i+1} of 30 completed...");
      }
      print("✅ SUCCESS! Database is STOCKED with $totalCount flights spanning 30 days.");
    } catch (e) {
      print("❌ ERROR seeding flights: $e");
    }
  }
}