import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  final String email;
  final AuthService authService;

  const ProfilePage({
    super.key,
    required this.email,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Icon(Icons.person, size: 80, color: Colors.grey),
                const SizedBox(height: 10),
                Text(email, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ABOUT USER
          _buildBox(
            context,
            title: "About User",
            icon: Icons.person_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AboutUserPage(email: email),
                ),
              );
            },
          ),

          // FLIGHT HISTORY
          _buildBox(
            context,
            title: "Flight History",
            icon: Icons.flight_takeoff,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlightHistoryPage(),
                ),
              );
            },
          ),

          // CONTACT US
          _buildBox(
            context,
            title: "Contact Us",
            icon: Icons.support_agent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContactUsPage(),
                ),
              );
            },
          ),

          // TERMS
          _buildBox(
            context,
            title: "Terms & Conditions",
            icon: Icons.description_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TermsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // LOGOUT
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await authService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Logout"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blue.shade700),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// ABOUT USER PAGE
// ===============================
class AboutUserPage extends StatelessWidget {
  final String email;

  const AboutUserPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About User")),
      body: Center(
        child: Text(
          "Email: $email\n\nMore user info coming soon…",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// ===============================
// FLIGHT HISTORY PAGE
// ===============================
class FlightHistoryPage extends StatelessWidget {
  const FlightHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flight History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No bookings yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsPage(
                        bookingData: data,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flight, size: 30, color: Colors.blue),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "${data['origin']} → ${data['destination']}\n${data['flightType']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ===============================
// BOOKING DETAILS PAGE (WITH ICONS + STYLING)
// ===============================
class BookingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailsPage({super.key, required this.bookingData});

  Widget _detail(String title, dynamic value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "$title: $value",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var p = bookingData['passengerDetails'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _detail("Origin", bookingData['origin'], Icons.flight_takeoff),
          _detail("Destination", bookingData['destination'], Icons.flight_land),
          _detail("Flight Type", bookingData['flightType'], Icons.airplane_ticket),
          _detail("Class", bookingData['class'], Icons.event_seat),
          _detail("Total Price", bookingData['totalPrice'], Icons.payments),
          _detail("Status", bookingData['status'], Icons.info),

          const SizedBox(height: 20),
          const Text("Passenger Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _detail("Adult", p['adult'], Icons.person),
          _detail("Child", p['child'], Icons.child_care),
          _detail("Infant", p['infant'], Icons.baby_changing_station),
          _detail("Senior", p['senior'], Icons.elderly),
          _detail("PWD", p['disability'], Icons.accessible),
        ],
      ),
    );
  }
}

// ===============================
// CONTACT US PAGE
// ===============================
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Us")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("FlyBook Support", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Text("📞 Phone: +63 900 123 4567"),
            SizedBox(height: 10),
            Text("📧 Email: support@flybook.com"),
            SizedBox(height: 10),
            Text("🌐 Website: www.flybook.com"),
            SizedBox(height: 10),
            Text("📍 Address: Pasay City, NAIA Terminal 3, Philippines"),
          ],
        ),
      ),
    );
  }
}

// ===============================
// TERMS PAGE
// ===============================
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms & Conditions")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            Text(
              "Flight Booking Terms & Conditions\n",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "1. All bookings are non-transferable.\n"
              "2. Tickets may be refundable or non-refundable depending on airline rules.\n"
              "3. Changes to flight schedules may incur additional fees.\n"
              "4. Passengers must present valid ID upon check-in.\n"
              "5. Infants must be accompanied by an adult.\n"
              "6. FlyBook is not responsible for delays caused by airlines.\n"
              "7. Prices are subject to change without prior notice.\n"
              "8. Passengers are responsible for ensuring correct information is entered during booking.\n"
              "9. Violation of airline policies may result in denied boarding.\n",
              style: TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
