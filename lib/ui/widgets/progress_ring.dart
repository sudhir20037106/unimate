import 'package:flutter/material.dart';

/// A custom-painted circular progress indicator used by the Pomodoro timer.
///
/// [CustomPainter] is used in preference to a stock [CircularProgressIndicator]
/// because the design calls for a thick, rounded, gradient-free arc drawn over a
/// visible track, with the sweep starting at twelve o'clock.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.colour,
    required this.child,
    this.diameter = 240,
    this.strokeWidth = 14,
  });

  final double progress;
  final Color colour;
  final Widget child;
  final double diameter;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          colour: colour,
          track: theme.colorScheme.surfaceContainerHighest,
          strokeWidth: strokeWidth,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.colour,
    required this.track,
    required this.strokeWidth,
  });

  final double progress;
  final Color colour;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide - strokeWidth) / 2;

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(centre, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -1.5707963267948966, // Start the sweep at the top of the circle.
        6.283185307179586 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.colour != colour ||
        oldDelegate.track != track ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
