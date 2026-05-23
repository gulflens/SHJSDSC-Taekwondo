import 'package:flutter/material.dart';

import '../../core/services/score_engine.dart';
import '../../theme/app_theme.dart';

/// Port of the shared primitives from AthleteDesignSystem.swift — the subset
/// the Athletes slice uses. Reach for these before inventing new cards, exactly
/// as the Swift design-system rule says.

/// Mirrors `ProgressRing` / `AthleteGradeRing`: a circular composite-score gauge
/// with the letter grade in the center.
class GradeRing extends StatelessWidget {
  final double composite; // 0…100
  final LetterGrade grade;
  final double size;

  const GradeRing({
    super.key,
    required this.composite,
    required this.grade,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hue = scoreHue(composite, scheme);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (composite / 100).clamp(0, 1),
              strokeWidth: size * 0.1,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(hue),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Numbers stay LTR even under Arabic (CLAUDE.md rule).
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              grade.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: size * 0.3,
                color: hue,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors the status pill (8pt radius, severity tint).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Mirrors `SectionCard`: soft-shadow rounded surface used across the modules.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
