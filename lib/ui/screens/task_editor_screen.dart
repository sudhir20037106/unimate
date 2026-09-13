import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/task.dart';
import '../../state/planner_controller.dart';

/// Creates a new task or edits an existing one.
///
/// A single screen serves both cases; the presence of [task] switches the
/// title, the primary action label and the availability of deletion. Validation
/// is performed field by field so that errors are reported beside the control
/// that produced them.
class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key, this.task});

  final StudyTask? task;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subject;
  late final TextEditingController _notes;

  late DateTime _dueDate;
  late TaskPriority _priority;
  late TaskStatus _status;
  late double _estimate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final StudyTask? task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _subject = TextEditingController(text: task?.subject ?? '');
    _notes = TextEditingController(text: task?.notes ?? '');
    _dueDate = task?.dueDate ??
        DateTime.now().add(const Duration(days: 3)).copyWith(
              hour: 23,
              minute: 59,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.pending;
    _estimate = (task?.estimatedMinutes ?? 60).toDouble();
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Select the due date',
    );
    if (picked == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
      helpText: 'Select the due time',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? _dueDate.hour,
        time?.minute ?? _dueDate.minute,
      );
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final PlannerController planner = context.read<PlannerController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    if (_isEditing) {
      planner.updateTask(
        widget.task!.copyWith(
          title: _title.text,
          subject: _subject.text,
          notes: _notes.text,
          dueDate: _dueDate,
          priority: _priority,
          status: _status,
          estimatedMinutes: _estimate.round(),
        ),
      );
    } else {
      planner.createTask(
        title: _title.text,
        subject: _subject.text,
        dueDate: _dueDate,
        notes: _notes.text,
        priority: _priority,
        estimatedMinutes: _estimate.round(),
      );
    }
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Task updated' : 'Task added'),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: const Text(
          'The task will be removed from your list. This cannot be undone '
          'from here.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    context.read<PlannerController>().deleteTask(widget.task!.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> subjects = context.read<PlannerController>().subjects;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              tooltip: 'Delete task',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'e.g. ICT725 Assessment 4 report',
                ),
                validator: (String? value) =>
                    (value ?? '').trim().length < 3
                        ? 'Give the task a short, recognisable title'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subject,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. ICT725',
                  suffixIcon: subjects.isEmpty
                      ? null
                      : PopupMenuButton<String>(
                          tooltip: 'Choose an existing subject',
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          onSelected: (String value) =>
                              setState(() => _subject.text = value),
                          itemBuilder: (BuildContext context) => subjects
                              .map(
                                (String subject) => PopupMenuItem<String>(
                                  value: subject,
                                  child: Text(subject),
                                ),
                              )
                              .toList(),
                        ),
                ),
                validator: (String? value) => (value ?? '').trim().isEmpty
                    ? 'Enter the subject this task belongs to'
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: const Text('Due'),
                subtitle: Text(
                  '${Formatters.fullDate(_dueDate)} at '
                  '${Formatters.time(_dueDate)}',
                ),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ),
              const Divider(height: 24),
              Text('Priority', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: TaskPriority.values
                    .map(
                      (TaskPriority value) => ButtonSegment<TaskPriority>(
                        value: value,
                        label: Text(value.label),
                      ),
                    )
                    .toList(),
                selected: <TaskPriority>{_priority},
                onSelectionChanged: (Set<TaskPriority> selection) =>
                    setState(() => _priority = selection.first),
              ),
              if (_isEditing) ...<Widget>[
                const SizedBox(height: 20),
                Text('Status', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<TaskStatus>(
                  segments: TaskStatus.values
                      .map(
                        (TaskStatus value) => ButtonSegment<TaskStatus>(
                          value: value,
                          label: Text(value.label),
                        ),
                      )
                      .toList(),
                  selected: <TaskStatus>{_status},
                  onSelectionChanged: (Set<TaskStatus> selection) =>
                      setState(() => _status = selection.first),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Text('Estimated effort', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    Formatters.minutes(_estimate.round()),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _estimate,
                min: 15,
                max: 480,
                divisions: 31,
                label: Formatters.minutes(_estimate.round()),
                onChanged: (double value) => setState(() => _estimate = value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notes,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_isEditing ? 'Save changes' : 'Add task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
