import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Existing Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ⭐️ NEW Controllers for User Info ⭐️
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  final AuthService _authService = AuthService();
  bool loading = false;
  String status = '';
  
  // ⭐️ State for Birth Date ⭐️
  DateTime? _selectedDate;

  // ⭐️ Calculates age automatically ⭐️
  int get _userAge {
    if (_selectedDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    // Adjust age if the birthday hasn't occurred yet this year
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  // ⭐️ Date Picker Function ⭐️
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000), // Default to a reasonable year
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // User cannot select a future date
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ⭐️ CORRECTED: Signup function passes all parameters to AuthService ⭐️
  Future<void> _signup() async {
    // Basic validation to ensure required fields are filled
    if (_selectedDate == null || 
        firstNameController.text.isEmpty || 
        lastNameController.text.isEmpty ||
        contactNumberController.text.isEmpty) {
      setState(() {
        status = 'Please fill out all required fields (Name, Date, Contact).';
      });
      return;
    }

    setState(() {
      loading = true;
      status = '';
    });

    // Passing all required parameters to the updated AuthService
    final error = await _authService.signUp(
      emailController.text.trim(),
      passwordController.text.trim(),
      firstName: firstNameController.text.trim(),
      middleName: middleNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      birthDate: _selectedDate!,
      contactNumber: contactNumberController.text.trim(),
      age: _userAge,
    );

    if (mounted) {
      setState(() => loading = false);
      if (error == null) {
        Navigator.pushReplacementNamed(context, '/login',
            arguments: {'message': 'Account created. Check Gmail to verify.'});
      } else {
        setState(() => status = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            "https://50skyshades.com/images/o/4743-nLUoxf0MGVFEYlQ7Hlj9r0tuB.jpg",
            fit: BoxFit.cover,
          ),
          // Signup form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Container(
                width: screenWidth * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Sign Up",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF)),
                    ),
                    const SizedBox(height: 30),
                    
                    // --- Name Fields ---
                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: "First Name",
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: middleNameController,
                      decoration: InputDecoration(
                        labelText: "Middle Name (Optional)",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: "Last Name",
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Contact Number ---
                    TextField(
                      controller: contactNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Contact Number",
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- Birth Date Picker and Age ---
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Birth Date",
                          prefixIcon: const Icon(Icons.calendar_month),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate == null ? Colors.grey[700] : Colors.black,
                              ),
                            ),
                            Text(
                              _selectedDate == null ? '' : 'Age: $_userAge',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6C63FF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Authentication Fields ---
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Sign Up Button ---
                    SizedBox(
                      width: double.infinity,
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                backgroundColor: const Color(0xFF6C63FF),
                              ),
                              child: const Text("Sign Up",
                                  style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                    ),
                    const SizedBox(height: 12),
                    
                    // --- Status/Error Message ---
                    Text(status, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    
                    // --- Login Link ---
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text("Already have an account? Login",
                          style: TextStyle(color: Color(0xFF6C63FF))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}