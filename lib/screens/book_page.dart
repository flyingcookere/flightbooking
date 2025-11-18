import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class BookPage extends StatefulWidget {
  const BookPage({Key? key}) : super(key: key);

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  // Booking type
  String bookingType = 'One Way';

  // Controllers for One Way / Round Trip
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  DateTime? departureDate;
  DateTime? returnDate; // only for round trip
  int passengers = 1;
  String flightClass = 'Economy';

  // Multi-City legs
  List<Map<String, dynamic>> flightLegs = [
    {'from': '', 'to': '', 'date': DateTime.now()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Flight')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Booking type selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => bookingType = 'One Way'),
                  child: Text('One Way'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => bookingType = 'Round Trip'),
                  child: Text('Round Trip'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => bookingType = 'Multi-City'),
                  child: Text('Multi-City'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Conditional forms
            if (bookingType == 'One Way') buildOneWayForm(),
            if (bookingType == 'Round Trip') buildRoundTripForm(),
            if (bookingType == 'Multi-City') buildMultiCityForm(),
          ],
        ),
      ),
    );
  }

  // ---------------------- FORMS ------------------------

  Widget buildOneWayForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: fromController,
            decoration: InputDecoration(labelText: 'From'),
          ),
          TextField(
            controller: toController,
            decoration: InputDecoration(labelText: 'To'),
          ),
          ListTile(
            title: Text('Departure: ${departureDate != null ? departureDate!.toLocal().toString().split(' ')[0] : 'Select Date'}'),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: departureDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => departureDate = picked);
            },
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Passengers'),
            keyboardType: TextInputType.number,
            onChanged: (val) => passengers = int.tryParse(val) ?? 1,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Class'),
            onChanged: (val) => flightClass = val,
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: bookFlight, child: Text('Book')),
        ],
      ),
    );
  }

  Widget buildRoundTripForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(controller: fromController, decoration: InputDecoration(labelText: 'From')),
          TextField(controller: toController, decoration: InputDecoration(labelText: 'To')),
          ListTile(
            title: Text('Departure: ${departureDate != null ? departureDate!.toLocal().toString().split(' ')[0] : 'Select Date'}'),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: departureDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => departureDate = picked);
            },
          ),
          ListTile(
            title: Text('Return: ${returnDate != null ? returnDate!.toLocal().toString().split(' ')[0] : 'Select Date'}'),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: returnDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => returnDate = picked);
            },
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Passengers'),
            keyboardType: TextInputType.number,
            onChanged: (val) => passengers = int.tryParse(val) ?? 1,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Class'),
            onChanged: (val) => flightClass = val,
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: bookFlight, child: Text('Book')),
        ],
      ),
    );
  }

  Widget buildMultiCityForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: flightLegs.length,
            itemBuilder: (context, index) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(labelText: 'From'),
                        onChanged: (val) => flightLegs[index]['from'] = val,
                      ),
                      TextField(
                        decoration: InputDecoration(labelText: 'To'),
                        onChanged: (val) => flightLegs[index]['to'] = val,
                      ),
                      ListTile(
                        title: Text('Date: ${flightLegs[index]['date'].toLocal().toString().split(' ')[0]}'),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: flightLegs[index]['date'],
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100));
                          if (picked != null) setState(() => flightLegs[index]['date'] = picked);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => setState(() => flightLegs.add({'from': '', 'to': '', 'date': DateTime.now()})),
            child: Text('Add Flight Leg'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Passengers'),
            keyboardType: TextInputType.number,
            onChanged: (val) => passengers = int.tryParse(val) ?? 1,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Class'),
            onChanged: (val) => flightClass = val,
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: bookFlight, child: Text('Book')),
        ],
      ),
    );
  }

  // ---------------------- BOOK FUNCTION ------------------------
  void bookFlight() async {
    Map<String, dynamic> data = {
      'type': bookingType,
      'passengers': passengers,
      'class': flightClass,
    };

    if (bookingType == 'One Way') {
      data.addAll({
        'from': fromController.text,
        'to': toController.text,
        'departureDate': departureDate?.toIso8601String(),
      });
    } else if (bookingType == 'Round Trip') {
      data.addAll({
        'from': fromController.text,
        'to': toController.text,
        'departureDate': departureDate?.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
      });
    } else {
      data['legs'] = flightLegs.map((leg) => {
        'from': leg['from'],
        'to': leg['to'],
        'date': leg['date'].toIso8601String(),
      }).toList();
    }

    // Call your Firestore service
    await FirestoreService().bookFlight(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Flight booked successfully!')),
    );
  }
}
