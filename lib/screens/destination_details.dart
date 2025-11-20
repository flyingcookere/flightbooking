import 'package:flutter/material.dart';
import 'book_page.dart';

class DestinationDetails extends StatelessWidget {
  final String code;
  final String city;
  final String name;
  final String image;

  const DestinationDetails({
    super.key,
    required this.code,
    required this.city,
    required this.name,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final descriptions = {
      "Manila":
          "A vibrant mix of history, nightlife, shopping, and iconic Filipino culture. Explore Intramuros, dine at world-class restaurants, and experience the city’s electric energy.",
      "Cebu":
          "Beaches, lechon, festivals, and world-famous diving spots. Cebu is the perfect blend of city life and tropical paradise.",
      "Davao":
          "Home of Mt. Apo, durian, clean streets, and peaceful urban living. A gateway to eco adventures and stunning natural landscapes.",
      "Puerto Princesa":
          "The majestic Underground River, limestone cliffs, and teal waters—this place feels unreal. Escape into nature and crystal-clear beaches.",
      "Boracay":
          "Powder-soft sand, aqua-blue waters, nightlife, and luxury resorts. One of the world’s best islands—no explanation needed.",
    };

    final salesPitch = {
      "Manila":
          "Fly to Manila now! It's the heart of the Philippines—modern, exciting, and endlessly alive. Your adventure starts the moment you land.",
      "Cebu":
          "Cebu is calling! Tropical escapes, rich culture, and adventure-packed itineraries. Book now and experience the Queen City of the South!",
      "Davao":
          "Want peace + adventure? Davao is your best bet. Nature, wildlife, and clean urban living. Book your escape today!",
      "Puerto Princesa":
          "Puerto Princesa is the paradise your soul craves. Nature at its finest. Book now for a stress-free getaway!",
      "Boracay":
          "The world-famous Boracay is waiting. White Beach, sunset sails, island luxury. Treat yourself—book the trip now!",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(city),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // HEADER IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Image.network(
              image,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  "$city ($code)",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),

                // WHY VISIT?
                const Text(
                  "Why visit?",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  descriptions[city]!,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),

                const SizedBox(height: 25),

                // SALES TALK
                const Text(
                  "Don't miss out!",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  salesPitch[city]!,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "BOOK NOW",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                )

              ],
            ),
          )
        ],
      ),
    );
  }
}
