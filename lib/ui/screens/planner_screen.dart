import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/study_session.dart';
import '../../state/planner_controller.dart';
import '../../state/pomodoro_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/progress_ring.dart';
import '../widgets/section_header.dart';

/// Feature two: the study planner and its embedded Pomodoro focus timer.
///
/// The timer is the analytical heart of the application. Every completed focus
/// interval is written back to [PlannerController] as a study session, so the
/// charts on the Progress screen describe effort that actually happened rather
/// than effort the student intended.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  Future<void> _addSession(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => const _PlanSessionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PlannerController planner = context.watch<PlannerController>();
    final Map<DateTime, List<StudySession>> byDay = planner.sessionsByDay;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSession(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plan session'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: <Widget>[
            Text(
              'Study planner',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Run a focus cycle, then plan the rest of your week.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            const _PomodoroPanel(),
            SectionHeader(
              title: 'Planned sessions',
              subtitle: byDay.isEmpty
                  ? null
                  : '${byDay.values.fold<int>(0, (int sum, List<StudySession> s) => sum + s.length)} scheduled',
            ),
            if (byDay.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.event_note_rounded,
                  title: 'No sessions planned',
                  message:
                      'Block out study time and UniMate will keep it beside '
                      'your deadlines.',
                  actionLabel: 'Plan a session',
                  onAction: () => _addSession(context),
                ),
              )
            else
              ...byDay.entries.map(
                (MapEntry<DateTime, List<StudySession>> entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                      child: Text(
                        Formatters.fullDate(entry.key),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ...entry.value.map(
                      (StudySession session) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SessionTile(session: session),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PomodoroPanel extends StatelessWidget {
  const _PomodoroPanel();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PomodoroController timer = context.watch<PomodoroController>();
    final SettingsController settings = context.watch<SettingsController>();
    final PlannerController planner = context.watch<PlannerController>();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        children: <Widget>[
          AnimatedContainer(
            duration: settings.animation(const Duration(milliseconds: 300)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: timer.phase.colour.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              timer.phase.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: timer.phase.colour,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ProgressRing(
            progress: timer.progress,
            colour: timer.phase.colour,
            diameter: 232,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  Formatters.clock(timer.remaining),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${timer.completedFocusIntervals} of '
                  '${timer.intervalsBeforeLongBreak} until a long break',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: 'Reset the current interval',
                onPressed: timer.reset,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 72,
                height: 72,
                child: FilledButton(
                  onPressed: timer.toggle,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    backgroundColor: timer.phase.colour,
                  ),
                  child: Icon(
                    timer.running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 34,
                    color: Colors.white,
                    semanticLabel: timer.running ? 'Pause' : 'Start',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                tooltip: 'Skip to the next interval',
                onPressed: timer.skip,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text('Focusing on', style: theme.textTheme.bodySmall),
              const Spacer(),
              DropdownButton<String>(
                value: planner.subjects.contains(timer.subject)
                    ? timer.subject
                    : (planner.subjects.isEmpty
                        ? null
                        : planner.subjects.first),
                hint: const Text('Select subject'),
                underline: const SizedBox.shrink(),
                items: planner.subjects
                    .map(
                      (String subject) => DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    timer.setSubject(value);
                  }
                },
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text('Interval length', style: theme.textTheme.bodySmall),
              const Spacer(),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 15, label: Text('15')),
                  ButtonSegment<int>(value: 25, label: Text('25')),
                  ButtonSegment<int>(value: 50, label: Text('50')),
                ],
                selected: <int>{timer.focusMinutes},
                onSelectionChanged: (Set<int> selection) =>
                    timer.configure(focus: selection.first),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Logged today: '
                    '${Formatters.minutes(planner.focusMinutesToday)} · '
                    'this week: '
                    '${Formatters.minutes(planner.focusMinutesThisWeek)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PlannerController planner = context.read<PlannerController>();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      semanticLabel: '${session.subject} study session, '
          '${Formatters.time(session.start)}, '
          '${Formatters.minutes(session.durationMinutes)}'
          '${session.completed ? ', completed' : ''}',
      child: Row(
        children: <Widget>[
          Checkbox(
            value: session.completed,
            onChanged: (bool? _) =>
                planner.toggleSessionCompleted(session.id),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        session.subject,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration: session.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (session.fromPomodoro) ...<Widget>[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.timer_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                Text(
                  '${Formatters.time(session.start)} – '
                  '${Formatters.time(session.end)} · '
                  '${Formatters.minutes(session.durationMinutes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove session',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => planner.deleteSession(session.id),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for planning a study session.
///
/// The sheet is a [StatefulWidget] so that its text controller is disposed by
/// the framework once the sheet has left the tree, rather than by the caller as
/// soon as the awaited future resolves — which happens while the sheet is still
/// animating out and its fields are still mounted.
class _PlanSessionSheet extends StatefulWidget {
  const _PlanSessionSheet();

  @override
  State<_PlanSessionSheet> createState() => _PlanSessionSheetState();
}

class _PlanSessionSheetState extends State<_PlanSessionSheet> {
  late final TextEditingController _subject;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  double _duration = 50;

  @override
  void initState() {
    super.initState();
    final List<String> subjects = context.read<PlannerController>().subjects;
    _subject = TextEditingController(
      text: subjects.isEmpty ? '' : subjects.first,
    );
  }

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  void _save() {
    context.read<PlannerController>().addSession(
          subject: _subject.text,
          start: DateTime(
            _date.year,
            _date.month,
            _date.day,
            _time.hour,
            _time.minute,
          ),
          durationMinutes: _duration.round(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Plan a study session',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _subject,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: Text(Formatters.dayMonth(_date)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(_time.format(context)),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Text('Duration'),
                const Spacer(),
                Text(Formatters.minutes(_duration.round())),
              ],
            ),
            Slider(
              value: _duration,
              min: 15,
              max: 180,
              divisions: 11,
              label: Formatters.minutes(_duration.round()),
              onChanged: (double value) => setState(() => _duration = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _save,
              child: const Text('Add session'),
            ),
          ],
        ),
      ),
    );
  }
}
