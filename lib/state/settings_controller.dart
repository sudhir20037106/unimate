import 'package:flutter/material.dart';

import '../data/repositories/local_store.dart';

/// Holds user-configurable presentation preferences.
///
/// Every preference is written through to [LocalStore] immediately, so the
/// chosen theme, text size and motion settings survive an application restart.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store)
      : _themeMode = _parseThemeMode(_store.themeMode),
        _textScale = _store.textScale,
        _highContrast = _store.highContrast,
        _reduceMotion = _store.reduceMotion;

  final LocalStore _store;

  ThemeMode _themeMode;
  double _textScale;
  bool _highContrast;
  bool _reduceMotion;

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;

  static ThemeMode _parseThemeMode(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _store.saveThemeMode(mode.name);
  }

  /// Text scale is clamped to the 0.9-1.6 range. Values beyond that break the
  /// fixed-height chrome, so the application constrains rather than ignores the
  /// preference, preserving layout integrity while still honouring the request.
  Future<void> setTextScale(double value) async {
    final double clamped = value.clamp(0.9, 1.6).toDouble();
    if (_textScale == clamped) {
      return;
    }
    _textScale = clamped;
    notifyListeners();
    await _store.saveTextScale(clamped);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await _store.saveHighContrast(value);
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();
    await _store.saveReduceMotion(value);
  }

  /// Animation duration helper honoured by every custom transition, so that a
  /// user who has requested reduced motion receives an instant state change.
  Duration animation(Duration preferred) =>
      _reduceMotion ? Duration.zero : preferred;
}
