import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

const String bgImage =
    "https://50skyshades.com/images/o/4743-nLUoxf0MGVFEYlQ7Hlj9r0tuB.jpg";

class ProfilePage extends StatelessWidget {
  final String email;
  final AuthService authService;

  const ProfilePage({
    super.key,
    required this.email,
    required this.authService,
  });

  Future<String> _getFirstName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authService.currentUser!.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['firstName'] ?? 'User';
      } else {
        return 'User';
      }
    } catch (e) {
      print("Error fetching first name: $e");
      return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(bgImage, fit: BoxFit.cover),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 40),
              FutureBuilder<String>(
                future: _getFirstName(),
                builder: (context, snapshot) {
                  String firstName = 'Loading...';
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    firstName = snapshot.data!;
                  }

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 53, 7, 138),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              _buildBox(
                context,
                title: "About User",
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AboutUserPage(uid: authService.currentUser!.uid),
                    ),
                  );
                },
              ),

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

              _buildBox(
                context,
                title: "Logout",
                icon: Icons.logout,
                color: const Color.fromARGB(255, 218, 93, 85),
                onTap: () async {
                  await authService.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBox(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: const Color.fromARGB(255, 45, 3, 80)),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 45, 3, 80)),
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
  final String uid;

  const AboutUserPage({super.key, required this.uid});

  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        return {};
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(bgImage, fit: BoxFit.cover),
          ),
          SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var user = snapshot.data ?? {};
                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "About User",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: 450, // fixed width
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.15),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 18, color: Colors.black),
                                children: [
                                  const TextSpan(
                                      text: "First Name: ",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: user['firstName'] ?? ''),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 18, color: Colors.black),
                                children: [
                                  const TextSpan(
                                      text: "Middle Name: ",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: user['middleName'] ?? ''),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 18, color: Colors.black),
                                children: [
                                  const TextSpan(
                                      text: "Last Name: ",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: user['lastName'] ?? ''),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 18, color: Colors.black),
                                children: [
                                  const TextSpan(
                                      text: "Email: ",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: user['email'] ?? ''),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 18, color: Colors.black),
                                children: [
                                  const TextSpan(
                                      text: "Age: ",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: "${user['age'] ?? ''}"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 18, color: Colors.black),
                                children: [
                                  const TextSpan(
                                      text: "Contact Number: ",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: user['contactNumber'] ?? ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )

                  ],
                );
              },
            ),
          ),
        ],
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(bgImage, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text("Flight History",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(
                            child: Text("No bookings yet.",
                                style: TextStyle(color: Colors.white)));
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
                                  const Icon(Icons.flight,
                                      size: 30, color: Color.fromARGB(255, 42, 0, 110)),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// BOOKING DETAILS PAGE
// ===============================
class BookingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailsPage({super.key, required this.bookingData});

  Widget _detail(String title, dynamic value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 3),
          ),
        ],
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(bgImage, fit: BoxFit.cover),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text("Booking Details",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                _detail("Origin", bookingData['origin'], Icons.flight_takeoff),
                _detail("Destination", bookingData['destination'],
                    Icons.flight_land),
                _detail("Flight Type", bookingData['flightType'],
                    Icons.airplane_ticket),
                _detail("Class", bookingData['class'], Icons.event_seat),
                _detail("Total Price", bookingData['totalPrice'], Icons.payments),
                _detail("Status", bookingData['status'], Icons.info),
                const SizedBox(height: 20),
                const Text("Passenger Details",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _detail("Adult", p['adult'], Icons.person),
                _detail("Child", p['child'], Icons.child_care),
                _detail("Infant", p['infant'], Icons.baby_changing_station),
                _detail("Senior", p['senior'], Icons.elderly),
                _detail("PWD", p['disability'], Icons.accessible),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.network(bgImage, fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Contact Us",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "FlyBook Support",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            Text("📞 Phone: +63 900 123 4567",
                                textAlign: TextAlign.center),
                            SizedBox(height: 10),
                            Text("📧 Email: support@flybook.com",
                                textAlign: TextAlign.center),
                            SizedBox(height: 10),
                            Text("🌐 Website: www.flybook.com",
                                textAlign: TextAlign.center),
                            SizedBox(height: 10),
                            Text(
                              "📍 Address: Pasay City, NAIA Terminal 3, Philippines",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              bgImage,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Terms & Conditions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: ListView(
                            children: const [
                              Text(
                                "Flight Booking Terms & Conditions\n",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
