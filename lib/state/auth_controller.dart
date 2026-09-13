import 'package:flutter/material.dart';

import '../data/repositories/local_store.dart';

/// Manages the client-side account flow (welcome, sign up, sign in).
///
/// Assessment 4 covers the front end only, so credentials are validated and
/// persisted locally rather than exchanged with an identity provider. The API
/// of this controller is nevertheless asynchronous and failure-aware, so that a
/// real authentication service can be substituted without touching the widgets.
class AuthController extends ChangeNotifier {
  AuthController(this._store)
      : _displayName = _store.displayName,
        _email = _store.email;

  final LocalStore _store;

  String _displayName;
  String _email;
  bool _signedIn = false;
  bool _busy = false;
  String? _error;

  String get displayName => _displayName;
  String get email => _email;
  bool get signedIn => _signedIn;
  bool get busy => _busy;
  String? get error => _error;

  String get initials {
    final List<String> parts = _displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'S';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static String? validateEmail(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Enter your student email address';
    }
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(input)) {
      return 'Enter a valid email address, for example you@koi.edu.au';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final String input = value ?? '';
    if (input.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!input.contains(RegExp(r'[A-Za-z]')) ||
        !input.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if ((value ?? '').trim().length < 2) {
      return 'Enter your full name';
    }
    return null;
  }

  Future<bool> signIn({required String email, required String password}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    // Simulated network latency keeps the loading state observable during the
    // assessment demonstration.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (validateEmail(email) != null || validatePassword(password) != null) {
      _busy = false;
      _error = 'Those details do not look right. Please check and try again.';
      notifyListeners();
      return false;
    }

    _email = email.trim();
    _signedIn = true;
    _busy = false;
    notifyListeners();
    await _store.saveEmail(_email);
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    _displayName = name.trim();
    _email = email.trim();
    _signedIn = true;
    _busy = false;
    notifyListeners();
    await _store.saveDisplayName(_displayName);
    await _store.saveEmail(_email);
    return true;
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (name != null && name.trim().isNotEmpty) {
      _displayName = name.trim();
      await _store.saveDisplayName(_displayName);
    }
    if (email != null && email.trim().isNotEmpty) {
      _email = email.trim();
      await _store.saveEmail(_email);
    }
    notifyListeners();
  }

  void signOut() {
    _signedIn = false;
    notifyListeners();
  }
}
