import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Isolated Firebase Authentication service for university course assignment.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Registers a student with email and password via Firebase Auth.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('FirebaseAuthService register error: $e');
      rethrow;
    }
  }

  /// Logs in a student with email and password via Firebase Auth.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('FirebaseAuthService login error: $e');
      rethrow;
    }
  }

  /// Signs out current Firebase Authentication user.
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('FirebaseAuthService logout error: $e');
      rethrow;
    }
  }
}
