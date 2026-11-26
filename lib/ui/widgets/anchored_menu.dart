import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/theme/app_theme.dart';

/// One row of an [AnchoredMenu].
class MenuItemData<T> {
  const MenuItemData({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
    this.dividerBefore = false,
    this.selected = false,
  });

  /// What the menu returns when this row is chosen.
  final T value;
  final String label;
  final IconData icon;

  /// Draws the row in the error color, for actions that delete something.
  final bool destructive;

  /// Draws a line above the row, to set it apart from the ones before it.
  final bool dividerBefore;

  /// Marks the row with a check, for the current choice in a list of options.
  final bool selected;
}

/// Opens a menu next to [anchor], a rectangle in screen coordinates: a ⋮
/// button's bounds, or a zero-size rectangle at the point where a tile was
/// held. Resolves to the chosen row's value, or null if it was dismissed.
///
/// The menu is always full size. It fades in and grows slightly from the corner
/// nearest the anchor, in about 120 ms. It opens below the anchor when that is
/// the upper half of the screen and above it otherwise, and on the side with
/// more room.
Future<T?> showAnchoredMenu<T>(
  BuildContext context, {
  required Rect anchor,
  required List<MenuItemData<T>> items,
}) {
  final screen = MediaQuery.sizeOf(context);
  final fromRight = anchor.center.dx > screen.width / 2;
  final fromBottom = anchor.center.dy > screen.height / 2;
  final origin = Alignment(fromRight ? 1 : -1, fromBottom ? 1 : -1);
  final instant = MediaQuery.disableAnimationsOf(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: instant
        ? Duration.zero
        : const Duration(milliseconds: 120),
    // The animation is on the menu itself, below, because the page fills the
    // screen and would otherwise scale from the wrong place.
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
    pageBuilder: (context, animation, secondaryAnimation) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      );

      return CustomSingleChildLayout(
        delegate: _MenuLayout(anchor),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            alignment: origin,
            child: AnchoredMenu<T>(items: items),
          ),
        ),
      );
    },
  );
}

/// The menu panel. Use [showAnchoredMenu] to open one.
class AnchoredMenu<T> extends StatelessWidget {
  const AnchoredMenu({super.key, required this.items});

  final List<MenuItemData<T>> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Actions',
      child: Material(
        color: scheme.surfaceContainer,
        elevation: 3,
        shadowColor: scheme.shadow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 192, maxWidth: 280),
          child: IntrinsicWidth(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items) ...[
                    if (item.dividerBefore)
                      const Divider(height: AppSpacing.md + 1),
                    _MenuRow<T>(item: item),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({required this.item});

  final MenuItemData<T> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: item.selected,
      child: InkWell(
        onTap: () => Navigator.pop(context, item.value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(item.icon, color: color)),
                const SizedBox(width: AppSpacing.md - 4),
                Flexible(
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodyLarge?.copyWith(color: color),
                  ),
                ),
                if (item.selected) ...[
                  const SizedBox(width: AppSpacing.md),
                  ExcludeSemantics(child: Icon(Icons.check, color: color)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts the menu's corner at the anchor, on the side with more room, and keeps
/// it on screen.
class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout(this.anchor);

  final Rect anchor;

  static const _margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(
      Size(
        constraints.maxWidth - 2 * _margin,
        constraints.maxHeight - 2 * _margin,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final fromRight = anchor.center.dx > size.width / 2;
    final fromBottom = anchor.center.dy > size.height / 2;

    final x = fromRight ? anchor.right - childSize.width : anchor.left;
    final y = fromBottom ? anchor.top - childSize.height : anchor.bottom;

    return Offset(
      x.clamp(_margin, size.width - childSize.width - _margin).toDouble(),
      y.clamp(_margin, size.height - childSize.height - _margin).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) => oldDelegate.anchor != anchor;
}
