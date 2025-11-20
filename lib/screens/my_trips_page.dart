import 'package:flutter/material.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  _MyTripsPageState createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  // 0 = upcoming, 1 = past, 2 = reserved, 3 = cancelled
  int selectedTab = 0;

  // Sample data
  List<String> upcomingTrips = [];
  List<Map<String, String>> pastTrips = [
    {
      'route': 'Manila → Cebu',
      'datetime': 'Nov 15, 2025 - 10:00 AM',
    },
    {
      'route': 'Cebu → Davao',
      'datetime': 'Oct 22, 2025 - 2:30 PM',
    },
  ];
  List<String> reservedTrips = [];
  List<String> cancelledTrips = [];

  @override
  Widget build(BuildContext context) {
    List<Widget> tripWidgets = [];

    // ---------------- UPCOMING ----------------
    if (selectedTab == 0) {
      if (upcomingTrips.isEmpty) {
        tripWidgets.add(const Center(
          child: Text("No Trips Available",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ));
      }
    }

    // ---------------- PAST ----------------
    if (selectedTab == 1) {
      if (pastTrips.isEmpty) {
        tripWidgets.add(const Center(
          child: Text("No Trips Available",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ));
      } else {
        tripWidgets = pastTrips
            .map(
              (trip) => Padding(
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
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          trip['route']!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Verdana',
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          trip['datetime']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Verdana',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList();
      }
    }

    // ---------------- RESERVED ----------------
    if (selectedTab == 2) {
      if (reservedTrips.isEmpty) {
        tripWidgets.add(const Center(
          child: Text("No Reserved Trips",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ));
      }
    }

    // ---------------- CANCELLED ----------------
    if (selectedTab == 3) {
      if (cancelledTrips.isEmpty) {
        tripWidgets.add(const Center(
          child: Text("No Cancelled Trips",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "My Trips",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            // 🔥 SCROLLABLE BUTTON ROW
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton("Upcoming", 0),
                  _buildTabButton("Past", 1),
                  _buildTabButton("Reserved", 2),
                  _buildTabButton("Cancelled", 3),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: tripWidgets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 REUSABLE TAB BUTTON
  Widget _buildTabButton(String label, int tabIndex) {
    bool selected = selectedTab == tabIndex;
    return Container(
      width: 160,
      height: 70,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: selected
            ? const Color.fromARGB(255, 108, 99, 255)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
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
                fontSize: 16,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
