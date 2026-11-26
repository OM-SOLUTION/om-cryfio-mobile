import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/pill_surface.dart';

/// A search bar: a magnifier, the text, and at the end a divider with a filter
/// button. It has no border; [onFilter] is the filter button's action.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hint = 'Search anything...',
    this.controller,
    this.onChanged,
    this.onFilter,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// Shown as a filter button when given.
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    // The bar has a fixed height, so its text stops growing at 1.3x.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: PillSurface(
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            Icon(Icons.search, size: 28, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: textStyle,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: textStyle?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  // No border, fill or padding of its own: the bar is the box.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            if (onFilter != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(width: 2, height: 24, color: scheme.primary),
              IconButton(
                tooltip: 'Filter',
                onPressed: onFilter,
                color: scheme.primary,
                icon: const Icon(Icons.tune),
              ),
              const SizedBox(width: AppSpacing.xs),
            ] else
              const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
