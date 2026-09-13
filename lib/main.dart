import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/local_store.dart';
import 'state/auth_controller.dart';
import 'state/planner_controller.dart';
import 'state/pomodoro_controller.dart';
import 'state/settings_controller.dart';

/// Application entry point.
///
/// Persistence is initialised before the first frame so that the user's saved
/// tasks, sessions, timetable and preferences are available synchronously to
/// every controller, which removes the need for loading states inside the UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final LocalStore store = await LocalStore.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(store),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(store),
        ),
        ChangeNotifierProvider<PlannerController>(
          create: (_) => PlannerController(store),
        ),
        ChangeNotifierProxyProvider<PlannerController, PomodoroController>(
          create: (BuildContext context) => PomodoroController(
            context.read<PlannerController>(),
          ),
          update: (
            BuildContext context,
            PlannerController planner,
            PomodoroController? previous,
          ) =>
              previous ?? PomodoroController(planner),
        ),
      ],
      child: const UniMateApp(),
    ),
  );
}
