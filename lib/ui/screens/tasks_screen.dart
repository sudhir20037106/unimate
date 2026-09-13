import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/task.dart';
import '../../state/planner_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';
import 'task_editor_screen.dart';

/// Feature one: complete task management.
///
/// The screen combines full create, read, update and delete behaviour with
/// search, status and subject filtering, four sort strategies, deadline
/// grouping, swipe-to-delete and an undo affordance.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openEditor(BuildContext context, [StudyTask? task]) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskEditorScreen(task: task),
      ),
    );
  }

  void _delete(BuildContext context, StudyTask task) {
    final PlannerController planner = context.read<PlannerController>();
    final ({StudyTask task, int index})? removed = planner.deleteTask(task.id);
    if (removed == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${removed.task.title}" deleted'),
          action: SnackBarAction(
            label: 'Undo',
            // Destructive actions are always reversible, so a mis-swipe never
            // costs the user data.
            onPressed: () =>
                planner.restoreTask(removed.task, removed.index),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PlannerController planner = context.watch<PlannerController>();
    final Map<String, List<StudyTask>> groups = planner.groupedTasks;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'My tasks',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  PopupMenuButton<TaskSort>(
                    tooltip: 'Sort tasks',
                    initialValue: planner.sort,
                    onSelected: planner.setSort,
                    icon: const Icon(Icons.sort_rounded),
                    itemBuilder: (BuildContext context) => TaskSort.values
                        .map(
                          (TaskSort value) => PopupMenuItem<TaskSort>(
                            value: value,
                            child: Text('Sort by ${value.label.toLowerCase()}'),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _search,
                onChanged: planner.setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search tasks, subjects or notes',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: planner.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            planner.setQuery('');
                          },
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: <Widget>[
                  FilterChip(
                    label: const Text('All'),
                    selected: planner.statusFilter == null,
                    onSelected: (bool _) => planner.setStatusFilter(null),
                  ),
                  const SizedBox(width: 8),
                  ...TaskStatus.values.map(
                    (TaskStatus status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: planner.statusFilter == status,
                        onSelected: (bool selected) =>
                            planner.setStatusFilter(selected ? status : null),
                      ),
                    ),
                  ),
                  if (planner.subjects.isNotEmpty) ...<Widget>[
                    const VerticalDivider(width: 20),
                    ...planner.subjects.map(
                      (String subject) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(subject),
                          selected: planner.subjectFilter == subject,
                          onSelected: (bool selected) => planner
                              .setSubjectFilter(selected ? subject : null),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (planner.hasActiveFilters)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: () {
                      _search.clear();
                      planner.clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Clear filters'),
                  ),
                ),
              ),
            Expanded(
              child: groups.isEmpty
                  ? EmptyState(
                      icon: planner.hasActiveFilters
                          ? Icons.search_off_rounded
                          : Icons.task_alt_rounded,
                      title: planner.hasActiveFilters
                          ? 'No matching tasks'
                          : 'No tasks yet',
                      message: planner.hasActiveFilters
                          ? 'Try a different search term or clear the active '
                              'filters.'
                          : 'Add your first assessment and UniMate will track '
                              'the deadline for you.',
                      actionLabel:
                          planner.hasActiveFilters ? null : 'Add a task',
                      onAction: planner.hasActiveFilters
                          ? null
                          : () => _openEditor(context),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      children: <Widget>[
                        for (final MapEntry<String, List<StudyTask>> group
                            in groups.entries) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  group.key,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: group.key == 'Overdue'
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${group.value.length}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...group.value.map(
                            (StudyTask task) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TaskCard(
                                task: task,
                                onToggleStatus: () =>
                                    planner.cycleStatus(task.id),
                                onOpen: () => _openEditor(context, task),
                                onDelete: () => _delete(context, task),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
