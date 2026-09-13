import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/class_entry.dart';
import '../models/study_session.dart';
import '../models/task.dart';

/// A thin persistence layer over [SharedPreferences].
///
/// The repository pattern is used so that the presentation layer never talks to
/// a storage API directly. Should the application later migrate to SQLite or a
/// remote backend, only this class changes.
class LocalStore {
  LocalStore(this._prefs);

  static const String _tasksKey = 'unimate.tasks.v1';
  static const String _sessionsKey = 'unimate.sessions.v1';
  static const String _classesKey = 'unimate.classes.v1';
  static const String _themeKey = 'unimate.theme.v1';
  static const String _textScaleKey = 'unimate.textScale.v1';
  static const String _highContrastKey = 'unimate.highContrast.v1';
  static const String _reduceMotionKey = 'unimate.reduceMotion.v1';
  static const String _nameKey = 'unimate.displayName.v1';
  static const String _emailKey = 'unimate.email.v1';
  static const String _seededKey = 'unimate.seeded.v1';

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  bool get isSeeded => _prefs.getBool(_seededKey) ?? false;

  Future<void> markSeeded() => _prefs.setBool(_seededKey, true);

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final String? raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((dynamic item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      // Corrupted payloads are discarded rather than crashing the application.
      return <T>[];
    }
  }

  Future<void> _writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return _prefs.setString(
      key,
      jsonEncode(items.map(toJson).toList()),
    );
  }

  List<StudyTask> loadTasks() => _readList(_tasksKey, StudyTask.fromJson);

  Future<void> saveTasks(List<StudyTask> tasks) =>
      _writeList(_tasksKey, tasks, (StudyTask t) => t.toJson());

  List<StudySession> loadSessions() =>
      _readList(_sessionsKey, StudySession.fromJson);

  Future<void> saveSessions(List<StudySession> sessions) =>
      _writeList(_sessionsKey, sessions, (StudySession s) => s.toJson());

  List<ClassEntry> loadClasses() => _readList(_classesKey, ClassEntry.fromJson);

  Future<void> saveClasses(List<ClassEntry> classes) =>
      _writeList(_classesKey, classes, (ClassEntry c) => c.toJson());

  String get themeMode => _prefs.getString(_themeKey) ?? 'system';

  Future<void> saveThemeMode(String value) => _prefs.setString(_themeKey, value);

  double get textScale => _prefs.getDouble(_textScaleKey) ?? 1.0;

  Future<void> saveTextScale(double value) =>
      _prefs.setDouble(_textScaleKey, value);

  bool get highContrast => _prefs.getBool(_highContrastKey) ?? false;

  Future<void> saveHighContrast(bool value) =>
      _prefs.setBool(_highContrastKey, value);

  bool get reduceMotion => _prefs.getBool(_reduceMotionKey) ?? false;

  Future<void> saveReduceMotion(bool value) =>
      _prefs.setBool(_reduceMotionKey, value);

  String get displayName => _prefs.getString(_nameKey) ?? 'Student';

  Future<void> saveDisplayName(String value) =>
      _prefs.setString(_nameKey, value);

  String get email => _prefs.getString(_emailKey) ?? '';

  Future<void> saveEmail(String value) => _prefs.setString(_emailKey, value);
}
