import 'package:flutter/material.dart';

import 'package:om_cryfio/features/sharing/domain/sharing.dart';

/// A small pill that says which role someone holds: Owner, Editor or Viewer.
class RoleChip extends StatelessWidget {
  const RoleChip(this.role, {super.key});

  final ShareRole role;

  static IconData iconFor(ShareRole role) => switch (role) {
    ShareRole.owner => Icons.workspace_premium_outlined,
    ShareRole.editor => Icons.edit_outlined,
    ShareRole.viewer => Icons.visibility_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: scheme.onSecondaryContainer);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.secondaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconFor(role), size: 14, color: scheme.onSecondaryContainer),
            const SizedBox(width: 4),
            // Cut off rather than overflow in a very narrow space.
            Flexible(
              child: Text(
                role.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
