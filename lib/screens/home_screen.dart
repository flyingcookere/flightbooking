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
