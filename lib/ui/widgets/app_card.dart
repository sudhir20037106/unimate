import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The single card primitive used throughout UniMate.
///
/// Routing every panel through one widget is what keeps corner radius, border,
/// elevation and padding identical on every screen, satisfying the consistency
/// expectation carried over from the high-fidelity prototype.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget content = DecoratedBox(
      decoration: AppTheme.cardDecoration(context),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (semanticLabel == null) {
      return content;
    }
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: content,
    );
  }
}
