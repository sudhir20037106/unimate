import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/models/class_entry.dart';
import '../data/models/study_session.dart';
import '../data/models/task.dart';
import '../data/repositories/local_store.dart';

/// Sort strategies available on the Tasks screen.
enum TaskSort { dueDate, priority, subject, title }

extension TaskSortX on TaskSort {
  String get label {
    switch (this) {
      case TaskSort.dueDate:
        return 'Due date';
      case TaskSort.priority:
        return 'Priority';
      case TaskSort.subject:
        return 'Subject';
      case TaskSort.title:
        return 'Title';
    }
  }
}

/// The application's primary domain controller.
///
/// It owns the task, study-session and timetable collections, exposes derived
/// analytics consumed by the dashboard and the progress screen, and writes
/// every mutation through to [LocalStore]. Presentation widgets subscribe to it
/// through `provider`, which keeps rebuild scope narrow and the widget tree
/// free of business logic.
class PlannerController extends ChangeNotifier {
  PlannerController(this._store) {
    _tasks = _store.loadTasks();
    _sessions = _store.loadSessions();
    _classes = _store.loadClasses();
    if (!_store.isSeeded && _tasks.isEmpty && _classes.isEmpty) {
      _seedDemonstrationData();
    }
  }

  final LocalStore _store;
  final Uuid _uuid = const Uuid();

  List<StudyTask> _tasks = <StudyTask>[];
  List<StudySession> _sessions = <StudySession>[];
  List<ClassEntry> _classes = <ClassEntry>[];

  String _query = '';
  TaskStatus? _statusFilter;
  String? _subjectFilter;
  TaskSort _sort = TaskSort.dueDate;

  // ---------------------------------------------------------------------------
  // Raw collections
  // ---------------------------------------------------------------------------

  List<StudyTask> get allTasks => List<StudyTask>.unmodifiable(_tasks);
  List<StudySession> get sessions => List<StudySession>.unmodifiable(_sessions);
  List<ClassEntry> get classes => List<ClassEntry>.unmodifiable(_classes);

  String get query => _query;
  TaskStatus? get statusFilter => _statusFilter;
  String? get subjectFilter => _subjectFilter;
  TaskSort get sort => _sort;

  /// Every subject referenced by a task or a timetable entry, sorted for
  /// predictable presentation in filter chips and dropdowns.
  List<String> get subjects {
    final Set<String> values = <String>{
      ..._tasks.map((StudyTask t) => t.subject),
      ..._classes.map((ClassEntry c) => c.subject),
      ..._sessions.map((StudySession s) => s.subject),
    }..removeWhere((String value) => value.trim().isEmpty);
    final List<String> sorted = values.toList()..sort();
    return sorted;
  }

