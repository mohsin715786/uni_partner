import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_partner/models/user_model.dart';
import 'package:uni_partner/services/password_hasher.dart';

class AuthProvider extends ChangeNotifier {
  static const String _currentUserKey = 'current_user';
  static const String _setupCompletedKey = 'initial_setup_completed';

  // Secure storage keys for sensitive authentication secrets
  static const String _secSaltKey = 'sec_salt';
  static const String _secHashKey = 'sec_hash';
  static const String _secSessionKey = 'sec_session';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isInitialSetupCompleted = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isInitialSetupCompleted => _isInitialSetupCompleted;

  AuthProvider() {
    loadSession();
  }

  /// Restores authentication session state from Android Secure Storage on startup.
  /// Passwords and password hashes are never stored in SharedPreferences.
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isInitialSetupCompleted = prefs.getBool(_setupCompletedKey) ?? false;

      // Verify active session token in FlutterSecureStorage
      final sessionMarker = await _secureStorage.read(key: _secSessionKey);
      _isLoggedIn = (sessionMarker == 'active');

      final userJsonString = prefs.getString(_currentUserKey);
      if (_isLoggedIn &&
          userJsonString != null &&
          userJsonString.trim().isNotEmpty) {
        _currentUser = UserModel.fromJson(
          jsonDecode(userJsonString) as Map<String, dynamic>,
        );
      } else {
        _isLoggedIn = false;
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Error loading secure auth session: $e');
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registers a new student profile locally with cryptographic password hashing (PBKDF2-HMAC-SHA256).
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String university,
    required String department,
    required String semester,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final newUserId = DateTime.now().millisecondsSinceEpoch.toString();

    final newUser = UserModel(
      id: newUserId,
      fullName: fullName.trim(),
      email: cleanEmail,
      university: university.trim(),
      department: department.trim(),
      semester: semester.trim(),
    );

    try {
      // 1. Generate cryptographically secure random salt
      final salt = PasswordHasher.generateSalt();

      // 2. Derive PBKDF2-HMAC-SHA256 password verifier hash
      final verifierHash = PasswordHasher.deriveHash(password, salt);

      // 3. Store authentication secrets exclusively in Secure Storage
      await _secureStorage.write(key: _secSaltKey, value: salt);
      await _secureStorage.write(key: _secHashKey, value: verifierHash);
      await _secureStorage.write(key: _secSessionKey, value: 'active');

      // 4. Store non-sensitive student profile in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));

      _currentUser = newUser;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating secure student account: $e');
      return false;
    }
  }

  /// Updates existing user profile data without modifying secure authentication keys.
  Future<void> updateUserProfile({
    required String fullName,
    required String university,
    required String department,
    required String semester,
  }) async {
    if (_currentUser == null) return;

    final updated = UserModel(
      id: _currentUser!.id,
      fullName: fullName.trim(),
      email: _currentUser!.email,
      university: university.trim(),
      department: department.trim(),
      semester: semester.trim(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(updated.toJson()));
      _currentUser = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  /// Marks the initial first-time setup wizard as completed.
  Future<void> completeInitialSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_setupCompletedKey, true);
      _isInitialSetupCompleted = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing initial setup: $e');
    }
  }

  /// Verifies student login credentials using PBKDF2 key derivation and constant-time hash comparison.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonString = prefs.getString(_currentUserKey);

      if (userJsonString == null || userJsonString.trim().isEmpty) {
        return false;
      }

      final savedUser = UserModel.fromJson(
        jsonDecode(userJsonString) as Map<String, dynamic>,
      );

      // Verify registered email match
      if (savedUser.email.trim().toLowerCase() != email.trim().toLowerCase()) {
        return false;
      }

      // Read secure salt and hash from Android Secure Storage
      final storedSalt = await _secureStorage.read(key: _secSaltKey);
      final storedHash = await _secureStorage.read(key: _secHashKey);

      if (storedSalt == null || storedHash == null) {
        // Legacy demo account without secure credentials
        debugPrint('Secure credentials not found. User must re-register.');
        return false;
      }

      // Compute PBKDF2 hash from entered password and stored salt
      final derivedHash = PasswordHasher.deriveHash(password, storedSalt);

      // Constant-time hash verification against timing side-channel attacks
      final isPasswordValid =
          PasswordHasher.constantTimeCompare(derivedHash, storedHash);

      if (isPasswordValid) {
        await _secureStorage.write(key: _secSessionKey, value: 'active');
        _currentUser = savedUser;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying login credentials: $e');
      return false;
    }
  }

  /// Logs out the current user while preserving registered secure credentials and academic data.
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: _secSessionKey);
      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}
