import 'package:flutter/material.dart';

import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/features/sharing/presentation/role_chip.dart';
import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/anchored_menu.dart';
import 'package:om_cryfio/ui/widgets/coming_soon.dart';
import 'package:om_cryfio/ui/widgets/collaborator_avatars.dart';
import 'package:om_cryfio/ui/widgets/file_type_icon.dart';

/// Opens the sheet where the Owner manages who can reach [entry]: the people
/// with access and their roles, invitations not answered yet, inviting more
/// people and transferring ownership. Changing a role, removing someone and
/// cancelling an invitation work on the sample data and are reported to
/// [onChanged] with the updated entry. Inviting and transferring do not work
/// yet.
Future<void> showManageAccess(
  BuildContext context,
  SharedByMe entry, {
  ValueChanged<SharedByMe>? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The sheet draws its own surface and handle, so it can be dragged.
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ManageAccessSheet(
      entry: entry,
      now: DateTime.now(),
      onChanged: onChanged,
    ),
  );
}

/// What the role button's menu can do: give one of the two roles, or take the
/// person's access away.
enum _RoleChoice { editor, viewer, remove }

class ManageAccessSheet extends StatefulWidget {
  const ManageAccessSheet({
    super.key,
    required this.entry,
    required this.now,
    this.onChanged,
  });

  final SharedByMe entry;

  /// What "today" is, to work out when invitations end.
  final DateTime now;

  /// Called with the updated entry after every change.
  final ValueChanged<SharedByMe>? onChanged;

  @override
  State<ManageAccessSheet> createState() => _ManageAccessSheetState();
}

class _ManageAccessSheetState extends State<ManageAccessSheet> {
  late SharedByMe _entry = widget.entry;

  void _update(SharedByMe next) {
    setState(() => _entry = next);
    widget.onChanged?.call(next);
  }

  void _setRole(SharedPerson shared, ShareRole role) {
    _update(
      _entry.copyWith(
        people: [
          for (final p in _entry.people)
            if (p == shared) p.copyWith(role: role) else p,
        ],
      ),
    );
  }

  void _revoke(SharedPerson shared) {
    _update(
      _entry.copyWith(
        people: [
          for (final p in _entry.people)
            if (p != shared) p,
        ],
      ),
    );
  }

