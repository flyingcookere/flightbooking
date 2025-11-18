import 'package:flutter/material.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Start booking your next flight.",
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
