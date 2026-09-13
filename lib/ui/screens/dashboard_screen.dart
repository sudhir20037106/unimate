import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/class_entry.dart';
import '../../data/models/task.dart';
import '../../state/auth_controller.dart';
import '../../state/planner_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import 'profile_screen.dart';
import 'task_editor_screen.dart';

/// The adaptive home dashboard.
///
/// It answers the three questions a student asks on opening the application:
/// what is due, what is on today, and how am I tracking. Each answer is a live
/// projection of the domain state rather than static content.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PlannerController planner = context.watch<PlannerController>();
    final AuthController auth = context.watch<AuthController>();
    final List<StudyTask> upcoming = planner.upcoming.take(4).toList();
    final ClassEntry? next = planner.nextClass;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${_greeting()}, ${auth.displayName.split(' ').first}',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // The Assessment 3 usability finding asked for an
                            // explicit instruction beneath the greeting.
                            'What would you like to do today? Select an option '
                            'below.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      button: true,
                      label: 'Open profile and settings',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            auth.initials,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  const SectionHeader(title: 'This week at a glance'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: <Widget>[
                      StatTile(
                        label: 'Open tasks',
                        value: '${planner.openTasks}',
                        icon: Icons.checklist_rounded,
                        colour: theme.colorScheme.primary,
                      ),
                      StatTile(
                        label: 'Overdue',
                        value: '${planner.overdueTasks}',
                        icon: Icons.warning_amber_rounded,
                        colour: theme.colorScheme.error,
                      ),
                      StatTile(
                        label: 'Focus this week',
                        value: Formatters.minutes(planner.focusMinutesThisWeek),
                        icon: Icons.timer_rounded,
                        colour: const Color(0xFF0EA5E9),
                      ),
                      StatTile(
                        label: 'Study streak',
                        value: '${planner.studyStreak} d',
                        icon: Icons.local_fire_department_rounded,
                        colour: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  if (next != null) ...<Widget>[
                    const SectionHeader(title: 'Next class'),
                    AppCard(
                      onTap: () => onNavigate(3),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  next.subject,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${Formatters.weekdayName(next.weekday)} · '
                                  '${next.startTime.format(context)} – '
                                  '${next.endTime.format(context)}'
                                  '${next.room.isEmpty ? '' : ' · ${next.room}'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ],
                  SectionHeader(
                    title: 'Up next',
                    subtitle: 'Deadlines in the next seven days',
                    trailing: TextButton(
                      onPressed: () => onNavigate(1),
                      child: const Text('View all'),
                    ),
                  ),
                  if (upcoming.isEmpty)
                    const AppCard(
                      child: EmptyState(
                        icon: Icons.celebration_rounded,
                        title: 'Nothing due this week',
                        message:
                            'You are on top of your deadlines. Add a task when '
                            'the next one is announced.',
                      ),
                    )
                  else
                    ...upcoming.map(
                      (StudyTask task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _UpcomingTile(
                          task: task,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TaskEditorScreen(task: task),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SectionHeader(title: 'Quick actions'),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_task_rounded,
                          label: 'Add task',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TaskEditorScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'Start focus',
                          onTap: () => onNavigate(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.insights_rounded,
                          label: 'Progress',
                          onTap: () => onNavigate(4),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.task, required this.onTap});

  final StudyTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      semanticLabel: '${task.title}, ${task.subject}, '
          '${Formatters.relativeDue(task.daysRemaining)}',
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: task.priority.colour,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${task.subject} · ${Formatters.dayMonth(task.dueDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.relativeDue(task.daysRemaining),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: task.isOverdue
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
