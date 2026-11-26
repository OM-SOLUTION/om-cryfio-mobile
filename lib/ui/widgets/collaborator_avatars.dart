import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/theme/file_type_colors.dart';

/// The people with access to a file, as small overlapping circles with their
/// initials. More than [max] people end with a "+N" circle. Draws nothing when
/// there is nobody.
class CollaboratorAvatars extends StatelessWidget {
  const CollaboratorAvatars({
    super.key,
    required this.collaborators,
    this.size = 24,
    this.max = 3,
    this.ringColor,
    this.semanticLabel,
  });

  final List<Collaborator> collaborators;

  /// What screen readers say. Left out, [describe] of the [collaborators].
  final String? semanticLabel;

  /// Diameter of one circle.
  final double size;

  /// The most circles to draw, the "+N" one included.
  final int max;

  /// The thin outline that separates overlapping circles. It should be the color
  /// behind them. Left out, the page color.
  final Color? ringColor;

  static const _ring = 2.0;

  /// The width [count] circles take up.
  static double widthFor(int count, double size, {int max = 3}) {
    final shown = count < max ? count : max;
    return shown == 0 ? 0 : size + (shown - 1) * size * _overlapStep;
  }

  // Each circle starts this fraction of a diameter after the one before it.
  static const _overlapStep = 0.65;

  /// "Shared with Ann, Bob" for screen readers, or null when nobody has access.
  static String? describe(List<Collaborator> collaborators) =>
      collaborators.isEmpty
      ? null
      : 'Shared with ${collaborators.map((c) => c.name).join(', ')}';

  @override
  Widget build(BuildContext context) {
    if (collaborators.isEmpty) return const SizedBox.shrink();

    final ring = ringColor ?? Theme.of(context).colorScheme.surface;
    final overflow = collaborators.length > max;
    final named = overflow ? max - 1 : collaborators.length;
    final circles = [
      for (final person in collaborators.take(named))
        _Circle(
          size: size,
          ring: ring,
          text: person.initials,
          // The same name always gets the same color.
          color: HSLColor.fromAHSL(
            1,
            FileTypeColors.hueForExtension(person.name),
            0.55,
            0.36,
          ).toColor(),
        ),
      if (overflow)
        _Circle(
          size: size,
          ring: ring,
          text: '+${collaborators.length - named}',
          color: Theme.of(context).colorScheme.secondary,
        ),
    ];

    return Semantics(
      label: semanticLabel ?? describe(collaborators),
      excludeSemantics: true,
      child: SizedBox(
        width: widthFor(collaborators.length, size, max: max),
        height: size,
        child: Stack(
          children: [
            for (final (index, circle) in circles.indexed)
              Positioned(left: index * size * _overlapStep, child: circle),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({
    required this.size,
    required this.ring,
    required this.text,
    required this.color,
  });

  final double size;
  final Color ring;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: ring, width: CollaboratorAvatars._ring),
      ),
      child: Text(
        text,
        // Fixed size: the circle does not grow with the text size.
        textScaler: TextScaler.noScaling,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
