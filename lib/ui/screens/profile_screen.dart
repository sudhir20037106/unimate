import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../state/auth_controller.dart';
import '../../state/planner_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import 'welcome_screen.dart';

/// Profile, appearance, accessibility and privacy settings.
///
/// The accessibility group is deliberately exposed in the application itself
/// rather than deferred to the operating system, so that a student can enlarge
/// text, raise contrast or suppress animation without leaving UniMate.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthController auth = context.watch<AuthController>();
    final SettingsController settings = context.watch<SettingsController>();
    final PlannerController planner = context.watch<PlannerController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile and settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: <Widget>[
            AppCard(
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      auth.initials,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          auth.displayName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          auth.email.isEmpty
                              ? 'No email on file'
                              : auth.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit profile',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editProfile(context, auth),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Your activity'),
            AppCard(
              child: Column(
                children: <Widget>[
                  _StatRow(
                    label: 'Tasks tracked',
                    value: '${planner.totalTasks}',
                  ),
                  const Divider(height: 20),
                  _StatRow(
                    label: 'Focus time this week',
                    value: Formatters.minutes(planner.focusMinutesThisWeek),
                  ),
                  const Divider(height: 20),
                  _StatRow(
                    label: 'Classes in timetable',
                    value: '${planner.classes.length}',
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Appearance'),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Theme', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Auto'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: <ThemeMode>{settings.themeMode},
                    onSelectionChanged: (Set<ThemeMode> selection) =>
                        settings.setThemeMode(selection.first),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Accessibility'),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text('Text size', style: theme.textTheme.labelLarge),
                      const Spacer(),
                      Text(
                        '${(settings.textScale * 100).round()}%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.textScale,
                    min: 0.9,
                    max: 1.6,
                    divisions: 7,
                    label: '${(settings.textScale * 100).round()}%',
                    onChanged: settings.setTextScale,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.highContrast,
                    onChanged: settings.setHighContrast,
                    title: const Text('High contrast'),
                    subtitle: const Text(
                      'Strengthens text and outline colours.',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.reduceMotion,
                    onChanged: settings.setReduceMotion,
                    title: const Text('Reduce motion'),
                    subtitle: const Text(
                      'Removes screen transitions and animated meters.',
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Privacy and security'),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All tasks, sessions and timetable entries are stored '
                      'only on this device. Nothing is uploaded, shared or '
                      'used for analytics.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthController>().signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const WelcomeScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'UniMate 1.0.0 · ICT725 Assessment 4',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, AuthController auth) async {
    final TextEditingController name =
        TextEditingController(text: auth.displayName);
    final TextEditingController email =
        TextEditingController(text: auth.email);

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              auth.updateProfile(name: name.text, email: email.text);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
