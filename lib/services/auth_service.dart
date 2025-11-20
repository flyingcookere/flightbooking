import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ UPDATED: SIGN UP method now accepts all new user fields ⭐️
  Future<String?> signUp(
    String email, 
    String password, {
    required String firstName,
    required String middleName,
    required String lastName,
    required DateTime birthDate,
    required int age,
    required String contactNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      if (result.user != null) {
        await result.user!.sendEmailVerification();
      }

      // ⭐️ SAVE FULL PROFILE TO FIRESTORE ⭐️
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid, // Store UID explicitly
        'email': email,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'birthDate': Timestamp.fromDate(birthDate), // Convert DateTime to Firestore Timestamp
        'age': age,
        'contactNumber': contactNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Logout immediately to force verification upon next login
      await _auth.signOut();

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Signup failed: $e";
    }
  }

  // LOGIN (Unchanged)
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      final user = _auth.currentUser;
      await user?.reload(); // refresh info

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        return "Please verify your email before logging in.";
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login failed: $e";
    }
  }

  // LOGOUT (Unchanged)
  Future<void> logout() async {
    await _auth.signOut();
  }

  // GET CURRENT USER (Unchanged)
  User? get currentUser => _auth.currentUser;
}