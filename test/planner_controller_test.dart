import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimate/data/models/task.dart';
import 'package:unimate/data/repositories/local_store.dart';
import 'package:unimate/state/planner_controller.dart';

/// Unit tests covering the domain rules that the user interface depends upon.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlannerController planner;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final LocalStore store = await LocalStore.create();
    planner = PlannerController(store);
  });

  test('a new task is created with pending status', () {
    final int before = planner.totalTasks;
    final StudyTask task = planner.createTask(
      title: 'Draft report',
      subject: 'ICT725',
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );

    expect(planner.totalTasks, before + 1);
    expect(task.status, TaskStatus.pending);
  });

  test('cycling the status advances pending to in progress to completed', () {
    final StudyTask task = planner.createTask(
      title: 'Cycle me',
      subject: 'ICT725',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );

    planner.cycleStatus(task.id);
    expect(
      planner.allTasks.firstWhere((StudyTask t) => t.id == task.id).status,
      TaskStatus.inProgress,
    );

    planner.cycleStatus(task.id);
    expect(
      planner.allTasks.firstWhere((StudyTask t) => t.id == task.id).status,
      TaskStatus.completed,
    );
  });

  test('a deleted task can be restored to its original position', () {
    final StudyTask task = planner.createTask(
      title: 'Delete me',
      subject: 'ICT725',
      dueDate: DateTime.now().add(const Duration(days: 5)),
    );
    final int before = planner.totalTasks;

    final ({StudyTask task, int index})? removed =
        planner.deleteTask(task.id);
    expect(removed, isNotNull);
    expect(planner.totalTasks, before - 1);

    planner.restoreTask(removed!.task, removed.index);
    expect(planner.totalTasks, before);
  });

  test('search filters tasks by title, subject and notes', () {
    planner.createTask(
      title: 'Usability questionnaire',
      subject: 'ICT725',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      notes: 'Five participants',
    );

    planner.setQuery('questionnaire');
    expect(
      planner.visibleTasks.every(
        (StudyTask t) => t.title.toLowerCase().contains('questionnaire'),
      ),
      isTrue,
    );

    planner.setQuery('participants');
    expect(planner.visibleTasks.isNotEmpty, isTrue);

    planner.clearFilters();
    expect(planner.hasActiveFilters, isFalse);
  });

  test('logged focus minutes contribute to the weekly total', () {
    final int before = planner.focusMinutesThisWeek;
    planner.logFocusMinutes('ICT725', 25);
    expect(planner.focusMinutesThisWeek, before + 25);
  });

  test('an overdue task reports a negative number of days remaining', () {
    final StudyTask task = planner.createTask(
      title: 'Late submission',
      subject: 'ICT725',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
    );
    expect(task.daysRemaining, lessThan(0));
    expect(task.isOverdue, isTrue);
  });
}
