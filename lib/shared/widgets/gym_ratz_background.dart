import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─── Configuration Enums ───

enum BackgroundIntensity { none, subtle, medium }

enum BackgroundVariant { ratsOnly, weightsOnly, mixed }

// ─── Public Widget ───

class GymRatzBackground extends StatelessWidget {
  final Widget child;
  final BackgroundIntensity intensity;
  final BackgroundVariant variant;

  const GymRatzBackground({
    super.key,
    required this.child,
    this.intensity = BackgroundIntensity.subtle,
    this.variant = BackgroundVariant.mixed,
  });

  @override
  Widget build(BuildContext context) {
    if (intensity == BackgroundIntensity.none) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? const Color(0xFF003A6B) // primary-dark
        : const Color(0xFF3776A1); // primary

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              isComplex: true,
              willChange: false,
              painter: _GymRatzTexturePainter(
                color: color,
                intensity: intensity,
                variant: variant,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ─── CustomPainter ───

class _GymRatzTexturePainter extends CustomPainter {
  final Color color;
  final BackgroundIntensity intensity;
  final BackgroundVariant variant;

  static const double _cellSize = 120.0;
  static const double _iconScale = 18.0;

  _GymRatzTexturePainter({
    required this.color,
    required this.intensity,
    required this.variant,
  });

  double get _opacity {
    switch (intensity) {
      case BackgroundIntensity.subtle:
        return 0.025;
      case BackgroundIntensity.medium:
        return 0.045;
      case BackgroundIntensity.none:
        return 0.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: _opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    final clip = canvas.getLocalClipBounds();

    final startCol = (clip.left / _cellSize).floor();
    final endCol = (clip.right / _cellSize).ceil();
    final startRow = (clip.top / _cellSize).floor();
    final endRow = (clip.bottom / _cellSize).ceil();

    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        final cx = col * _cellSize + _cellSize / 2;
        final cy = row * _cellSize + _cellSize / 2;

        // Deterministic rotation: subtle ±15°
        final seed = (row * 17 + col * 31).abs();
        final angle = ((seed % 360) - 180) * math.pi / 180.0 * 0.08;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(angle);

        final iconType = _getIconType(row, col);
        switch (iconType) {
          case _IconType.rat:
            _drawRatHead(canvas, paint, strokePaint);
            break;
          case _IconType.dumbbell:
            _drawDumbbell(canvas, paint);
            break;
          case _IconType.barbell:
            _drawBarbell(canvas, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  _IconType _getIconType(int row, int col) {
    switch (variant) {
      case BackgroundVariant.ratsOnly:
        return _IconType.rat;
      case BackgroundVariant.weightsOnly:
        final idx = (row + col) % 2;
        return idx == 0 ? _IconType.dumbbell : _IconType.barbell;
      case BackgroundVariant.mixed:
        final idx = (row * 3 + col) % 3;
        switch (idx) {
          case 0:
            return _IconType.rat;
          case 1:
            return _IconType.dumbbell;
          default:
            return _IconType.barbell;
        }
    }
  }

  /// Angry rat head — minimal geometric silhouette
  /// Oval head, pointed ears angled outward, angry narrow eye slits, small snout
  void _drawRatHead(Canvas canvas, Paint fill, Paint stroke) {
    final s = _iconScale;

    // Head — slightly squashed oval
    final headRect = Rect.fromCenter(
      center: Offset(0, s * 0.05),
      width: s * 1.6,
      height: s * 1.4,
    );
    canvas.drawOval(headRect, fill);

    // Left ear — pointed triangle angled outward
    final leftEar = Path()
      ..moveTo(-s * 0.55, -s * 0.45)
      ..lineTo(-s * 0.95, -s * 1.05)
      ..lineTo(-s * 0.2, -s * 0.6)
      ..close();
    canvas.drawPath(leftEar, fill);

    // Right ear — mirrored
    final rightEar = Path()
      ..moveTo(s * 0.55, -s * 0.45)
      ..lineTo(s * 0.95, -s * 1.05)
      ..lineTo(s * 0.2, -s * 0.6)
      ..close();
    canvas.drawPath(rightEar, fill);

    // Angry eyes — narrow angled slits (drawn as strokes for sharpness)
    // Left eye: angled down toward center
    final leftEye = Path()
      ..moveTo(-s * 0.42, -s * 0.12)
      ..lineTo(-s * 0.12, -s * 0.02);
    canvas.drawPath(leftEye, stroke);

    // Right eye: mirrored
    final rightEye = Path()
      ..moveTo(s * 0.42, -s * 0.12)
      ..lineTo(s * 0.12, -s * 0.02);
    canvas.drawPath(rightEye, stroke);

    // Snout — small downward triangle
    final snout = Path()
      ..moveTo(-s * 0.12, s * 0.3)
      ..lineTo(0, s * 0.52)
      ..lineTo(s * 0.12, s * 0.3)
      ..close();
    canvas.drawPath(snout, fill);
  }

  /// Dumbbell — center bar + stacked plates on each end
  void _drawDumbbell(Canvas canvas, Paint fill) {
    final s = _iconScale;

    // Center bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 1.8, height: s * 0.2),
        Radius.circular(s * 0.1),
      ),
      fill,
    );

    // Left plates (outer wider, inner narrower)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.78, 0),
          width: s * 0.22,
          height: s * 0.9,
        ),
        Radius.circular(s * 0.04),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.96, 0),
          width: s * 0.18,
          height: s * 1.1,
        ),
        Radius.circular(s * 0.04),
      ),
      fill,
    );

    // Right plates (mirrored)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.78, 0),
          width: s * 0.22,
          height: s * 0.9,
        ),
        Radius.circular(s * 0.04),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.96, 0),
          width: s * 0.18,
          height: s * 1.1,
        ),
        Radius.circular(s * 0.04),
      ),
      fill,
    );
  }

  /// Barbell — longer bar with larger plates and collar circles
  void _drawBarbell(Canvas canvas, Paint fill) {
    final s = _iconScale;

    // Long bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 2.2, height: s * 0.14),
        Radius.circular(s * 0.07),
      ),
      fill,
    );

    // Left plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.85, 0),
          width: s * 0.16,
          height: s * 1.2,
        ),
        Radius.circular(s * 0.03),
      ),
      fill,
    );

    // Left collar
    canvas.drawCircle(Offset(-s * 0.72, 0), s * 0.08, fill);

    // Right plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.85, 0),
          width: s * 0.16,
          height: s * 1.2,
        ),
        Radius.circular(s * 0.03),
      ),
      fill,
    );

    // Right collar
    canvas.drawCircle(Offset(s * 0.72, 0), s * 0.08, fill);
  }

  @override
  bool shouldRepaint(_GymRatzTexturePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.intensity != intensity ||
        oldDelegate.variant != variant;
  }
}

enum _IconType { rat, dumbbell, barbell }