  // ---------------------------------------------------------------------------
  // Filtering and sorting
  // ---------------------------------------------------------------------------

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setStatusFilter(TaskStatus? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setSubjectFilter(String? value) {
    _subjectFilter = value;
    notifyListeners();
  }

  void setSort(TaskSort value) {
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = null;
    _subjectFilter = null;
    _sort = TaskSort.dueDate;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _query.isNotEmpty || _statusFilter != null || _subjectFilter != null;

  /// Tasks after the search term, status filter, subject filter and the active
  /// sort strategy have been applied.
  List<StudyTask> get visibleTasks {
    final String needle = _query.trim().toLowerCase();
    final List<StudyTask> filtered = _tasks.where((StudyTask task) {
      final bool matchesQuery = needle.isEmpty ||
          task.title.toLowerCase().contains(needle) ||
          task.subject.toLowerCase().contains(needle) ||
          task.notes.toLowerCase().contains(needle);
      final bool matchesStatus =
          _statusFilter == null || task.status == _statusFilter;
      final bool matchesSubject =
          _subjectFilter == null || task.subject == _subjectFilter;
      return matchesQuery && matchesStatus && matchesSubject;
    }).toList();

    filtered.sort((StudyTask a, StudyTask b) {
      switch (_sort) {
        case TaskSort.dueDate:
          return a.dueDate.compareTo(b.dueDate);
        case TaskSort.priority:
          final int byPriority =
              b.priority.weight.compareTo(a.priority.weight);
          return byPriority != 0
              ? byPriority
              : a.dueDate.compareTo(b.dueDate);
        case TaskSort.subject:
          final int bySubject =
              a.subject.toLowerCase().compareTo(b.subject.toLowerCase());
          return bySubject != 0 ? bySubject : a.dueDate.compareTo(b.dueDate);
        case TaskSort.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    // Completed work is always pushed to the bottom of the list so that open
    // commitments remain the focus of the screen.
    filtered.sort((StudyTask a, StudyTask b) {
      if (a.isCompleted == b.isCompleted) {
        return 0;
      }
      return a.isCompleted ? 1 : -1;
    });

    return filtered;
  }

  /// Visible tasks bucketed into deadline horizons. The dashboard and the Tasks
  /// screen both render these groups as sticky section headers.
  Map<String, List<StudyTask>> get groupedTasks {
    final Map<String, List<StudyTask>> groups = <String, List<StudyTask>>{
      'Overdue': <StudyTask>[],
      'Today': <StudyTask>[],
      'Tomorrow': <StudyTask>[],
      'This week': <StudyTask>[],
      'Later': <StudyTask>[],
      'Completed': <StudyTask>[],
    };

    for (final StudyTask task in visibleTasks) {
      if (task.isCompleted) {
        groups['Completed']!.add(task);
      } else if (task.isOverdue) {
        groups['Overdue']!.add(task);
      } else if (task.daysRemaining == 0) {
        groups['Today']!.add(task);
      } else if (task.daysRemaining == 1) {
        groups['Tomorrow']!.add(task);
      } else if (task.daysRemaining <= 7) {
        groups['This week']!.add(task);
      } else {
        groups['Later']!.add(task);
      }
    }

    groups.removeWhere(
      (String _, List<StudyTask> value) => value.isEmpty,
    );
    return groups;
  }

  // ---------------------------------------------------------------------------
  // Task mutations
  // ---------------------------------------------------------------------------

  StudyTask createTask({
    required String title,
    required String subject,
    required DateTime dueDate,
    String notes = '',
    TaskPriority priority = TaskPriority.medium,
    int estimatedMinutes = 60,
  }) {
    final StudyTask task = StudyTask(
      id: _uuid.v4(),
      title: title.trim(),
      subject: subject.trim().isEmpty ? 'General' : subject.trim(),
      dueDate: dueDate,
      notes: notes.trim(),
      priority: priority,
      estimatedMinutes: estimatedMinutes,
    );
    _tasks = <StudyTask>[..._tasks, task];
    _persistTasks();
    return task;
  }

  void updateTask(StudyTask updated) {
    _tasks = _tasks
        .map((StudyTask task) => task.id == updated.id ? updated : task)
        .toList();
    _persistTasks();
  }

  /// Advances a task through its lifecycle. Tapping the status chip therefore
  /// performs the most common action without opening the editor, which was the
  /// clarity improvement requested during Assessment 3 user testing.
  void cycleStatus(String id) {
    _tasks = _tasks.map((StudyTask task) {
      if (task.id != id) {
        return task;
      }
      final TaskStatus next = TaskStatus
          .values[(task.status.index + 1) % TaskStatus.values.length];
      return task.copyWith(status: next);
    }).toList();
    _persistTasks();
  }

  void setTaskStatus(String id, TaskStatus status) {
    _tasks = _tasks
        .map((StudyTask task) =>
            task.id == id ? task.copyWith(status: status) : task)
        .toList();
    _persistTasks();
  }

  /// Removes a task and returns it together with its original index so that the
  /// calling widget can offer a non-destructive undo action.
  ({StudyTask task, int index})? deleteTask(String id) {
    final int index = _tasks.indexWhere((StudyTask task) => task.id == id);
    if (index == -1) {
      return null;
    }
    final StudyTask removed = _tasks[index];
    _tasks = <StudyTask>[..._tasks]..removeAt(index);
    _persistTasks();
    return (task: removed, index: index);
  }

  void restoreTask(StudyTask task, int index) {
    final List<StudyTask> next = <StudyTask>[..._tasks];
    next.insert(index.clamp(0, next.length), task);
    _tasks = next;
    _persistTasks();
  }

  // ---------------------------------------------------------------------------
  // Study sessions
  // ---------------------------------------------------------------------------

  List<StudySession> get todaySessions {
    final List<StudySession> today =
        _sessions.where((StudySession s) => s.isToday).toList()
          ..sort((StudySession a, StudySession b) => a.start.compareTo(b.start));
    return today;
  }

  /// Planned sessions grouped by calendar day, ordered chronologically.
  Map<DateTime, List<StudySession>> get sessionsByDay {
    final Map<DateTime, List<StudySession>> grouped =
        <DateTime, List<StudySession>>{};
    for (final StudySession session in _sessions) {
      final DateTime key = DateTime(
        session.start.year,
        session.start.month,
        session.start.day,
      );
      grouped.putIfAbsent(key, () => <StudySession>[]).add(session);
    }
    final List<DateTime> keys = grouped.keys.toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));
    return <DateTime, List<StudySession>>{
      for (final DateTime key in keys)
        key: grouped[key]!
          ..sort((StudySession a, StudySession b) => a.start.compareTo(b.start)),
    };
  }

  StudySession addSession({
    required String subject,
    required DateTime start,
    required int durationMinutes,
    bool completed = false,
    bool fromPomodoro = false,
  }) {
    final StudySession session = StudySession(
      id: _uuid.v4(),
      subject: subject.trim().isEmpty ? 'General' : subject.trim(),
      start: start,
      durationMinutes: durationMinutes,
      completed: completed,
      fromPomodoro: fromPomodoro,
    );
    _sessions = <StudySession>[..._sessions, session];
    _persistSessions();
    return session;
  }

  void toggleSessionCompleted(String id) {
    _sessions = _sessions
        .map((StudySession s) =>
            s.id == id ? s.copyWith(completed: !s.completed) : s)
        .toList();
    _persistSessions();
  }

  void deleteSession(String id) {
    _sessions = _sessions.where((StudySession s) => s.id != id).toList();
    _persistSessions();
  }

  /// Called by the Pomodoro controller when a focus cycle finishes. The minutes
  /// are logged as a completed session so the analytics reflect real effort.
  void logFocusMinutes(String subject, int minutes) {
    addSession(
      subject: subject,
      start: DateTime.now().subtract(Duration(minutes: minutes)),
      durationMinutes: minutes,
      completed: true,
      fromPomodoro: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Timetable
  // ---------------------------------------------------------------------------

  List<ClassEntry> classesFor(int weekday) {
    final List<ClassEntry> day =
        _classes.where((ClassEntry c) => c.weekday == weekday).toList()
          ..sort((ClassEntry a, ClassEntry b) =>
              a.startMinuteOfDay.compareTo(b.startMinuteOfDay));
    return day;
  }

  /// Entries that overlap another entry on the same day.
  Set<String> get clashingClassIds {
    final Set<String> ids = <String>{};
    for (final ClassEntry a in _classes) {
      for (final ClassEntry b in _classes) {
        if (a.clashesWith(b)) {
          ids..add(a.id)..add(b.id);
        }
      }
    }
    return ids;
  }

  /// The next scheduled class from the current moment, searching forward across
  /// the week and wrapping around if necessary.
  ClassEntry? get nextClass {
    if (_classes.isEmpty) {
      return null;
    }
    final DateTime now = DateTime.now();
    final int nowMinutes = now.hour * 60 + now.minute;
    for (int offset = 0; offset < 8; offset++) {
      final int weekday = ((now.weekday - 1 + offset) % 7) + 1;
      final List<ClassEntry> day = classesFor(weekday);
      for (final ClassEntry entry in day) {
        if (offset > 0 || entry.startMinuteOfDay > nowMinutes) {
          return entry;
        }
      }
    }
    return null;
  }

  ClassEntry addClass({
    required String subject,
    required int weekday,
    required int startMinuteOfDay,
    required int durationMinutes,
    String room = '',
    String mode = 'On campus',
  }) {
    final ClassEntry entry = ClassEntry(
      id: _uuid.v4(),
      subject: subject.trim().isEmpty ? 'Class' : subject.trim(),
      weekday: weekday,
      startMinuteOfDay: startMinuteOfDay,
      durationMinutes: durationMinutes,
      room: room.trim(),
      mode: mode,
    );
    _classes = <ClassEntry>[..._classes, entry];
    _persistClasses();
    return entry;
  }

  void deleteClass(String id) {
    _classes = _classes.where((ClassEntry c) => c.id != id).toList();
    _persistClasses();
  }

  // ---------------------------------------------------------------------------
  // Derived analytics
  // ---------------------------------------------------------------------------

  int get totalTasks => _tasks.length;

  int get completedTasks =>
      _tasks.where((StudyTask t) => t.isCompleted).length;

  int get openTasks => totalTasks - completedTasks;

  int get overdueTasks => _tasks.where((StudyTask t) => t.isOverdue).length;

  double get completionRate =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  /// Tasks due within the next seven days, ordered by urgency. Used by the
  /// dashboard "Up next" panel.
  List<StudyTask> get upcoming {
    final List<StudyTask> list = _tasks
        .where((StudyTask t) => !t.isCompleted && t.daysRemaining <= 7)
        .toList()
      ..sort((StudyTask a, StudyTask b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Focus minutes recorded on each of the last seven days, oldest first.
  List<({DateTime day, int minutes})> get weeklyFocus {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return List<({DateTime day, int minutes})>.generate(7, (int index) {
      final DateTime day = today.subtract(Duration(days: 6 - index));
      final int minutes = _sessions
          .where((StudySession s) =>
              s.completed &&
              s.start.year == day.year &&
              s.start.month == day.month &&
              s.start.day == day.day)
          .fold<int>(0, (int sum, StudySession s) => sum + s.durationMinutes);
      return (day: day, minutes: minutes);
    });
  }

  int get focusMinutesThisWeek => weeklyFocus.fold<int>(
        0,
        (int sum, ({DateTime day, int minutes}) entry) => sum + entry.minutes,
      );

  int get focusMinutesToday => weeklyFocus.last.minutes;

  /// Consecutive days, counting back from today, on which focus time was logged.
  int get studyStreak {
    int streak = 0;
    final List<({DateTime day, int minutes})> week = weeklyFocus.reversed
        .toList(growable: false);
    for (final ({DateTime day, int minutes}) entry in week) {
      if (entry.minutes > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Completion progress for each subject, used by the progress donut chart.
  List<({String subject, int total, int completed})> get subjectBreakdown {
    final Map<String, List<StudyTask>> bySubject = <String, List<StudyTask>>{};
    for (final StudyTask task in _tasks) {
      bySubject.putIfAbsent(task.subject, () => <StudyTask>[]).add(task);
    }
    final List<({String subject, int total, int completed})> rows = bySubject
        .entries
        .map((MapEntry<String, List<StudyTask>> entry) => (
              subject: entry.key,
              total: entry.value.length,
              completed:
                  entry.value.where((StudyTask t) => t.isCompleted).length,
            ))
        .toList()
      ..sort((({String subject, int total, int completed}) a,
              ({String subject, int total, int completed}) b) =>
          b.total.compareTo(a.total));
    return rows;
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  void _persistTasks() {
    notifyListeners();
    _store.saveTasks(_tasks);
  }

  void _persistSessions() {
    notifyListeners();
    _store.saveSessions(_sessions);
  }

  void _persistClasses() {
    notifyListeners();
    _store.saveClasses(_classes);
  }

  /// Populates a realistic trimester on first launch so that the application can
  /// be demonstrated immediately without manual data entry.
  void _seedDemonstrationData() {
    final DateTime now = DateTime.now();
    DateTime at(int daysFromNow, int hour) => DateTime(
          now.year,
          now.month,
          now.day + daysFromNow,
          hour,
        );

    _tasks = <StudyTask>[
      StudyTask(
        id: _uuid.v4(),
        title: 'ICT725 Assessment 4 report',
        subject: 'ICT725',
        dueDate: at(2, 23),
        notes: 'Implemented functionality, screenshots, GitHub link.',
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        estimatedMinutes: 240,
      ),
      StudyTask(
        id: _uuid.v4(),
        title: 'Usability testing write-up',
        subject: 'ICT725',
        dueDate: at(-1, 17),
        notes: 'Collate the five participant responses.',
        priority: TaskPriority.medium,
        estimatedMinutes: 90,
      ),
      StudyTask(
        id: _uuid.v4(),
        title: 'Data cleaning group task',
        subject: 'Data Analytics',
        dueDate: at(0, 21),
        priority: TaskPriority.high,
        estimatedMinutes: 120,
      ),
      StudyTask(
        id: _uuid.v4(),
        title: 'Consumer behaviour quiz 6',
        subject: 'Marketing',
        dueDate: at(4, 20),
        priority: TaskPriority.low,
        estimatedMinutes: 45,
      ),
      StudyTask(
        id: _uuid.v4(),
        title: 'Project management case study',
        subject: 'ICT712',
        dueDate: at(9, 23),
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        estimatedMinutes: 180,
      ),
      StudyTask(
        id: _uuid.v4(),
        title: 'Read Yablonski chapters 3-5',
        subject: 'ICT725',
        dueDate: at(-3, 18),
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        estimatedMinutes: 60,
      ),
    ];

    _classes = <ClassEntry>[
      ClassEntry(
        id: _uuid.v4(),
        subject: 'ICT725 Lecture',
        weekday: DateTime.monday,
        startMinuteOfDay: 9 * 60,
        durationMinutes: 60,
        room: 'Level 9, 11 York St',
      ),
      ClassEntry(
        id: _uuid.v4(),
        subject: 'ICT725 Tutorial',
        weekday: DateTime.monday,
        startMinuteOfDay: 10 * 60,
        durationMinutes: 120,
        room: 'Lab 9.03',
      ),
      ClassEntry(
        id: _uuid.v4(),
        subject: 'ICT712 Workshop',
        weekday: DateTime.wednesday,
        startMinuteOfDay: 14 * 60,
        durationMinutes: 180,
        room: 'Online',
        mode: 'Online',
      ),
      ClassEntry(
        id: _uuid.v4(),
        subject: 'Data Analytics',
        weekday: DateTime.thursday,
        startMinuteOfDay: 17 * 60 + 30,
        durationMinutes: 150,
        room: 'Kent St 4.01',
      ),
      ClassEntry(
        id: _uuid.v4(),
        subject: 'Marketing Seminar',
        weekday: DateTime.friday,
        startMinuteOfDay: 11 * 60,
        durationMinutes: 90,
        room: 'Market St 2.06',
      ),
    ];

    _sessions = <StudySession>[
      for (int i = 6; i >= 0; i--)
        if (i != 3 && i != 5)
          StudySession(
            id: _uuid.v4(),
            subject: i.isEven ? 'ICT725' : 'Data Analytics',
            start: now.subtract(Duration(days: i, hours: 2)),
            durationMinutes: 25 * (1 + (i % 3)),
            completed: true,
            fromPomodoro: true,
          ),
      StudySession(
        id: _uuid.v4(),
        subject: 'ICT725',
        start: at(0, 19),
        durationMinutes: 50,
      ),
      StudySession(
        id: _uuid.v4(),
        subject: 'Marketing',
        start: at(1, 16),
        durationMinutes: 25,
      ),
    ];

    _store
      ..saveTasks(_tasks)
      ..saveSessions(_sessions)
      ..saveClasses(_classes)
      ..markSeeded();
  }
}
