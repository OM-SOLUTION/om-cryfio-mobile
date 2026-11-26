import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/theme/app_theme.dart';

/// The rounded white bar the search field and the view toggle sit on: no
/// border, a very soft shadow so it still shows on a near-white background.
class PillSurface extends StatelessWidget {
  const PillSurface({super.key, required this.child});

  /// The bar's height. The text inside is kept to a size that fits it.
  static const height = 52.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: SizedBox(height: height, child: child),
    );
  }
}
