import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Updated Sign Up: Now includes a default 'role'
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      // 1. Create the user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // 2. AUTOMATICALLY create the Firestore document with the 'role' field
        // This ensures you never have to add it manually in the console!
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': 'buyer',
          'isVerifiedSeller': false,
          'createdAt': FieldValue.serverTimestamp(),
          'cart': [],
        });
        debugPrint("✅ Database initialized for ${user.email} with role: buyer");
      }
      return user;
    } catch (e) {
      debugPrint("❌ Signup Error: ${e.toString()}");
      return null;
    }
  }

  // 2. Helper Method: Fetch User Data
  // This allows your Login Screen to check roles securely
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      return null;
    }
  }

  // Login
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
  // Inside AuthService class
  Future<List<Map<String, dynamic>>> getPersistentCart(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['cart'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching cart: $e");
    }
    return [];
  }
  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}