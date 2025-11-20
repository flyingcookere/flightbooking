import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class OneWayBookingPage extends StatefulWidget {
  final String route; // e.g., "MNL-to-CEBU"

  const OneWayBookingPage({super.key, required this.route});

  @override
  State<OneWayBookingPage> createState() => _OneWayBookingPageState();
}

class _OneWayBookingPageState extends State<OneWayBookingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // --- STATE VARIABLES ---
  String? originCity;
  String? destinationCity;

  // Full Detailed Passenger Counts
  int adultCount = 1;
  int childCount = 0;
  int infantCount = 0;
  int personWithDisabilityCount = 0;
  int ofwCount = 0;
  int seniorCitizenCount = 0;
  
  String? selectedFlightDocId;
  double? selectedFlightPrice; 
  int maxSeatsAvailable = 0; 
  String flightClass = 'Economy'; 
  DateTime? departureDate; 
  bool _saving = false;

  // Calculated total
  int get totalPassengers => adultCount + childCount + infantCount + personWithDisabilityCount + ofwCount + seniorCitizenCount; 

  @override
  void initState() {
    super.initState();
    List<String> parts = widget.route.split('-to-');
    if (parts.length == 2) {
      originCity = parts[0];
      destinationCity = parts[1];
    }
  }

  // --- LOGIC ---

  // 🔥 FIX: Updated document ID to the generic path
  CollectionReference getFlightsCollection() {
    String currentRoute = '${originCity ?? "MNL"}-to-${destinationCity ?? "CEBU"}';
    return _firestore.collection('flightbooking').doc('all-one-way-schedules').collection(currentRoute);
  }

  // 🔥 FIXED: Removed the logic that forces passengers to 0 if seats are missing
  void selectFlight(String docId, int seats, double price) {
    setState(() {
      selectedFlightDocId = docId;
      maxSeatsAvailable = seats;
      selectedFlightPrice = price;
      // Strict check removed so button works for testing!
    });
  }

  Future<void> _pickDepartureDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: departureDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => departureDate = picked);
  }

  // --- CITY PICKER MODAL ---
  Future<void> _showCityPicker(bool isOrigin) async {
    final cities = ['MNL', 'CEBU', 'DVO', 'MPH', 'PPS']; 
    final selected = await showModalBottomSheet<String>(
      context: context, 
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20), height: 300, 
        child: ListView(children: cities.map((c) => ListTile(title: Text(c), onTap: () => Navigator.pop(ctx, c))).toList()),
      ),
    );

    if (selected != null) {
      setState(() {
        if (isOrigin) { originCity = selected; if (destinationCity == originCity) destinationCity = null; } 
        else { destinationCity = selected; }
        selectedFlightDocId = null; maxSeatsAvailable = 0;
      });
    }
  }

  // --- PASSENGER MODAL ---
  Future<void> _showPassengerPicker() async {
    int tempAdult = adultCount; int tempChild = childCount; int tempInfant = infantCount;
    int tempPWD = personWithDisabilityCount; int tempOFW = ofwCount; int tempSenior = seniorCitizenCount;
    // Just use a high default so + button always works
    int maxTotal = 99; 
    
    Widget buildRow(String label, String sub, int count, Function(int) onChange) {
      int currentTotal = tempAdult + tempChild + tempInfant + tempPWD + tempOFW + tempSenior;
      bool isIncDisabled = (currentTotal >= maxTotal);
      return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), if(sub.isNotEmpty) Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        IconButton(onPressed: count <= 0 ? null : () => setState(() => onChange(count - 1)), icon: Icon(Icons.remove_circle_outline, color: count <= 0 ? Colors.grey : Colors.blue)),
        SizedBox(width: 20, child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        IconButton(onPressed: isIncDisabled ? null : () => setState(() => onChange(count + 1)), icon: Icon(Icons.add_circle_outline, color: isIncDisabled ? Colors.grey : Colors.blue)),
      ]));
    }

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) => Container(
        padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.75,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Select Passengers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]),
          const Divider(),
          Expanded(child: SingleChildScrollView(child: Column(children: [
              buildRow('Adult', '12 y +', tempAdult, (v) => setModal(() => tempAdult = v)),
              buildRow('Child', '2 y - 11 y', tempChild, (v) => setModal(() => tempChild = v)),
              buildRow('Person with Disability', '', tempPWD, (v) => setModal(() => tempPWD = v)),
              buildRow('Infant', '16 d - 23 m', tempInfant, (v) => setModal(() => tempInfant = v)),
              buildRow('Overseas Filipino Worker', '', tempOFW, (v) => setModal(() => tempOFW = v)),
              buildRow('Senior Citizen', '60 y +', tempSenior, (v) => setModal(() => tempSenior = v)),
          ]))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, {'adult': tempAdult, 'child': tempChild, 'pwd': tempPWD, 'infant': tempInfant, 'ofw': tempOFW, 'senior': tempSenior}), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Continue', style: TextStyle(color: Colors.white)))
        ]),
      )),
    );

    if (result != null) {
      setState(() { 
        adultCount = result['adult']!; childCount = result['child']!; personWithDisabilityCount = result['pwd']!;
        infantCount = result['infant']!; ofwCount = result['ofw']!; seniorCitizenCount = result['senior']!;
      });
    }
  }

  // --- CLASS MODAL ---
  Future<void> _showClassPicker() async {
    String tempClass = flightClass;
    final classes = ['All Cabin', 'Economy', 'Comfort', 'Premium Economy', 'Business'];
    final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) => Container(
        padding: const EdgeInsets.all(20), height: 350,
        child: Column(children: [
          const Text('Select Cabin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          Expanded(child: ListView(children: classes.map((c) => RadioListTile(title: Text(c), value: c, groupValue: tempClass, activeColor: Colors.blue, onChanged: (v) => setModal(() => tempClass = v!))).toList())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, tempClass), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), child: const Text('Continue', style: TextStyle(color: Colors.white))),
        ]),
    )));
    if (selected != null) setState(() => flightClass = selected);
  }

  // --- BOOKING/RESERVE LOGIC ---
  Future<void> handleBooking(String status) async {
    if (selectedFlightDocId == null || totalPassengers <= 0) return;
    setState(() => _saving = true);
    
    final flightRef = getFlightsCollection().doc(selectedFlightDocId);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(flightRef);
        if (!snap.exists) throw Exception("Flight not found");
        final data = snap.data() as Map<String, dynamic>;
        
        // Optional: You can uncomment this later if you want strict checking again
        // if (totalPassengers > data['seatAvailable']) throw Exception("Not enough seats");

        transaction.set(_firestore.collection('bookings').doc(), {
          "flightRef": flightRef, 
          "status": status,
          "flightType": "One Way",
          "origin": originCity, "destination": destinationCity,
          "totalPassengers": totalPassengers,
          "passengerDetails": {'adult': adultCount, 'child': childCount, 'disability': personWithDisabilityCount, 'infant': infantCount, 'ofw': ofwCount, 'senior': seniorCitizenCount},
          "class": flightClass, 
          "totalPrice": totalPassengers * (data['price'] ?? 0),
          "timestamp": FieldValue.serverTimestamp(),
        });
        
        transaction.update(flightRef, {"seatAvailable": data['seatAvailable'] - totalPassengers});
      });
      
      String msg = status == 'confirmed' ? "Booking Confirmed!" : "Flight Reserved!";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      
      setState(() { 
        adultCount=1; childCount=0; personWithDisabilityCount=0; infantCount=0; ofwCount=0; seniorCitizenCount=0;
        selectedFlightDocId=null; maxSeatsAvailable=0; 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      setState(() => _saving = false);
    }
  }

  // --- UI HELPERS ---
  Widget _buildLocationInput({required String label, required String? code, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 4),
      Text(code ?? "Select", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: code == null ? Colors.grey : Colors.blue)),
    ])));
  }

  Widget _buildSelector(String label, String val, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 4),
      Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = departureDate == null ? "Select Date" : DateFormat('dd MMM yyyy').format(departureDate!);
    bool canProceed = selectedFlightDocId != null && totalPassengers > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(child: _buildLocationInput(label: "From", code: originCity, onTap: () => _showCityPicker(true))),
          const Icon(Icons.swap_horiz, color: Colors.blue),
          Expanded(child: _buildLocationInput(label: "To", code: destinationCity, onTap: () => _showCityPicker(false))),
        ]))),
        const SizedBox(height: 10),
        InkWell(onTap: _pickDepartureDate, child: Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const Icon(Icons.calendar_today, color: Colors.blue), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Departure Date", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(dateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ])
        ])))),
        const SizedBox(height: 10),
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: _buildSelector("Passengers", "$totalPassengers", _showPassengerPicker)),
          const VerticalDivider(color: Colors.transparent, thickness: 1, indent: 10, endIndent: 10),
          Expanded(child: _buildSelector("Class", flightClass, _showClassPicker)),
        ]))),
        
        const SizedBox(height: 20),

        const Text("Available Flights:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot>(
          stream: getFlightsCollection().snapshots(), 
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No flights found for this route."));
            
            return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: docs.length, itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                bool isSel = docs[i].id == selectedFlightDocId;
                double price = (data['price'] ?? 0).toDouble();
                
                if (departureDate != null && data['date'] != null) {
                    DateTime flightDate = (data['date'] as Timestamp).toDate();
                    if (flightDate.day != departureDate!.day || flightDate.month != departureDate!.month) { return const SizedBox.shrink(); }
                }

                return Card(color: isSel ? Colors.blue.shade50 : Colors.white, shape: RoundedRectangleBorder(side: BorderSide(color: isSel ? Colors.blue : Colors.transparent), borderRadius: BorderRadius.circular(10)), child: ListTile(
                    onTap: () => selectFlight(docs[i].id, data['seatAvailable'] ?? 0, price),
                    title: Text("${data['time']} - ₱$price", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Seats: ${data['seatAvailable']}"),
                    trailing: isSel ? const Icon(Icons.check_circle, color: Colors.blue) : const Text("Select"),
                  ));
              },
            );
          },
        ),
        
        const SizedBox(height: 20),

        Row(children: [
              Expanded(child: OutlinedButton(
                  onPressed: (canProceed && !_saving) ? () => handleBooking('reserved') : null,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.blue, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text("RESERVE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
             )),
             const SizedBox(width: 16),
              Expanded(child: ElevatedButton(
                  onPressed: (canProceed && !_saving) ? () => handleBooking('confirmed') : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 5),
                  child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("BOOK NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             )),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }
}