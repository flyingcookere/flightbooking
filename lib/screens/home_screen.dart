import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.currentUser?.email ?? "No User";

    return Scaffold(
      backgroundColor: Colors.white,

      // TOP TITLE (changes depending on tab)
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _currentIndex == 0
              ? "Discover"
              : _currentIndex == 1
                  ? "My Trips"
                  : _currentIndex == 2
                      ? "Book Now"
                      : "Profile",
        ),
      ),

      body: _buildBody(userEmail),

      // BOTTOM NAVIGATION (4 ITEMS)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel),
            label: "My Trips",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff),
            label: "Book",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "User",
          ),
        ],
      ),
    );
  }

  // BODY CHANGER
  Widget _buildBody(String userEmail) {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildMyTrips();
      case 2:
        return _buildBook();
      case 3:
        return _buildProfile(userEmail);
      default:
        return Container();
    }
  }

  // 🟦 HOME SCREEN (PAL-style big image cards)
  Widget _buildHome() {
    final destinations = [
      {
        "name": "Boracay",
        "image":
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e"
      },
      {
        "name": "Cebu",
        "image":
            "https://images.unsplash.com/photo-1506744038136-46273834b3fb"
      },
      {
        "name": "Palawan",
        "image":
            "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee"
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Popular Destinations",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // BIG IMAGE CARDS
        ...destinations.map((place) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.network(
                    place["image"]!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Text(
                      place["name"]!,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // 🟧 MY TRIPS PAGE
  Widget _buildMyTrips() {
    return const Center(
      child: Text("Your booked flights will appear here.",
          style: TextStyle(fontSize: 18)),
    );
  }

  // 🟥 BOOK PAGE
  Widget _buildBook() {
    return const Center(
      child: Text("Start booking your next flight.",
          style: TextStyle(fontSize: 18)),
    );
  }

  // 🟩 PROFILE PAGE WITH LOGOUT
  Widget _buildProfile(String email) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          Text(email, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