  void _cancelInvite(PendingInvite invite) {
    _update(
      _entry.copyWith(
        pending: [
          for (final p in _entry.pending)
            if (p != invite) p,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _entry.item;
    void soon() => showComingSoon(context);

    // Opens partway so the page behind stays in view; drag it up for more
    // room, or down to close it. The list scrolls once it is all the way up.
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _openSize,
      minChildSize: _closeSize,
      maxChildSize: _fullSize,
      snap: true,
      snapSizes: const [_openSize, _fullSize],
      builder: (context, scrollController) => Material(
        color: theme.colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            const _DragHandle(),
            Row(
              children: [
                FileTypeIcon(name: item.name, kind: item.kind),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('People with access', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            _PersonRow(
              person: Collaborator.owner,
              // Short enough to stay on one line, like the rows below.
              subtitle: 'Full control',
              trailing: const RoleChip(ShareRole.owner),
            ),
            for (final shared in _entry.people)
              _PersonRow(
                key: ValueKey(shared.person.name),
                person: shared.person,
                subtitle: shared.trust.label,
                trustIcon: shared.trust == KeyTrust.verified
                    ? Icons.verified_outlined
                    : Icons.help_outline,
                trailing: _RoleButton(
                  person: shared.person,
                  role: shared.role,
                  onRole: (role) => _setRole(shared, role),
                  onRemove: () => _revoke(shared),
                ),
              ),
            if (_entry.pending.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Waiting for an answer', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              for (final invite in _entry.pending)
                _PersonRow(
                  key: ValueKey('pending ${invite.person.name}'),
                  person: invite.person,
                  subtitle:
                      '${invite.role.label} · ${invite.expiryText(widget.now)}',
                  // Not the wide role column: a small red icon on the right.
                  compact: true,
                  trailing: IconButton(
                    onPressed: () => _cancelInvite(invite),
                    tooltip: 'Cancel invitation for ${invite.person.name}',
                    icon: const Icon(Icons.close),
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: soon,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Invite people'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: soon,
              child: const Text('Transfer ownership…'),
            ),
          ],
        ),
      ),
    );
  }
}

// How tall the sheet is, as a share of the screen: where it opens, the most it
// reaches, and the height below which dragging down closes it.
const _openSize = 0.6;
const _fullSize = 0.95;
const _closeSize = 0.3;

/// The small bar at the top of the sheet that says it can be dragged.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Drag to resize or close',
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// The width of the column at the right of every row, so the Owner label and
/// the role buttons line up with the same edges.
const _slotWidth = 108.0;

/// The height of the buttons in that column.
const _slotHeight = 36.0;

/// An outlined button that fills the right-hand column.
class _SlotButton extends StatelessWidget {
  const _SlotButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _slotWidth,
      height: _slotHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.only(left: 12, right: 4),
        ),
        child: child,
      ),
    );
  }
}

/// The dropdown of someone with access: it shows their role, and opens a menu
/// to change it to Editor or Viewer, or to remove their access.
class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.person,
    required this.role,
    required this.onRole,
    required this.onRemove,
  });

  final Collaborator person;
  final ShareRole role;
  final ValueChanged<ShareRole> onRole;
  final VoidCallback onRemove;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;

    final choice = await showAnchoredMenu<_RoleChoice>(
      context,
      anchor: anchor,
      items: [
        MenuItemData(
          value: _RoleChoice.editor,
          label: ShareRole.editor.label,
          icon: RoleChip.iconFor(ShareRole.editor),
          selected: role == ShareRole.editor,
        ),
        MenuItemData(
          value: _RoleChoice.viewer,
          label: ShareRole.viewer.label,
          icon: RoleChip.iconFor(ShareRole.viewer),
          selected: role == ShareRole.viewer,
        ),
        const MenuItemData(
          value: _RoleChoice.remove,
          label: 'Remove access',
          icon: Icons.person_remove_outlined,
          destructive: true,
          dividerBefore: true,
        ),
      ],
    );

    switch (choice) {
      case _RoleChoice.editor:
        onRole(ShareRole.editor);
      case _RoleChoice.viewer:
        onRole(ShareRole.viewer);
      case _RoleChoice.remove:
        onRemove();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Builder gives the button's own position to anchor the menu to.
    return Builder(
      builder: (buttonContext) => Tooltip(
        message: 'Access for ${person.name}',
        child: _SlotButton(
          onPressed: () => _open(buttonContext),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  role.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small icon before a trust label, centered on the text's line, and
/// growing with the text size so it stays level with it.
class _TrustIcon extends StatelessWidget {
  const _TrustIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(14);

    return ExcludeSemantics(
      child: Icon(icon, size: size, color: color),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    super.key,
    required this.person,
    required this.subtitle,
    required this.trailing,
    this.trustIcon,
    this.compact = false,
  });

  final Collaborator person;
  final String subtitle;
  final Widget trailing;

  /// Whether [trailing] is small and takes only its own width, leaving the
  /// rest to the name, instead of the fixed-width right-hand column.
  final bool compact;

  /// A small icon before the subtitle, for how far the person's key is trusted.
  final IconData? trustIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      // Room between people, so the rows do not run together.
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          CollaboratorAvatars(
            collaborators: [person],
            size: 40,
            ringColor: theme.colorScheme.surfaceContainerLow,
            semanticLabel: person.name,
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          // The name and what is under it take whatever the fixed right-hand
          // column leaves, and wrap onto a second line instead of being cut.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
                // The icon and its text share one center line.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (trustIcon != null) ...[
                      _TrustIcon(icon: trustIcon!, color: muted),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (compact)
            // An icon button is 48 wide with the 24 px icon centered; pull it
            // back so the icon ends at the same right edge as the buttons.
            Transform.translate(offset: const Offset(12, 0), child: trailing)
          else
            SizedBox(
              width: _slotWidth,
              child: Align(alignment: Alignment.centerRight, child: trailing),
            ),
        ],
      ),
    );
  }
}
