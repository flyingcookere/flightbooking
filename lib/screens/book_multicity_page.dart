import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookMultiCityPage extends StatefulWidget {
  const BookMultiCityPage({super.key});

  @override
  State<BookMultiCityPage> createState() => _BookMultiCityPageState();
}

class _BookMultiCityPageState extends State<BookMultiCityPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- STATE: FLIGHT LEGS ---
  // 🔥 FIXED: 'date' is now null by default so it shows "Select Date"
  List<Map<String, dynamic>> flightLegs = [
    {'from': null, 'to': null, 'date': null},
    {'from': null, 'to': null, 'date': null},
  ];

  // --- STATE: GLOBAL SELECTIONS ---
  int adultCount = 1;
  int childCount = 0;
  int infantCount = 0;
  int personWithDisabilityCount = 0;
  int ofwCount = 0;
  int seniorCitizenCount = 0;
  
  String flightClass = 'Economy';
  bool _isLoadingFlights = false;
  bool _showResults = false; 

  // Calculated total
  int get totalPassengers => adultCount + childCount + infantCount + personWithDisabilityCount + ofwCount + seniorCitizenCount;

  // --- MODAL: CITY PICKER ---
  Future<void> _showCityPicker(int index, bool isOrigin) async {
    final cities = ['MNL', 'CEBU', 'DVO', 'MPH', 'PPS']; 
    
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        child: ListView(
          children: cities.map((c) => ListTile(title: Text(c), onTap: () => Navigator.pop(ctx, c))).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        if (isOrigin) {
          flightLegs[index]['from'] = selected;
        } else {
          flightLegs[index]['to'] = selected;
        }
        _showResults = false; 
      });
    }
  }

  // --- MODAL: DATE PICKER ---
  Future<void> _pickDate(int index) async {
    DateTime now = DateTime.now();
    // Use current date as fallback if null
    DateTime initial = flightLegs[index]['date'] ?? now;
    if (initial.isBefore(now)) initial = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        flightLegs[index]['date'] = picked;
        _showResults = false;
      });
    }
  }

  // --- MODAL: PASSENGERS ---
  Future<void> _showPassengerPicker() async {
    int tempAdult = adultCount; int tempChild = childCount; int tempInfant = infantCount;
    int tempPWD = personWithDisabilityCount; int tempOFW = ofwCount; int tempSenior = seniorCitizenCount;
    int maxTotal = 9; 

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) {
        Widget buildRow(String label, String sub, int count, Function(int) onChange) {
          int currentTotal = tempAdult + tempChild + tempInfant + tempPWD + tempOFW + tempSenior;
          bool isIncDisabled = (currentTotal >= maxTotal);
          return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), if(sub.isNotEmpty) Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
              IconButton(onPressed: count <= 0 ? null : () => setModal(() => onChange(count - 1)), icon: Icon(Icons.remove_circle_outline, color: count <= 0 ? Colors.grey : Colors.blue)),
              SizedBox(width: 20, child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              IconButton(onPressed: isIncDisabled ? null : () => setModal(() => onChange(count + 1)), icon: Icon(Icons.add_circle_outline, color: isIncDisabled ? Colors.grey : Colors.blue)),
          ]));
        }
        return Container(
          padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.75,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Select Passengers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]),
            const Divider(),
            Expanded(child: SingleChildScrollView(child: Column(children: [
               buildRow('Adult', '12 y +', tempAdult, (v) => tempAdult = v),
               buildRow('Child', '2 y - 11 y', tempChild, (v) => tempChild = v),
               buildRow('Person with Disability', '', tempPWD, (v) => tempPWD = v),
               buildRow('Infant', '16 d - 23 m', tempInfant, (v) => tempInfant = v),
               buildRow('Overseas Filipino Worker', '', tempOFW, (v) => tempOFW = v),
               buildRow('Senior Citizen', '60 y +', tempSenior, (v) => tempSenior = v),
            ]))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, {'adult': tempAdult, 'child': tempChild, 'pwd': tempPWD, 'infant': tempInfant, 'ofw': tempOFW, 'senior': tempSenior}), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Continue', style: TextStyle(color: Colors.white)))
          ]),
        );
      }),
    );

    if (result != null) {
      setState(() {
        adultCount = result['adult']!; childCount = result['child']!; personWithDisabilityCount = result['pwd']!;
        infantCount = result['infant']!; ofwCount = result['ofw']!; seniorCitizenCount = result['senior']!;
      });
    }
  }

  // --- MODAL: CLASS ---
  Future<void> _showClassPicker() async {
    String tempClass = flightClass;
    final classes = ['All Cabin', 'Economy', 'Comfort', 'Premium Economy', 'Business'];
    final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => Container(
        padding: const EdgeInsets.all(20), height: 350,
        child: Column(children: [
          const Text('Select Cabin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          Expanded(child: ListView(children: classes.map((c) => ListTile(title: Text(c), onTap: () => Navigator.pop(ctx, c), leading: Radio(value: c, groupValue: tempClass, onChanged: null, activeColor: Colors.blue))).toList())),
    ])));
    if (selected != null) setState(() => flightClass = selected);
  }

  // --- LOGIC: ADD/REMOVE FLIGHTS ---
  void _addFlightLeg() {
    setState(() {
      String? prevDest = flightLegs.last['to'];
      // Add new leg with NULL date
      flightLegs.add({'from': prevDest, 'to': null, 'date': null});
      _showResults = false;
    });
  }

  void _removeFlightLeg(int index) {
    if (flightLegs.length > 1) {
      setState(() {
        flightLegs.removeAt(index);
        _showResults = false;
      });
    }
  }

  // --- SEARCH LOGIC ---
  Future<void> _searchFlights() async {
    // 🔥 VALIDATION: Check if date is null
    for (var leg in flightLegs) {
      if (leg['from'] == null || leg['to'] == null || leg['date'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select locations and dates for all flights.")));
        return;
      }
    }

    setState(() { _isLoadingFlights = true; _showResults = false; });
    await Future.delayed(const Duration(seconds: 2));
    setState(() { _isLoadingFlights = false; _showResults = true; });
  }

  // --- UI HELPERS ---
  Widget _buildLocationInput(String label, String? val, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      const SizedBox(height: 4),
      Text(val ?? "Select", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: val == null ? Colors.grey : Colors.blue)),
    ]));
  }

  Widget _buildSelector(String label, String val, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      const SizedBox(height: 4),
      Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ])));
  }

  Widget _buildFlightLegCard(int index) {
    // 🔥 LOGIC: Handle null date display
    String dateText = flightLegs[index]['date'] == null 
        ? "Select Date" 
        : DateFormat('dd MMM yyyy').format(flightLegs[index]['date']);
    
    Color dateColor = flightLegs[index]['date'] == null ? Colors.grey : Colors.blue;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Flight ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                if (flightLegs.length > 1)
                  InkWell(onTap: () => _removeFlightLeg(index), child: const Icon(Icons.close, color: Colors.red, size: 20))
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildLocationInput("From", flightLegs[index]['from'], () => _showCityPicker(index, true))),
                const Icon(Icons.arrow_forward, color: Colors.blue),
                Expanded(child: _buildLocationInput("To", flightLegs[index]['to'], () => _showCityPicker(index, false))),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(index),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: dateColor),
                    const SizedBox(width: 8),
                    Text("Date: $dateText", style: TextStyle(fontWeight: FontWeight.bold, color: dateColor)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(int index) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.flight, color: Colors.blue),
        title: Text("Flight ${index + 1}: ${flightLegs[index]['from']} → ${flightLegs[index]['to']}"),
        // Handle date formatting safely in results too
        subtitle: Text("${DateFormat('MMM dd').format(flightLegs[index]['date']!)} • 08:00 AM • Economy"),
        trailing: const Text("₱3,500", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(flightLegs.length, (index) => _buildFlightLegCard(index)),

          OutlinedButton.icon(
            onPressed: _addFlightLeg,
            icon: const Icon(Icons.add),
            label: const Text("Add Another Flight"),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
          
          const SizedBox(height: 20),

          Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
            Expanded(child: _buildSelector("Passengers", "$totalPassengers", _showPassengerPicker)),
            const VerticalDivider(color: Colors.transparent, thickness: 1, indent: 10, endIndent: 10),
            Expanded(child: _buildSelector("Class", flightClass, _showClassPicker)),
          ]))),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: _isLoadingFlights ? null : _searchFlights,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _isLoadingFlights ? const CircularProgressIndicator(color: Colors.white) : const Text("SEARCH MULTI-CITY FLIGHTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 30),

          if (_showResults) ...[
            const Text("Available Flights:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...List.generate(flightLegs.length, (index) => _buildResultCard(index)),
            
            const SizedBox(height: 20),
            ElevatedButton(
               onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Proceeding to Booking Summary...")));
               }, 
               style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 50),
               ),
               child: const Text("PROCEED TO BOOKING", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
            )
          ]
        ],
      ),
    );
  }
}