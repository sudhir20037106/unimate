import 'dart:async';

import 'package:flutter/material.dart';

import 'planner_controller.dart';

/// The two alternating phases of the Pomodoro technique.
enum PomodoroPhase { focus, shortBreak, longBreak }

extension PomodoroPhaseX on PomodoroPhase {
  String get label {
    switch (this) {
      case PomodoroPhase.focus:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short break';
      case PomodoroPhase.longBreak:
        return 'Long break';
    }
  }

  Color get colour {
    switch (this) {
      case PomodoroPhase.focus:
        return const Color(0xFF4F46E5);
      case PomodoroPhase.shortBreak:
        return const Color(0xFF0EA5E9);
      case PomodoroPhase.longBreak:
        return const Color(0xFF10B981);
    }
  }
}

/// Drives the focus timer that sits inside the Study Planner feature.
///
/// The controller implements the full Pomodoro cycle: a configurable focus
/// interval, a short break after each interval and a long break after every
/// fourth interval. Completed focus intervals are written back into
/// [PlannerController] as study sessions, which is what allows the Progress
/// screen to chart verified effort rather than an estimate.
class PomodoroController extends ChangeNotifier {
  PomodoroController(this._planner);

  final PlannerController _planner;

  Timer? _ticker;

  int focusMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int intervalsBeforeLongBreak = 4;

  PomodoroPhase _phase = PomodoroPhase.focus;
  Duration _remaining = const Duration(minutes: 25);
  bool _running = false;
  int _completedFocusIntervals = 0;
  String _subject = 'ICT725';

  PomodoroPhase get phase => _phase;
  Duration get remaining => _remaining;
  bool get running => _running;
  int get completedFocusIntervals => _completedFocusIntervals;
  String get subject => _subject;

  Duration get _phaseDuration {
    switch (_phase) {
      case PomodoroPhase.focus:
        return Duration(minutes: focusMinutes);
      case PomodoroPhase.shortBreak:
        return Duration(minutes: shortBreakMinutes);
      case PomodoroPhase.longBreak:
        return Duration(minutes: longBreakMinutes);
    }
  }

  /// Fraction of the current phase already elapsed, in the range 0.0-1.0.
  /// Consumed by the custom-painted progress ring.
  double get progress {
    final int total = _phaseDuration.inSeconds;
    if (total == 0) {
      return 0;
    }
    return ((total - _remaining.inSeconds) / total).clamp(0.0, 1.0);
  }

  void setSubject(String value) {
    _subject = value;
    notifyListeners();
  }

  void configure({
    int? focus,
    int? shortBreak,
    int? longBreak,
    int? intervals,
  }) {
    focusMinutes = focus ?? focusMinutes;
    shortBreakMinutes = shortBreak ?? shortBreakMinutes;
    longBreakMinutes = longBreak ?? longBreakMinutes;
    intervalsBeforeLongBreak = intervals ?? intervalsBeforeLongBreak;
    if (!_running) {
      _remaining = _phaseDuration;
    }
    notifyListeners();
  }

  void start() {
    if (_running) {
      return;
    }
    _running = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  void pause() {
    _running = false;
    _ticker?.cancel();
    notifyListeners();
  }

  void toggle() => _running ? pause() : start();

  void reset() {
    _ticker?.cancel();
    _running = false;
    _remaining = _phaseDuration;
    notifyListeners();
  }

  /// Ends the current phase early and moves to the next one. A focus interval
  /// skipped in this way is not logged, because the effort did not occur.
  void skip() {
    _ticker?.cancel();
    _running = false;
    _advancePhase(logCompletedFocus: false);
  }

  void _onTick(Timer timer) {
    if (_remaining.inSeconds <= 1) {
      timer.cancel();
      _running = false;
      _advancePhase(logCompletedFocus: true);
      return;
    }
    _remaining = _remaining - const Duration(seconds: 1);
    notifyListeners();
  }

  void _advancePhase({required bool logCompletedFocus}) {
    if (_phase == PomodoroPhase.focus) {
      if (logCompletedFocus) {
        _completedFocusIntervals++;
        _planner.logFocusMinutes(_subject, focusMinutes);
      }
      final bool longBreakDue = _completedFocusIntervals > 0 &&
          _completedFocusIntervals % intervalsBeforeLongBreak == 0;
      _phase = longBreakDue ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      _phase = PomodoroPhase.focus;
    }
    _remaining = _phaseDuration;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
