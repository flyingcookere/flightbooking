import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  _MyTripsPageState createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  int selectedTab = 0; // 0 = Upcoming, 1 = Past, 2 = Reserved, 3 = Cancelled

  @override
  void initState() {
    super.initState();
    // Explicitly set the default tab index when the widget is first created
    selectedTab = 0; // Ensures it starts on "Upcoming Trips"
  }
  
  // --- FUNCTION: Updates the booking status to "cancelled" ---
  Future<void> _cancelTrip(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'status': 'cancelled'});
      
      // The StreamBuilder will automatically refresh the list, moving the trip to the "Cancelled" tab!
      print("Trip $docId status updated to 'cancelled'");
    } catch (e) {
      print("Error cancelling trip: $e");
    }
  }

  // --- HELPER FUNCTION: Fetches the real flight date and doc ID ---
  Future<List<Map<String, dynamic>>> _getEnrichedTrips(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> bookingDocs) async {
    
    List<Map<String, dynamic>> results = [];

    for (var doc in bookingDocs) {
      var data = doc.data();
      
      // Store the document ID in the map
      data['docId'] = doc.id; 
      
      DocumentReference? flightRef = data['flightRef'];
      DateTime realDepartureDate = DateTime.now(); 

      if (flightRef != null) {
        try {
          DocumentSnapshot flightSnap = await flightRef.get();
          
          if (flightSnap.exists) {
            Map<String, dynamic> flightData = flightSnap.data() as Map<String, dynamic>;
            
            // ⚠️ IMPORTANT: Check the field name in your Firestore Schedule collection
            var dateField = flightData['departureDate']; 

            if (dateField is Timestamp) {
              realDepartureDate = dateField.toDate();
            } else if (dateField is String) {
              realDepartureDate = DateTime.tryParse(dateField) ?? DateTime.now();
            }
          }
        } catch (e) {
          print("Error fetching flight details: $e");
        }
      }
      data['realDepartureDate'] = realDepartureDate;
      results.add(data);
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "My Trips",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            // Tab buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton("Upcoming Trips", 0),
                  _buildTabButton("Past Trips", 1),
                  _buildTabButton("Reserved", 2),
                  _buildTabButton("Cancelled", 3),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Trips list with Two-Step Loading
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // 1. Listen to Bookings
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .orderBy('timestamp', descending: true) 
                    .snapshots(),
                builder: (context, snapshot) {
                  // Loading Bookings...
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Bookings Found",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  // 2. Fetch Real Flight Dates (Async)
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getEnrichedTrips(snapshot.data!.docs),
                    builder: (context, enrichedSnapshot) {
                      
                      // Loading Real Dates...
                      if (enrichedSnapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: CircularProgressIndicator());
                      }

                      final allTrips = enrichedSnapshot.data ?? [];
                      final filteredTrips = <Map<String, dynamic>>[];
                      final now = DateTime.now();

                      // 3. Filter Logic (Corrected)
                      for (var trip in allTrips) {
                        final status = (trip["status"] ?? "").toString().toLowerCase();
                        final DateTime dep = trip['realDepartureDate']; // The REAL flight date

                        switch (selectedTab) {
                          case 0: // Upcoming
                            // Must be confirmed AND date must be in the future
                            if (status == "confirmed" && dep.isBefore(now)) {
                              filteredTrips.add(trip);
                            }
                            break;
                          case 1: // Past
                            // Must be confirmed AND date must be in the past
                            if (status == "confirmed" && dep.isAfter(now)) {
                              filteredTrips.add(trip);
                            }
                            break;
                          case 2: // Reserved
                            if (status == "reserved") filteredTrips.add(trip);
                            break;
                          case 3: // Cancelled
                            if (status == "cancelled") filteredTrips.add(trip);
                            break;
                        }
                      }

                      // Optional: Sort the filtered list by date
                      filteredTrips.sort((a, b) {
                        DateTime dateA = a['realDepartureDate'];
                        DateTime dateB = b['realDepartureDate'];
                        if (selectedTab == 1) return dateB.compareTo(dateA);
                        return dateA.compareTo(dateB);
                      });

                      if (filteredTrips.isEmpty) {
                        String message;
                        switch (selectedTab) {
                          case 0: message = "No Upcoming Trips"; break;
                          case 1: message = "No Past Trips"; break;
                          case 2: message = "No Reserved Trips"; break;
                          case 3: message = "No Cancelled Trips"; break;
                          default: message = "No Trips";
                        }
                        return Center(
                          child: Text(
                            message,
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      // 4. Display List
                      return ListView.builder(
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) {
                          final trip = filteredTrips[index];
                          final DateTime dep = trip['realDepartureDate'];
                          final String docId = trip['docId']; 
                          
                          // Logic to show/hide the Cancel button
                          final bool showCancelButton = selectedTab == 0 || selectedTab == 2;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  // TOP LEFT: Route
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "${trip['origin'] ?? 'N/A'} → ${trip['destination'] ?? 'N/A'}",
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                  // BOTTOM LEFT: Date, Flight Type, & Class
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_month, size: 18, color: Colors.grey[800]),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${dep.year}-${dep.month}-${dep.day} • ${trip['flightType'] ?? 'Flight'} • ${trip['class'] ?? 'Class'}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // BOTTOM RIGHT: CANCEL BUTTON (Conditional)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: showCancelButton
                                        ? TextButton(
                                            onPressed: () => _cancelTrip(docId),
                                            child: const Text(
                                              "CANCEL",
                                              style: TextStyle(
                                                color: Color.fromARGB(255, 57, 57, 57), 
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          )
                                        // If the trip is Past or Cancelled, show nothing here.
                                        : const SizedBox.shrink(), 
                                  ),

                                  // TOP RIGHT: Status Tag
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: trip['status'] == 'confirmed' 
                                            ? Colors.green[100] 
                                            : (trip['status'] == 'cancelled' ? Colors.red[100] : Colors.orange[100]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (trip['status'] ?? '').toString().toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: trip['status'] == 'confirmed' 
                                              ? Colors.green[800] 
                                              : (trip['status'] == 'cancelled' ? Colors.red[800] : Colors.orange[800]),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final selected = selectedTab == tabIndex;

    return Container(
      width: 160,
      height: 50,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF6C63FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: selected ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))] : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            selectedTab = tabIndex;
          });
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}