import 'package:flutter/material.dart';
import 'book_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        "name": "Boracay",
        "image":
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
        "route": BookPage(), // <- Boracay will open BookPage
      },
      {
        "name": "Cebu",
        "image":
            "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
      },
      {
        "name": "Palawan",
        "image":
            "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
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
        ...destinations.map((place) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () {
                if (place.containsKey("route")) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => place["route"] as Widget),
                  );
                }
              },
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
            ),
          );
        }).toList(),
      ],
    );
  }
}
