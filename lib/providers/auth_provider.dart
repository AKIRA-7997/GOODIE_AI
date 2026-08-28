import 'package:flutter/material.dart';

/// Handles (dummy) authentication state — no real backend.
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isLoading = false;
  String? _userEmail;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;

  String get displayName {
    if (_isGuest) return 'Guest User';
    if (_userEmail == null) return 'User';
    return _userEmail!.split('@').first;
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Please enter both email and password';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _isLoading = false;
    _isAuthenticated = true;
    _isGuest = false;
    _userEmail = email.trim();
    notifyListeners();
    return true;
  }

  void continueAsGuest() {
    _isAuthenticated = true;
    _isGuest = true;
    _userEmail = null;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _isGuest = false;
    _userEmail = null;
    notifyListeners();
  }
}
