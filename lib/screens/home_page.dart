import 'package:flutter/material.dart';
import 'destination_details.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        'code': 'MNL',
        'city': 'Manila',
        'name': 'Ninoy Aquino Intl',
        'image': 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e'
      },
      {
        'code': 'CEBU',
        'city': 'Cebu',
        'name': 'Mactan-Cebu Intl',
        'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb'
      },
      {
        'code': 'DVO',
        'city': 'Davao',
        'name': 'Francisco Bangoy Intl',
        'image': 'https://images.unsplash.com/photo-1502082553048-f009c37129b9'
      },
      {
        'code': 'PPS',
        'city': 'Puerto Princesa',
        'name': 'Puerto Princesa Intl',
        'image': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee'
      },
      {
        'code': 'MPH',
        'city': 'Boracay',
        'name': 'Caticlan',
        'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      backgroundColor: const Color(0xFFF5F7FF),
      body: ListView(
        children: [
          // --------------------- HEADER ---------------------
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade500,
                  Colors.blue.shade300,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, Traveler",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Where do you want to fly?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --------------------- TITLE ---------------------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Popular Destinations",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --------------------- HORIZONTAL CARD LIST ---------------------
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              itemCount: destinations.length,
              itemBuilder: (context, i) {
                final place = destinations[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DestinationDetails(
                          code: place['code']!,
                          city: place['city']!,
                          name: place['name']!,
                          image: place['image']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.08),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Image.network(
                            place["image"]!,
                            height: 130,
                            width: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place["city"]!,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                place["name"]!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
