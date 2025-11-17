import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.currentUser?.email ?? "No User";

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Logged in as: $userEmail"),
            const SizedBox(height: 20),

            // 🔥 TEST Firestore Button
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('test')
                    .add({'timestamp': DateTime.now().toString()});
              },
              child: const Text("Add Firestore Test Data"),
            ),

            const SizedBox(height: 20),

            // LOGOUT BUTTON
            ElevatedButton(
              onPressed: () async {
                await _authService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
