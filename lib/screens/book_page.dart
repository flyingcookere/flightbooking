import 'package:flutter/material.dart';
import 'book_oneway_page.dart'; 
import 'book_roundtrip_page.dart';

class _BookPageState extends State<BookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 1. Removed 'Multi City'
  final List<String> tabTitles = const [
    'Round Trip', 
    'One Way',
  ];

  @override
  void initState() {
    super.initState();
    // Length is now 2
    // Start on 'One Way' (index 1)
    _tabController = TabController(length: tabTitles.length, vsync: this, initialIndex: 1); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCustomTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), 
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blue, 
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white, 
        unselectedLabelColor: Colors.blue, 
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: tabTitles.map((title) => Tab(text: title)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCustomTabToggle(),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            // 2. Removed the Multi City page entry, leaving only two children
            children: const [ 
              // 1. Round Trip
              BookRoundTripPage(), 
              
              // 2. One Way
              OneWayBookingPage(route: ''), 
            ],  
          ),
        ),
      ],
    );
  }
}

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}
