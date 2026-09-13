import 'package:flutter/material.dart';

/// Lifecycle states a study task can occupy.
///
/// The workflow is deliberately linear (`pending` -> `inProgress` -> `completed`)
/// so that progress analytics can be derived without ambiguity.
enum TaskStatus { pending, inProgress, completed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Color get colour {
    switch (this) {
      case TaskStatus.pending:
        return const Color(0xFF9A3412);
      case TaskStatus.inProgress:
        return const Color(0xFF1D4ED8);
      case TaskStatus.completed:
        return const Color(0xFF166534);
    }
  }

  Color get container {
    switch (this) {
      case TaskStatus.pending:
        return const Color(0xFFFFEDD5);
      case TaskStatus.inProgress:
        return const Color(0xFFDBEAFE);
      case TaskStatus.completed:
        return const Color(0xFFDCFCE7);
    }
  }
}

/// Relative importance of a task, used for sorting and for the colour-coded
/// priority rail rendered on each task card.
enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color get colour {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF0EA5E9);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.high:
        return const Color(0xFFEF4444);
    }
  }

  /// Weight used when ordering tasks; higher priorities surface first.
  int get weight => TaskPriority.values.length - index;
}

/// An immutable representation of a single assessment or study commitment.
@immutable
class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.notes = '',
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.estimatedMinutes = 60,
  });

  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final String notes;
  final TaskStatus status;
  final TaskPriority priority;
  final int estimatedMinutes;

  bool get isCompleted => status == TaskStatus.completed;

  /// A task is overdue when its due date has passed and it is still open.
  bool get isOverdue =>
      !isCompleted && dueDate.isBefore(DateTime.now()) && !isDueToday;

  bool get isDueToday {
    final DateTime now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  /// Whole days remaining until the deadline; negative values indicate overdue.
  int get daysRemaining {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  StudyTask copyWith({
    String? title,
    String? subject,
    DateTime? dueDate,
    String? notes,
    TaskStatus? status,
    TaskPriority? priority,
    int? estimatedMinutes,
  }) {
    return StudyTask(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'subject': subject,
        'dueDate': dueDate.toIso8601String(),
        'notes': notes,
        'status': status.name,
        'priority': priority.name,
        'estimatedMinutes': estimatedMinutes,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String? ?? 'General',
      dueDate: DateTime.parse(json['dueDate'] as String),
      notes: json['notes'] as String? ?? '',
      status: TaskStatus.values.firstWhere(
        (TaskStatus value) => value.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (TaskPriority value) => value.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 60,
    );
  }
}
