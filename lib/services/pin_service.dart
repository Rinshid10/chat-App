import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Service for managing the app's 4-digit PIN lock feature.
/// PIN is hashed with SHA256 before storing for security.
class PinService extends ChangeNotifier {
  static const String _pinHashKey = 'app_pin_hash';
  static const String _pinEnabledKey = 'pin_enabled';

  bool _isPinEnabled = false;
  bool get isPinEnabled => _isPinEnabled;

  /// Initialize the service by loading current PIN state
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPinEnabled = prefs.getBool(_pinEnabledKey) ?? false;
    notifyListeners();
  }

  /// Check if PIN lock is enabled
  Future<bool> checkPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _isPinEnabled = prefs.getBool(_pinEnabledKey) ?? false;
    return _isPinEnabled;
  }

  /// Set a new PIN (hashes the PIN before storing)
  Future<void> setPin(String pin) async {
    if (pin.length != 4) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }

    try {
      // Hash the PIN using SHA256
      final hash = sha256.convert(utf8.encode(pin)).toString();
      debugPrint('PIN hash generated');

      // Store hash in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinHashKey, hash);
      await prefs.setBool(_pinEnabledKey, true);

      _isPinEnabled = true;
      notifyListeners();

      debugPrint('PIN has been set successfully');
    } catch (e, stackTrace) {
      debugPrint('Error setting PIN: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Verify if the entered PIN matches the stored PIN
  Future<bool> verifyPin(String pin) async {
    if (pin.length != 4) {
      return false;
    }

    try {
      // Hash the entered PIN
      final hash = sha256.convert(utf8.encode(pin)).toString();

      // Get stored hash
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_pinHashKey);

      if (storedHash == null) {
        debugPrint('No PIN stored');
        return false;
      }

      return hash == storedHash;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Disable PIN lock and remove stored PIN
  Future<void> disablePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinHashKey);
      await prefs.setBool(_pinEnabledKey, false);

      _isPinEnabled = false;
      notifyListeners();

      debugPrint('PIN has been disabled');
    } catch (e) {
      debugPrint('Error disabling PIN: $e');
      rethrow;
    }
  }

  /// Change the existing PIN (requires old PIN verification first)
  Future<bool> changePin(String oldPin, String newPin) async {
    // Verify old PIN first
    final isValid = await verifyPin(oldPin);
    if (!isValid) {
      return false;
    }

    // Set new PIN
    await setPin(newPin);
    return true;
  }
}
