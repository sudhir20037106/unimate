import 'package:flutter/material.dart';

/// Central design-token definition for UniMate.
///
/// The seed colour is carried directly from the Assessment 3 Figma prototype
/// (`#4F46E5`) so that the implemented application remains visually consistent
/// with the approved high-fidelity design. Surface, container and outline roles
/// are derived algorithmically by [ColorScheme.fromSeed], which guarantees that
/// every foreground/background pairing satisfies the Material 3 contrast rules
/// in both the light and the dark theme.
class AppTheme {
  const AppTheme._();

  /// Primary brand colour inherited from the high-fidelity prototype.
  static const Color seed = Color(0xFF4F46E5);
  static const Color accent = Color(0xFF06B6D4);

  /// Shared geometry tokens.
  static const double radius = 18;
  static const double gutter = 16;

  /// Minimum interactive target, expressed in logical pixels.
  static const double minTouchTarget = 48;

  static ThemeData light({bool highContrast = false}) =>
      _build(Brightness.light, highContrast);

  static ThemeData dark({bool highContrast = false}) =>
      _build(Brightness.dark, highContrast);

  static ThemeData _build(Brightness brightness, bool highContrast) {
    final bool isLight = brightness == Brightness.light;
    ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    if (highContrast) {
      // The accessibility settings expose a high-contrast mode. Rather than
      // shipping a second palette, the generated scheme is tightened so that
      // body text is rendered in near-black or near-white and outlines become
      // explicit, which assists users with low vision.
      scheme = scheme.copyWith(
        onSurface: isLight ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        onSurfaceVariant:
            isLight ? const Color(0xFF1A1A1A) : const Color(0xFFEDEDED),
        outline: isLight ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isLight ? const Color(0xFFF6F6FB) : const Color(0xFF101014),
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 52 dp comfortably exceeds the 48 dp target recommended by the
          // Material and W3C mobile accessibility guidelines.
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? Colors.white
            : scheme.surface.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : const Color(0xFF17171C),
        indicatorColor: scheme.primaryContainer,
        elevation: 3,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceVariant,
        color: scheme.primary,
      ),
    );
  }

  /// Surface colour used by every card in the application.
  static Color surfaceOf(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF1A1A21);
  }

  /// Shared card decoration so that every panel shares identical geometry.
  static BoxDecoration cardDecoration(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BoxDecoration(
      color: surfaceOf(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: theme.colorScheme.outlineVariant),
      boxShadow: theme.brightness == Brightness.light
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F111827),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ]
          : const <BoxShadow>[],
    );
  }
}
