import 'package:flutter/material.dart';

class MyTripsPage extends StatelessWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Your booked flights will appear here.",
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
