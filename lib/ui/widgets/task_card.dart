import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/task.dart';
import 'app_card.dart';

/// Presents a single task with its priority rail, subject, deadline and an
/// interactive status chip.
///
/// The status chip advances the task through its lifecycle in place, so the
/// most frequent action in the application costs one tap rather than a full
/// navigation into the editor.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleStatus,
    required this.onOpen,
    required this.onDelete,
  });

  final StudyTask task;
  final VoidCallback onToggleStatus;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool overdue = task.isOverdue;

    return Dismissible(
      key: ValueKey<String>('task-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (DismissDirection _) => onDelete(),
      child: AppCard(
        onTap: onOpen,
        padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
        semanticLabel: '${task.title}, ${task.subject}, '
            '${task.status.label}, ${task.priority.label} priority, '
            '${Formatters.relativeDue(task.daysRemaining)}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Colour-coded priority rail: a redundant, non-textual cue that
            // still resolves to a label for screen-reader users.
            Container(
              width: 5,
              height: 56,
              margin: const EdgeInsets.only(left: 10, right: 12, top: 2),
              decoration: BoxDecoration(
                color: task.priority.colour,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: task.isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _Pill(
                        icon: Icons.menu_book_rounded,
                        label: task.subject,
                      ),
                      _Pill(
                        icon: overdue
                            ? Icons.warning_amber_rounded
                            : Icons.event_rounded,
                        label:
                            '${Formatters.dayMonth(task.dueDate)} · ${Formatters.relativeDue(task.daysRemaining)}',
                        foreground:
                            overdue ? theme.colorScheme.error : null,
                      ),
                      _Pill(
                        icon: Icons.timer_outlined,
                        label: Formatters.minutes(task.estimatedMinutes),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Status ${task.status.label}. Activate to advance.',
              child: InkWell(
                onTap: onToggleStatus,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: task.status.container,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.status.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      // Bold status text was the second improvement requested by
                      // participants during Assessment 3 user testing.
                      fontWeight: FontWeight.w700,
                      color: task.status.colour,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.foreground});

  final IconData icon;
  final String label;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color colour = foreground ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: colour),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: colour),
        ),
      ],
    );
  }
}
