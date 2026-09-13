import 'package:flutter/material.dart';

/// A planned or completed block of focused study.
///
/// Sessions are created either manually from the Study Planner or automatically
/// when a Pomodoro focus cycle is completed, which is what allows the Progress
/// screen to chart genuine effort rather than self-reported estimates.
@immutable
class StudySession {
  const StudySession({
    required this.id,
    required this.subject,
    required this.start,
    required this.durationMinutes,
    this.completed = false,
    this.fromPomodoro = false,
  });

  final String id;
  final String subject;
  final DateTime start;
  final int durationMinutes;
  final bool completed;
  final bool fromPomodoro;

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  bool get isToday {
    final DateTime now = DateTime.now();
    return start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
  }

  StudySession copyWith({
    String? subject,
    DateTime? start,
    int? durationMinutes,
    bool? completed,
    bool? fromPomodoro,
  }) {
    return StudySession(
      id: id,
      subject: subject ?? this.subject,
      start: start ?? this.start,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completed: completed ?? this.completed,
      fromPomodoro: fromPomodoro ?? this.fromPomodoro,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'subject': subject,
        'start': start.toIso8601String(),
        'durationMinutes': durationMinutes,
        'completed': completed,
        'fromPomodoro': fromPomodoro,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      subject: json['subject'] as String? ?? 'General',
      start: DateTime.parse(json['start'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 25,
      completed: json['completed'] as bool? ?? false,
      fromPomodoro: json['fromPomodoro'] as bool? ?? false,
    );
  }
}
