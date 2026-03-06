import 'dart:math';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/key_storage_service.dart';
import '../services/session_service.dart';
import '../utils/constants.dart';

class AuthViewModel extends ChangeNotifier {
  final KeyStorageService _keyStorage;
  final SessionService _sessionService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _simulatedOtp;
  String? get simulatedOtp => _simulatedOtp;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _isBiometricLoginEnabled = false;
  bool get isBiometricLoginEnabled => _isBiometricLoginEnabled;

  AuthViewModel(this._keyStorage, this._sessionService) {
    _sessionService.onTimeout = logout;
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final savedValue = await _keyStorage.readValue(
      AppConstants.biometricEnabledKey,
    );
    _isBiometricLoginEnabled = savedValue == 'true';
    notifyListeners();
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    _isBiometricLoginEnabled = enabled;
    await _keyStorage.saveValue(
      AppConstants.biometricEnabledKey,
      enabled.toString(),
    );
    notifyListeners();
  }

  Future<bool> sendOtp(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    _simulatedOtp = (Random().nextInt(900000) + 100000).toString();
    debugPrint("SIMULATED OTP: $_simulatedOtp");
    return true;
  }

  bool verifyOtp(String otp) {
    return otp == _simulatedOtp;
  }

  Future<bool> login(String email, String password) async {
    await _keyStorage.saveValue('last_logged_in_user', email);
    await _keyStorage.saveValue('has_logged_in_once', 'true');
    _isLoggedIn = true;
    _sessionService.startTimer();
    notifyListeners();
    return true;
  }

  Future<void> setRememberedEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _keyStorage.deleteValue('remembered_email');
    } else {
      await _keyStorage.saveValue('remembered_email', email);
    }
  }

  Future<String?> getRememberedEmail() async {
    return await _keyStorage.readValue('remembered_email');
  }

  Future<void> clearRememberedEmail() async {
    await _keyStorage.deleteValue('remembered_email');
  }

  Future<bool> register(String email, String password) async {
    await _keyStorage.saveValue('user_email', email);
    _simulatedOtp = null;
    return true;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!_isBiometricLoginEnabled) return false;

    final hasLoggedInOnce = await _keyStorage.readValue('has_logged_in_once');
    if (hasLoggedInOnce != 'true') return false;

    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) return false;

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access CipherTask',
      );
      if (authenticated) {
        _isLoggedIn = true;
        _sessionService.startTimer();
        notifyListeners();
      }
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _sessionService.stopTimer();
    notifyListeners();
  }

  void handleUserInteraction() {
    if (_isLoggedIn) {
      _sessionService.resetTimer();
    }
  }
}
