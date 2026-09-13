import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatting helpers shared across the presentation layer.
///
/// Centralising these functions keeps date and duration formatting consistent
/// between screens, which is one of the heuristics (consistency and standards)
/// evaluated during the Assessment 3 usability testing.
class Formatters {
  const Formatters._();

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _fullDate = DateFormat('EEEE d MMMM');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _weekdayShort = DateFormat('EEE');

  static String dayMonth(DateTime date) => _dayMonth.format(date);

  static String fullDate(DateTime date) => _fullDate.format(date);

  static String time(DateTime date) => _time.format(date);

  static String weekdayShort(DateTime date) => _weekdayShort.format(date);

  static String timeOfDay(BuildContext context, TimeOfDay value) {
    return value.format(context);
  }

  /// Converts a duration in minutes into a compact, human readable string such
  /// as `1 h 45 m`, which is easier to scan than a raw minute count.
  static String minutes(int totalMinutes) {
    if (totalMinutes < 60) {
      return '$totalMinutes m';
    }
    final int hours = totalMinutes ~/ 60;
    final int remainder = totalMinutes % 60;
    return remainder == 0 ? '$hours h' : '$hours h $remainder m';
  }

  static String clock(Duration duration) {
    final String minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Produces a relative deadline description used on task cards and on the
  /// dashboard, e.g. `Due today`, `Overdue by 2 days`, `Due in 5 days`.
  static String relativeDue(int daysRemaining) {
    if (daysRemaining == 0) {
      return 'Due today';
    }
    if (daysRemaining == 1) {
      return 'Due tomorrow';
    }
    if (daysRemaining < 0) {
      final int overdue = daysRemaining.abs();
      return overdue == 1 ? 'Overdue by 1 day' : 'Overdue by $overdue days';
    }
    return 'Due in $daysRemaining days';
  }

  static String weekdayName(int isoWeekday) {
    const List<String> names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[(isoWeekday - 1).clamp(0, 6)];
  }
}
