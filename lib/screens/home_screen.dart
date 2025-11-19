import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'my_trips_page.dart';
import 'book_page.dart';
import 'profile_page.dart';

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
      
      // --- APP BAR: STYLED TO MATCH REFERENCE PHOTO ---
      appBar: AppBar(
        // Set background to dark blue
        backgroundColor: Colors.blue.shade800, 
        // Set foreground (icons, title) to white
        foregroundColor: Colors.white, 
        // Align title to the left
        centerTitle: false, 
        // Remove shadow
        elevation: 0, 
        title: Text(
          // Updated title logic to use "Book Flights" and a bolder style
          _currentIndex == 0
              ? "Discover"
              : _currentIndex == 1
                  ? "My Trips"
                  : _currentIndex == 2
                      ? "Book Flights" // Updated title for the booking page
                      : "Profile",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          // Add search icon, only visible on the 'Book Flights' tab (Index 2)
          if (_currentIndex == 2)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.search),
            ),
        ],
      ),
      
      body: _buildBody(userEmail),
      
      // --- BOTTOM NAVIGATION BAR: STYLED TO MATCH REFERENCE PHOTO ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blue,
        // Use a slightly darker grey to better match the visual style
        unselectedItemColor: Colors.grey.shade600, 
        type: BottomNavigationBarType.fixed,
        // Ensure labels are visible for all items
        showUnselectedLabels: true, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), // Use outlined icons for unselected state
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage_outlined), // More suitable icon for "My Trips"
            activeIcon: Icon(Icons.luggage),
            label: "My Trip", // Consistent label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff_outlined), // Airplane icon for booking
            activeIcon: Icon(Icons.flight_takeoff),
            label: "Book Flight", // Updated label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile", // Consistent label
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String userEmail) {
    switch (_currentIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const MyTripsPage();
      case 2:
        return const BookPage();
      case 3:
        return ProfilePage(email: userEmail, authService: _authService);
      default:
        return Container();
    }
  }
}