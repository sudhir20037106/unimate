import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import 'dashboard_screen.dart';
import 'planner_screen.dart';
import 'progress_screen.dart';
import 'schedule_screen.dart';
import 'tasks_screen.dart';

/// The persistent application shell.
///
/// On a handset the five destinations are presented in a Material 3
/// [NavigationBar]; at 720 logical pixels and above the shell switches to a
/// [NavigationRail], so the same code base adapts to a tablet or a desktop
/// window without a second layout tree.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination('Home', Icons.home_outlined, Icons.home_rounded),
    _Destination('Tasks', Icons.checklist_outlined, Icons.checklist_rounded),
    _Destination('Planner', Icons.timer_outlined, Icons.timer_rounded),
    _Destination(
      'Schedule',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
    ),
    _Destination('Progress', Icons.insights_outlined, Icons.insights_rounded),
  ];

  Widget _pageFor(int index) {
    switch (index) {
      case 1:
        return const TasksScreen();
      case 2:
        return const PlannerScreen();
      case 3:
        return const ScheduleScreen();
      case 4:
        return const ProgressScreen();
      case 0:
      default:
        return DashboardScreen(onNavigate: _select);
    }
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    final Widget body = AnimatedSwitcher(
      duration: settings.animation(const Duration(milliseconds: 260)),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_index),
        child: _pageFor(_index),
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 720;

        if (wide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map(
                        (_Destination d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: _destinations
                .map(
                  (_Destination d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
