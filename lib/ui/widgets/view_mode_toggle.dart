import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/pill_surface.dart';

enum ViewMode { list, grid }

/// Switches between the list and grid layouts of a collection. It looks like
/// the search bar's filter button: blue icons on a borderless white bar, and
/// the chosen one sits on a faint blue chip.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ViewMode mode;
  final ValueChanged<ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PillSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option(
              context,
              ViewMode.list,
              Icons.view_list_outlined,
              'List view',
            ),
            _option(
              context,
              ViewMode.grid,
              Icons.grid_view_outlined,
              'Grid view',
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context,
    ViewMode value,
    IconData icon,
    String tooltip,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = mode == value;

    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: () => onChanged(value),
      icon: Icon(icon),
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        // The chosen option takes the filter button's blue.
        backgroundColor: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      selectedIcon: Icon(icon, color: scheme.primary),
    );
  }
}
