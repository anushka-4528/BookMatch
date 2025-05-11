import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Stream to listen for auth changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign up with email and password
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners(); // Notify UI after sign-up
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthError(e));
    } catch (e) {
      throw Exception("Something went wrong during sign up.");
    }
  }

  // Login with email and password
  Future<void> login({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners(); // Notify UI after login
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthError(e));
    } catch (e) {
      throw Exception("Something went wrong during login.");
    }
  }

  // Logout user
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    notifyListeners(); // Notify UI after logout
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
      notifyListeners(); // Notify UI after account deletion
    } catch (e) {
      throw Exception("Failed to delete account.");
    }
  }

  // Handle FirebaseAuth error messages
  String _getFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error'}';
    }
  }
}
