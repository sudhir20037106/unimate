import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/class_entry.dart';
import '../../state/planner_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';

/// Feature three: the weekly class timetable.
///
/// Beyond listing classes, the screen detects overlapping entries and warns the
/// student inline, which converts a silent data-entry error into visible,
/// recoverable feedback.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int _selectedWeekday = DateTime.now().weekday;

  Future<void> _addClass() async {
    final PlannerController planner = context.read<PlannerController>();
    final TextEditingController subject = TextEditingController();
    final TextEditingController room = TextEditingController();
    int weekday = _selectedWeekday;
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    double duration = 60;
    String mode = 'On campus';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
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
                      'Add a class',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: subject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: room,
                      decoration: const InputDecoration(
                        labelText: 'Room or link',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      value: weekday,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: List<DropdownMenuItem<int>>.generate(
                        7,
                        (int index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(Formatters.weekdayName(index + 1)),
                        ),
                      ),
                      onChanged: (int? value) =>
                          setSheetState(() => weekday = value ?? weekday),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.schedule_rounded, size: 18),
                            label: Text(start.format(context)),
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: start,
                              );
                              if (picked != null) {
                                setSheetState(() => start = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: mode,
                            decoration:
                                const InputDecoration(labelText: 'Mode'),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem<String>(
                                value: 'On campus',
                                child: Text('On campus'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'Online',
                                child: Text('Online'),
                              ),
                            ],
                            onChanged: (String? value) =>
                                setSheetState(() => mode = value ?? mode),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Text('Duration'),
                        const Spacer(),
                        Text(Formatters.minutes(duration.round())),
                      ],
                    ),
                    Slider(
                      value: duration,
                      min: 30,
                      max: 240,
                      divisions: 14,
                      label: Formatters.minutes(duration.round()),
                      onChanged: (double value) =>
                          setSheetState(() => duration = value),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        planner.addClass(
                          subject: subject.text,
                          weekday: weekday,
                          startMinuteOfDay: start.hour * 60 + start.minute,
                          durationMinutes: duration.round(),
                          room: room.text,
                          mode: mode,
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Add class'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    subject.dispose();
    room.dispose();
    if (mounted) {
      setState(() => _selectedWeekday = weekday);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PlannerController planner = context.watch<PlannerController>();
    final List<ClassEntry> day = planner.classesFor(_selectedWeekday);
    final Set<String> clashes = planner.clashingClassIds;
    final int todayWeekday = DateTime.now().weekday;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClass,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add class'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Class schedule',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 7,
                separatorBuilder: (BuildContext _, int __) =>
                    const SizedBox(width: 10),
                itemBuilder: (BuildContext context, int index) {
                  final int weekday = index + 1;
                  final bool selected = weekday == _selectedWeekday;
                  final int count = planner.classesFor(weekday).length;
                  return Semantics(
                    selected: selected,
                    button: true,
                    label:
                        '${Formatters.weekdayName(weekday)}, $count classes',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          setState(() => _selectedWeekday = weekday),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 62,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant
                                  .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: weekday == todayWeekday && !selected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              Formatters.weekdayName(weekday).substring(0, 3),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 22,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? theme.colorScheme.onPrimary
                                        .withOpacity(0.22)
                                    : theme.colorScheme.primary
                                        .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: day.isEmpty
                  ? EmptyState(
                      icon: Icons.free_breakfast_rounded,
                      title:
                          'No classes on ${Formatters.weekdayName(_selectedWeekday)}',
                      message:
                          'Use this day for focused study, or add a class to '
                          'your timetable.',
                      actionLabel: 'Add class',
                      onAction: _addClass,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                      itemCount: day.length,
                      separatorBuilder: (BuildContext _, int __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final ClassEntry entry = day[index];
                        final bool clashing = clashes.contains(entry.id);
                        return AppCard(
                          semanticLabel: '${entry.subject}, '
                              '${entry.startTime.format(context)} to '
                              '${entry.endTime.format(context)}'
                              '${clashing ? ', timetable clash' : ''}',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    entry.startTime.format(context),
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    entry.endTime.format(context),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 3,
                                height: 46,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: clashing
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      entry.subject,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${entry.mode}'
                                      '${entry.room.isEmpty ? '' : ' · ${entry.room}'}'
                                      ' · ${Formatters.minutes(entry.durationMinutes)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (clashing) ...<Widget>[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.error_outline_rounded,
                                            size: 16,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'This class overlaps another '
                                              'entry on the same day.',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove class',
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    planner.deleteClass(entry.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
