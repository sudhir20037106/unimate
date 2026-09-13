import 'package:flutter/material.dart';

/// A recurring weekly timetable entry.
@immutable
class ClassEntry {
  const ClassEntry({
    required this.id,
    required this.subject,
    required this.weekday,
    required this.startMinuteOfDay,
    required this.durationMinutes,
    this.room = '',
    this.mode = 'On campus',
  });

  final String id;
  final String subject;

  /// ISO-8601 weekday, where Monday is 1 and Sunday is 7.
  final int weekday;
  final int startMinuteOfDay;
  final int durationMinutes;
  final String room;
  final String mode;

  int get endMinuteOfDay => startMinuteOfDay + durationMinutes;

  TimeOfDay get startTime => TimeOfDay(
        hour: startMinuteOfDay ~/ 60,
        minute: startMinuteOfDay % 60,
      );

  TimeOfDay get endTime => TimeOfDay(
        hour: (endMinuteOfDay ~/ 60) % 24,
        minute: endMinuteOfDay % 60,
      );

  /// Two entries clash when they fall on the same weekday and their intervals
  /// overlap. The Class Schedule screen surfaces clashes as an inline warning.
  bool clashesWith(ClassEntry other) {
    if (other.id == id || other.weekday != weekday) {
      return false;
    }
    return startMinuteOfDay < other.endMinuteOfDay &&
        other.startMinuteOfDay < endMinuteOfDay;
  }

  ClassEntry copyWith({
    String? subject,
    int? weekday,
    int? startMinuteOfDay,
    int? durationMinutes,
    String? room,
    String? mode,
  }) {
    return ClassEntry(
      id: id,
      subject: subject ?? this.subject,
      weekday: weekday ?? this.weekday,
      startMinuteOfDay: startMinuteOfDay ?? this.startMinuteOfDay,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      room: room ?? this.room,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'subject': subject,
        'weekday': weekday,
        'startMinuteOfDay': startMinuteOfDay,
        'durationMinutes': durationMinutes,
        'room': room,
        'mode': mode,
      };

  factory ClassEntry.fromJson(Map<String, dynamic> json) {
    return ClassEntry(
      id: json['id'] as String,
      subject: json['subject'] as String? ?? 'Class',
      weekday: json['weekday'] as int? ?? 1,
      startMinuteOfDay: json['startMinuteOfDay'] as int? ?? 9 * 60,
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      room: json['room'] as String? ?? '',
      mode: json['mode'] as String? ?? 'On campus',
    );
  }
}
