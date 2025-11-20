import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookRoundTripPage extends StatefulWidget {
  const BookRoundTripPage({super.key});

  @override
  State<BookRoundTripPage> createState() => _BookRoundTripPageState();
}

class _BookRoundTripPageState extends State<BookRoundTripPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? originCity;
  String? destinationCity;
  DateTime? departureDate;
  DateTime? returnDate;
  
  int adultCount = 1;
  int childCount = 0;
  int infantCount = 0;
  int personWithDisabilityCount = 0;
  int ofwCount = 0;
  int seniorCitizenCount = 0;

  String flightClass = 'Economy';

  String? selectedOutboundFlightDocId;
  String? selectedReturnFlightDocId;
  int maxSeatsAvailableOutbound = 0;
  int maxSeatsAvailableReturn = 0;
  bool _isLoadingFlights = false;
  bool _isBooking = false;

  int get totalPassengers => adultCount + childCount + infantCount + personWithDisabilityCount + ofwCount + seniorCitizenCount;

  // --- NEW: Gets the flight query for a specific leg (outbound or return) ---
  Stream<QuerySnapshot> getFlightsStream(String type) {
    String currentOrigin = type == 'outbound' ? originCity ?? 'MNL' : destinationCity ?? 'CEBU';
    String currentDest = type == 'outbound' ? destinationCity ?? 'CEBU' : originCity ?? 'MNL';
    
    // Safety check: if inputs are missing, return an empty stream that doesn't cause the Null error
    if (originCity == null || destinationCity == null || departureDate == null || returnDate == null) {
      // FIX: Returning a stream with an empty list instead of null to match type
      return const Stream.empty(); 
    }
    
    String currentRoute = '$currentOrigin-to-$currentDest';
    
    return _firestore
        .collection('flightbooking')
        .doc('all-round-trip-schedules') 
        .collection(currentRoute)
        .snapshots();
  }

  // --- DATE PICKERS ---
  Future<void> _pickDepartureDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: departureDate ?? now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (picked != null && picked != departureDate) { setState(() { departureDate = picked; if (returnDate != null && returnDate!.isBefore(departureDate!)) { returnDate = departureDate!.add(const Duration(days: 1)); } /* Removed _searchFlights() */ }); }
  }
  Future<void> _pickReturnDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: returnDate ?? (departureDate ?? now).add(const Duration(days: 1)), firstDate: departureDate ?? now.add(const Duration(days: 1)), lastDate: now.add(const Duration(days: 365 * 2)));
    if (picked != null && picked != returnDate) { setState(() { returnDate = picked; /* Removed _searchFlights() */ }); }
  }

  // --- PASSENGER PICKER (Simplified, assuming this method is correct) ---
  Future<void> _showPassengerPicker() async {
    int tempAdult = adultCount; int tempChild = childCount; int tempInfant = infantCount; int tempPWD = personWithDisabilityCount; int tempOFW = ofwCount; int tempSenior = seniorCitizenCount;
    int currentMaxSeats = 99; // Relaxed Max Limit

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) {
        Widget buildRow(String label, String sub, int count, Function(int) onChange) {
          int currentTotal = tempAdult + tempChild + tempInfant + tempPWD + tempOFW + tempSenior;
          bool isIncDisabled = currentTotal >= currentMaxSeats;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), if(sub.isNotEmpty) Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))])), IconButton(onPressed: count <= 0 ? null : () => setModal(() => onChange(count - 1)), icon: Icon(Icons.remove_circle_outline, color: count <= 0 ? Colors.grey : Colors.blue)), SizedBox(width: 20, child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), IconButton(onPressed: isIncDisabled ? null : () => setModal(() => onChange(count + 1)), icon: Icon(Icons.add_circle_outline, color: isIncDisabled ? Colors.grey : Colors.blue))]));
        }
        return Container(padding: const EdgeInsets.all(20), height: 400, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Select Passengers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]), const Divider(),
          Expanded(child: SingleChildScrollView(child: Column(children: [ buildRow('Adult', '12y+', tempAdult, (v) => tempAdult = v), buildRow('Child', '2y-11y', tempChild, (v) => tempChild = v), buildRow('Person with Disability', '', tempPWD, (v) => tempPWD = v), buildRow('Infant', '16d-23m', tempInfant, (v) => tempInfant = v), buildRow('Overseas Filipino Worker', '', tempOFW, (v) => tempOFW = v), buildRow('Senior Citizen', '60y+', tempSenior, (v) => tempSenior = v) ]))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, {'adult': tempAdult, 'child': tempChild, 'pwd': tempPWD, 'infant': tempInfant, 'ofw': tempOFW, 'senior': tempSenior}), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), child: const Text('Continue', style: TextStyle(color: Colors.white)))
        ]));
      }),
    );
    if (result != null) { setState(() { adultCount = result['adult']!; childCount = result['child']!; personWithDisabilityCount = result['pwd']!; infantCount = result['infant']!; ofwCount = result['ofw']!; seniorCitizenCount = result['senior']!; /* Removed _searchFlights() */ }); }
  }

  // --- CLASS PICKER (Assuming this method is correct) ---
  Future<void> _showClassPicker() async {
    String tempClass = flightClass; final classes = ['All Cabin', 'Economy', 'Comfort', 'Premium Economy', 'Business'];
    final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) => Container(padding: const EdgeInsets.all(20), height: 350, child: Column(children: [
          const Text('Select Cabin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          Expanded(child: ListView(children: classes.map((c) => RadioListTile(title: Text(c), value: c, groupValue: tempClass, onChanged: (v) => setModal(() => tempClass = v!))).toList())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, tempClass), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), child: const Text('Continue', style: TextStyle(color: Colors.white))),
    ]))));
    if (selected != null) { setState(() => flightClass = selected); /* Removed _searchFlights() */ }
  }

  // --- CITY PICKER ---
