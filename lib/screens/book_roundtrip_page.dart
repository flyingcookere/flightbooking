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
  
  // --- STATE VARIABLES ---
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

  List<Map<String, dynamic>> availableFlights = [];
  String? selectedOutboundFlightDocId;
  String? selectedReturnFlightDocId;
  int maxSeatsAvailableOutbound = 0;
  int maxSeatsAvailableReturn = 0;
  bool _isLoadingFlights = false;
  bool _isBooking = false;

  int get totalPassengers => adultCount + childCount + infantCount + personWithDisabilityCount + ofwCount + seniorCitizenCount;

  // --- DATE PICKERS ---
  Future<void> _pickDepartureDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: departureDate ?? now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (picked != null && picked != departureDate) {
      setState(() {
        departureDate = picked;
        if (returnDate != null && returnDate!.isBefore(departureDate!)) {
          returnDate = departureDate!.add(const Duration(days: 1));
        }
        _searchFlights();
      });
    }
  }

  Future<void> _pickReturnDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: returnDate ?? (departureDate ?? now).add(const Duration(days: 1)), firstDate: departureDate ?? now.add(const Duration(days: 1)), lastDate: now.add(const Duration(days: 365 * 2)));
    if (picked != null && picked != returnDate) { setState(() { returnDate = picked; _searchFlights(); }); }
  }

  // --- PASSENGER PICKER ---
  Future<void> _showPassengerPicker() async {
    int tempAdult = adultCount; int tempChild = childCount; int tempInfant = infantCount;
    int tempPWD = personWithDisabilityCount; int tempOFW = ofwCount; int tempSenior = seniorCitizenCount;
    int maxTotal = 9; 

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) {
        Widget buildRow(String label, String sub, int count, Function(int) onChange) {
          int currentTotal = tempAdult + tempChild + tempInfant + tempPWD + tempOFW + tempSenior;
          bool isIncDisabled = (maxTotal > 0 && currentTotal >= maxTotal);
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
            ElevatedButton(onPressed: () {
               if (tempAdult + tempChild + tempInfant == 0) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("At least one passenger required.")));
               } else {
                 Navigator.pop(ctx, {'adult': tempAdult, 'child': tempChild, 'pwd': tempPWD, 'infant': tempInfant, 'ofw': tempOFW, 'senior': tempSenior});
               }
            }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Continue', style: TextStyle(color: Colors.white)))
          ]),
        );
      }),
    );
    if (result != null) { setState(() { adultCount = result['adult']!; childCount = result['child']!; personWithDisabilityCount = result['pwd']!; infantCount = result['infant']!; ofwCount = result['ofw']!; seniorCitizenCount = result['senior']!; _searchFlights(); }); }
  }

  // --- CLASS PICKER ---
  Future<void> _showClassPicker() async {
    String tempClass = flightClass;
    final classes = ['All Cabin', 'Economy', 'Comfort', 'Premium Economy', 'Business'];
    final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) => Container(padding: const EdgeInsets.all(20), height: 350, child: Column(children: [
          const Text('Select Cabin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          Expanded(child: ListView(children: classes.map((c) => RadioListTile(title: Text(c), value: c, groupValue: tempClass, onChanged: (v) => setModal(() => tempClass = v!))).toList())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, tempClass), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), child: const Text('Continue', style: TextStyle(color: Colors.white))),
    ]))));
    if (selected != null) { setState(() => flightClass = selected); _searchFlights(); }
  }

  // --- SEARCH LOGIC ---
  Future<void> _searchFlights() async {
    if (originCity == null || destinationCity == null || departureDate == null || returnDate == null) { setState(() { availableFlights = []; }); return; }
    setState(() { _isLoadingFlights = true; availableFlights = []; });
    // Simulate Search delay (Replace with real query)
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _isLoadingFlights = false; });
  }

  void selectFlightLeg(String docId, int seats, String type) {
    setState(() {
      if (type == 'outbound') { selectedOutboundFlightDocId = docId; maxSeatsAvailableOutbound = seats; } 
      else { selectedReturnFlightDocId = docId; maxSeatsAvailableReturn = seats; }
    });
  }

  // --- BOOKING LOGIC ---
  Future<void> bookRoundTrip() async {
    if (selectedOutboundFlightDocId == null || selectedReturnFlightDocId == null || totalPassengers <= 0) return;
    setState(() => _isBooking = true);
    // ... (Firebase logic here, omitted for brevity but assumed present in your setup)
    await Future.delayed(const Duration(seconds: 2)); // Simulating booking
    setState(() => _isBooking = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Successful (Simulation)!")));
  }

  // --- UI Helpers ---
  Future<void> _showCityPicker(bool isOrigin) async {
    final cities = ['Manila (MNL)', 'Cebu (CEB)', 'Davao (DVO)', 'Boracay (MPH)', 'Palawan (PPS)']; 
    final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => Container(padding: const EdgeInsets.all(20), height: 300, child: ListView(children: cities.map((c) => ListTile(title: Text(c), onTap: () => Navigator.pop(ctx, c.split(' ')[0]))).toList())));
    if (selected != null) { setState(() { if (isOrigin) { originCity = selected; if (destinationCity == originCity) destinationCity = null; } else { destinationCity = selected; } selectedOutboundFlightDocId = null; selectedReturnFlightDocId = null; availableFlights = []; _searchFlights(); }); }
  }

  Widget _buildLocationInput({required String label, required String? code, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 4),
      Text(code ?? 'Select', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: code == null ? Colors.grey : Colors.blue)),
    ])));
  }
  
  Widget _buildDateInput({required String label, required DateTime? date, required VoidCallback onTap}) {
      final day = date != null ? DateFormat('dd').format(date) : '--';
      final month = date != null ? DateFormat('MMM yyyy').format(date) : 'Select Date';
      return InkWell(onTap: onTap, child: Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 4),
        Row(children: [Text(day, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)), const SizedBox(width: 12), Text(month, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
      ]))));
  }

  Widget _buildSelectionBox({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ])));
  }

  Widget _buildFlightList(String type) {
     return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No flights found (Demo Mode)")));
  }

  @override
  Widget build(BuildContext context) {
    bool canBook = selectedOutboundFlightDocId != null && selectedReturnFlightDocId != null && totalPassengers > 0;

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
        if ((originCity != null && destinationCity != null && departureDate != null && returnDate != null) || _isLoadingFlights) ...[
            const Text('Available Flights:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Consistent Header
            const Divider(),
            const Text('Outbound:', style: TextStyle(fontWeight: FontWeight.bold)), _buildFlightList('outbound'),
            const SizedBox(height: 10),
            const Text('Return:', style: TextStyle(fontWeight: FontWeight.bold)), _buildFlightList('return'),
            const SizedBox(height: 20),
        ],
        ElevatedButton(
          onPressed: canBook && !_isBooking ? bookRoundTrip : null, 
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, 
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 16), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(double.infinity, 50),
          ), 
          child: _isBooking ? const CircularProgressIndicator(color: Colors.white) : const Text("BOOK ROUND TRIP", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
        ),
    ]));
  }
}