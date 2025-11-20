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
  
  // 🔥 Defined _isBooking to prevent errors
  bool _isBooking = false;

  // 🔵 PAYMENT STATE
  String? paymentMethod;

  int get totalPassengers => adultCount + childCount + infantCount + personWithDisabilityCount + ofwCount + seniorCitizenCount;

  // --- PAYMENT MODAL ---
  Future<void> _showPaymentPicker() async {
    final methods = [
      'GCash', 'Maya', 'Debit Card', 'Credit Card', 'Cash at Airport'
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView(
                children: methods
                    .map((m) => ListTile(
                          title: Text(m),
                          onTap: () => Navigator.pop(ctx, m),
                        ))
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );

    if (selected != null) setState(() => paymentMethod = selected);
  }

  // --- FLIGHT STREAM ---
  Stream<QuerySnapshot> getFlightsStream(String type) {
    String currentOrigin = type == 'outbound' ? originCity ?? 'MNL' : destinationCity ?? 'CEBU';
    String currentDest = type == 'outbound' ? destinationCity ?? 'CEBU' : originCity ?? 'MNL';
    
    if (originCity == null || destinationCity == null || departureDate == null || returnDate == null) {
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
    if (picked != null && picked != departureDate) { setState(() { departureDate = picked; if (returnDate != null && returnDate!.isBefore(departureDate!)) { returnDate = departureDate!.add(const Duration(days: 1)); } }); }
  }
  Future<void> _pickReturnDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: returnDate ?? (departureDate ?? now).add(const Duration(days: 1)), firstDate: departureDate ?? now.add(const Duration(days: 1)), lastDate: now.add(const Duration(days: 365 * 2)));
    if (picked != null && picked != returnDate) { setState(() { returnDate = picked; }); }
  }

  // --- PASSENGER PICKER ---
  Future<void> _showPassengerPicker() async {
    int tempAdult = adultCount; int tempChild = childCount; int tempInfant = infantCount; int tempPWD = personWithDisabilityCount; int tempOFW = ofwCount; int tempSenior = seniorCitizenCount;
    int currentMaxSeats = 99; 

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
    if (result != null) { setState(() { adultCount = result['adult']!; childCount = result['child']!; personWithDisabilityCount = result['pwd']!; infantCount = result['infant']!; ofwCount = result['ofw']!; seniorCitizenCount = result['senior']!; }); }
  }

  // --- CLASS PICKER ---
  Future<void> _showClassPicker() async {
    String tempClass = flightClass; final classes = ['All Cabin', 'Economy', 'Comfort', 'Premium Economy', 'Business'];
    final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) => Container(padding: const EdgeInsets.all(20), height: 350, child: Column(children: [
          const Text('Select Cabin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          Expanded(child: ListView(children: classes.map((c) => RadioListTile(title: Text(c), value: c, groupValue: tempClass, onChanged: (v) => setModal(() => tempClass = v!))).toList())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, tempClass), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), child: const Text('Continue', style: TextStyle(color: Colors.white))),
    ]))));
    if (selected != null) { setState(() => flightClass = selected); }
  }

  // --- CITY PICKER ---
  Future<void> _showCityPicker(bool isOrigin) async {
    final cityMap = {
      'Manila (MNL)': 'MNL', 'Cebu (CEBU)': 'CEBU', 'Davao (DVO)': 'DVO', 'Boracay (MPH)': 'MPH',
      'Palawan (PPS)': 'PPS', 'Bicol (BKO)': 'BKO', 'Zamboanga (ZAM)': 'ZAM', 'Iloilo (ILO)': 'ILO',
    };
    final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => Container(padding: const EdgeInsets.all(20), height: 300, child: ListView(children: cityMap.entries.map((e) => ListTile(title: Text(e.key), onTap: () => Navigator.pop(ctx, e.value))).toList())));
    if (selected != null) { setState(() { if (isOrigin) { originCity = selected; if (destinationCity == originCity) destinationCity = null; } else { destinationCity = selected; } selectedOutboundFlightDocId = null; selectedReturnFlightDocId = null; paymentMethod = null; }); }
  }

  // --- FLIGHT SELECTION ---
  void selectFlightLeg(String docId, int seats, String type) {
    setState(() {
      if (type == 'outbound') { selectedOutboundFlightDocId = docId; maxSeatsAvailableOutbound = seats; } 
      else { selectedReturnFlightDocId = docId; maxSeatsAvailableReturn = seats; }
      // Optional: Reset payment when flight selection changes
      // paymentMethod = null;
    });
  }

  // --- BOOKING LOGIC (UPDATED: FORCES TEXT DATE SAVE) ---
  Future<void> handleRoundTripBooking(String status) async {
    if (selectedOutboundFlightDocId == null || selectedReturnFlightDocId == null || totalPassengers <= 0 || paymentMethod == null) return;
    
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

        // 🔥 CRITICAL FIX: Convert Timestamp to String "YYYY-MM-DD"
        DateTime outDateRaw = (outData['date'] as Timestamp).toDate();
        String outDateString = DateFormat('yyyy-MM-dd').format(outDateRaw); // This creates a String!

        DateTime retDateRaw = (retData['date'] as Timestamp).toDate();
        String retDateString = DateFormat('yyyy-MM-dd').format(retDateRaw); // This creates a String!

        double total = ((outData['price'] ?? 0) + (retData['price'] ?? 0)) * totalPassengers;

        transaction.set(_firestore.collection('bookings').doc(), {
          "status": status, 
          "flightType": "Round Trip", 
          "origin": originCity, 
          "destination": destinationCity,
          
          // 🔵 SAVING AS STRING (Clean Text, No Time)
          "outboundFlightDate": outDateString,
          "outboundFlightTime": outData['time'],
          "returnFlightDate": retDateString,
          "returnFlightTime": retData['time'],

          "totalPassengers": totalPassengers,
          "paymentMethod": paymentMethod,
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
        paymentMethod = null;
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
        
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['date'] is Timestamp && requiredDate != null) {
            DateTime flightDate = (data['date'] as Timestamp).toDate();
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

  @override
  Widget build(BuildContext context) {
    bool canProceed = selectedOutboundFlightDocId != null && selectedReturnFlightDocId != null && totalPassengers > 0 && paymentMethod != null;

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        
        // LOCATION CARD with SWAP BUTTON 🔄
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(child: _buildLocationInput(label: 'From', code: originCity, onTap: () => _showCityPicker(true))),
          
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.blue),
            onPressed: () {
              if (originCity != null && destinationCity != null) {
                setState(() {
                  String temp = originCity!;
                  originCity = destinationCity;
                  destinationCity = temp;
                  selectedOutboundFlightDocId = null;
                  selectedReturnFlightDocId = null;
                  paymentMethod = null;
                });
              }
            },
          ),

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
        
        const SizedBox(height: 10),

        // 🔵 PAYMENT METHOD CARD
        Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
                onTap: _showPaymentPicker,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.payment, color: Colors.blue),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Payment Method", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text(paymentMethod ?? "Select Payment Method", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ])
                  ]),
                ))),
        
        const SizedBox(height: 20),
        
        if (originCity != null && destinationCity != null && departureDate != null && returnDate != null) ...[
             const Text('Outbound:', style: TextStyle(fontWeight: FontWeight.bold)),
             _buildFlightList('outbound'), 
             const SizedBox(height: 10),
             const Text('Return:', style: TextStyle(fontWeight: FontWeight.bold)),
             _buildFlightList('return'), 
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