Future<void> _showCityPicker(bool isOrigin) async {
 // NOTE: The codes are in parentheses
 final cities = ['Manila (MNL)', 'Cebu (CEBU)', 'Davao (DVO)', 'Boracay (MPH)', 'Palawan (PPS)']; 
 final selected = await showModalBottomSheet<String>(
 context: context, 
 builder: (ctx) => Container(
 padding: const EdgeInsets.all(20), height: 300, 
 child: ListView(children: cities.map((c) {
 // Extract the code: finds the substring inside parentheses
 final code = c.substring(c.indexOf('(') + 1, c.indexOf(')'));
 return ListTile(
 title: Text(c), 
 // 🔥 FIX: Now passes the code (e.g., 'MNL') to the rest of the app
 onTap: () => Navigator.pop(ctx, code) 
);
 }).toList()),
 ),
 );

 if (selected != null) { 
 setState(() { 
 if (isOrigin) { originCity = selected; if (destinationCity == originCity) destinationCity = null; } 
 else { destinationCity = selected; } 
 selectedOutboundFlightDocId = null; selectedReturnFlightDocId = null; 
 }); 
 }
 }

  // --- FLIGHT SELECTION ---
  void selectFlightLeg(String docId, int seats, String type) {
    setState(() {
      if (type == 'outbound') { selectedOutboundFlightDocId = docId; maxSeatsAvailableOutbound = seats; } 
      else { selectedReturnFlightDocId = docId; maxSeatsAvailableReturn = seats; }
    });
  }

  // --- BOOKING LOGIC ---
  Future<void> handleRoundTripBooking(String status) async {
    if (selectedOutboundFlightDocId == null || selectedReturnFlightDocId == null || totalPassengers <= 0) return;
    setState(() => _isBooking = true);

    final documentPath = 'all-round-trip-schedules';
    final outboundRef = _firestore.collection('flightbooking').doc(documentPath).collection('$originCity-to-$destinationCity').doc(selectedOutboundFlightDocId);
    final returnRef = _firestore.collection('flightbooking').doc(documentPath).collection('$destinationCity-to-$originCity').doc(selectedReturnFlightDocId);

    try {
      await _firestore.runTransaction((transaction) async {
        final outSnap = await transaction.get(outboundRef);
        final retSnap = await transaction.get(returnRef);
        if (!outSnap.exists || !retSnap.exists) throw Exception("Flights not found");
        final outData = outSnap.data() as Map<String, dynamic>;
        final retData = retSnap.data() as Map<String, dynamic>;

        double total = ((outData['price'] ?? 0) + (retData['price'] ?? 0)) * totalPassengers;

        transaction.set(_firestore.collection('bookings').doc(), {
          "status": status, 
          "flightType": "Round Trip", "origin": originCity, "destination": destinationCity,
          "totalPassengers": totalPassengers,
          "passengerDetails": {'adult': adultCount, 'child': childCount, 'disability': personWithDisabilityCount, 'infant': infantCount, 'ofw': ofwCount, 'senior': seniorCitizenCount},
          "class": flightClass, "totalPrice": total, "timestamp": FieldValue.serverTimestamp(),
        });
        transaction.update(outboundRef, {"seatAvailable": outData['seatAvailable'] - totalPassengers});
        transaction.update(returnRef, {"seatAvailable": retData['seatAvailable'] - totalPassengers});
      });

      String msg = status == 'confirmed' ? "Round Trip Booked!" : "Round Trip Reserved!";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() { 
        originCity=null; destinationCity=null; departureDate=null; returnDate=null;
        adultCount=1; childCount=0; infantCount=0; personWithDisabilityCount=0; ofwCount=0; seniorCitizenCount=0;
        selectedOutboundFlightDocId=null; selectedReturnFlightDocId=null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isBooking = false);
    }
  }

  // --- UI HELPERS ---
  Widget _buildLocationInput({required String label, required String? code, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 4), Text(code ?? 'Select', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: code == null ? Colors.grey : Colors.blue))])));
  }
  Widget _buildDateInput({required String label, required DateTime? date, required VoidCallback onTap}) {
    final day = date != null ? DateFormat('dd').format(date) : '--'; final month = date != null ? DateFormat('MMM yyyy').format(date) : 'Select Date';
    return InkWell(onTap: onTap, child: Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 4), Row(children: [Text(day, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)), const SizedBox(width: 12), Text(month, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))])]))));
  }
  Widget _buildSelectionBox({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])));
  }
  // Widget _buildFlightList is now defined below inside the StreamBuilder logic

  // 🔥 IMPLEMENTED: Build the list using the StreamBuilder
  Widget _buildFlightList(String type) {
    if (originCity == null || destinationCity == null || departureDate == null || returnDate == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Select itinerary above.")));
    }
    
    String selectedDocId = type == 'outbound' ? selectedOutboundFlightDocId ?? '' : selectedReturnFlightDocId ?? '';
    DateTime? requiredDate = type == 'outbound' ? departureDate : returnDate;

    return StreamBuilder<QuerySnapshot>(
      stream: getFlightsStream(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No flights found for this route."));
        
        final allDocs = snapshot.data!.docs;
        
        // 1. Filter documents by the exact required date
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['date'] is Timestamp && requiredDate != null) {
            DateTime flightDate = (data['date'] as Timestamp).toDate();
            // Compare only year, month, and day
            return flightDate.year == requiredDate.year && 
                   flightDate.month == requiredDate.month && 
                   flightDate.day == requiredDate.day;
          }
          return false;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Padding(padding: const EdgeInsets.all(20), child: Text("No flights found for the selected ${type} date."));
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDocs.length,
          itemBuilder: (ctx, i) {
            final doc = filteredDocs[i];
            final data = doc.data() as Map<String, dynamic>;
            bool isSel = doc.id == selectedDocId;
            double price = (data['price'] ?? 0).toDouble();
            int seats = data['seatAvailable'] ?? 0;
            
            return Card(
              color: isSel ? Colors.blue.shade50 : Colors.white, 
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isSel ? Colors.blue : Colors.transparent), 
                borderRadius: BorderRadius.circular(10)
              ), 
              child: ListTile(
                onTap: () => selectFlightLeg(doc.id, seats, type),
                title: Text("${data['time']} - ₱${price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Seats: $seats"),
                trailing: isSel ? const Icon(Icons.check_circle, color: Colors.blue) : const Text("Select"),
              )
            );
          },
        );
      },
    );
  }


  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    bool canProceed = selectedOutboundFlightDocId != null && selectedReturnFlightDocId != null && totalPassengers > 0;

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(child: _buildLocationInput(label: 'From', code: originCity, onTap: () => _showCityPicker(true))),
          const Icon(Icons.swap_horiz, color: Colors.blue),
          Expanded(child: _buildLocationInput(label: 'To', code: destinationCity, onTap: () => _showCityPicker(false))),
        ]))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _buildDateInput(label: 'Departure', date: departureDate, onTap: _pickDepartureDate)),
          const SizedBox(width: 10),
          Expanded(child: _buildDateInput(label: 'Return', date: returnDate, onTap: _pickReturnDate)),
        ]),
        const SizedBox(height: 20),
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: _buildSelectionBox(label: 'Passengers', value: '$totalPassengers', onTap: _showPassengerPicker)),
          const VerticalDivider(color: Colors.transparent, thickness: 1, indent: 10, endIndent: 10),
          Expanded(child: _buildSelectionBox(label: 'Class', value: flightClass, onTap: _showClassPicker)),
        ]))),
        
        const SizedBox(height: 20),
        
        // Actual StreamBuilder widgets replacing the old placeholder text
        if (originCity != null && destinationCity != null && departureDate != null && returnDate != null) ...[
             const Text('Outbound:', style: TextStyle(fontWeight: FontWeight.bold)),
             _buildFlightList('outbound'), // Calls the StreamBuilder
             const SizedBox(height: 10),
             const Text('Return:', style: TextStyle(fontWeight: FontWeight.bold)),
             _buildFlightList('return'), // Calls the StreamBuilder
             const SizedBox(height: 20),
        ] else if (_isLoadingFlights) ...[
             const LinearProgressIndicator(),
        ],
        
        Row(children: [
              Expanded(child: OutlinedButton(
                  onPressed: (canProceed && !_isBooking) ? () => handleRoundTripBooking('reserved') : null,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.blue, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isBooking ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text("RESERVE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
             )),
             const SizedBox(width: 16),
              Expanded(child: ElevatedButton(
                  onPressed: (canProceed && !_isBooking) ? () => handleRoundTripBooking('confirmed') : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 5),
                  child: _isBooking ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("BOOK NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             )),
        ]),
        const SizedBox(height: 20),
    ]));
  }
}