import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'state/settings_controller.dart';
import 'ui/screens/welcome_screen.dart';

/// The root widget.
///
/// The theme, the text scale and the accessibility flags are all resolved here
/// from [SettingsController], so a preference change is reflected instantly and
/// consistently across every screen in the application.
class UniMateApp extends StatelessWidget {
  const UniMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'UniMate',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(highContrast: settings.highContrast),
      darkTheme: AppTheme.dark(highContrast: settings.highContrast),
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          // The in-app text-size preference is applied on top of the platform
          // setting, so the two compose rather than compete.
          data: media.copyWith(
            textScaler: TextScaler.linear(settings.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const WelcomeScreen(),
    );
  }
}
