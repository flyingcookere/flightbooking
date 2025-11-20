import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'my_trips_page.dart';
import 'book_page.dart';
import 'profile_page.dart';
import 'db_seeder.dart';


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
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800, 
        foregroundColor: Colors.white, 
        centerTitle: false, 
        elevation: 0, 
        title: Text(
          _currentIndex == 0
              ? "Discover"
              : _currentIndex == 1
                  ? "My Trips"
                  : _currentIndex == 2
                      ? "Book Flights"
                      : "Profile",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          if (_currentIndex == 2)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.search),
            ),
        ],
      ),
      
      body: _buildBody(userEmail),
      
      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade600, 
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage_outlined),
            activeIcon: Icon(Icons.luggage),
            label: "My Trip",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff_outlined),
            activeIcon: Icon(Icons.flight_takeoff),
            label: "Book Flight",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),

      // 🔥 HERE IS THE RED BUTTON (Added after BottomNavigationBar) 🔥
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red, 
        child: const Icon(Icons.cloud_upload),
        onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seeding Database...")));
            
            // This calls the "Robot" script to fill your database
            DatabaseSeeder seeder = DatabaseSeeder();
            await seeder.seedAirports(); 
            await seeder.seedFlights();  
            
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Database Done! Now delete this button.")));
        },
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