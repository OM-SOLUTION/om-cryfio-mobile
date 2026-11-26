import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/file_kind.dart';
import 'package:om_cryfio/ui/widgets/collaborator_avatars.dart';
import 'package:om_cryfio/ui/widgets/file_activity_text.dart';
import 'package:om_cryfio/ui/widgets/file_type_icon.dart';

export 'package:om_cryfio/ui/file_kind.dart';

/// One row in a file or folder list: the icon, the name, a line with the size,
/// the last action and when it happened, and at the end the people with access
/// and the row's menu.
///
/// For something another person shared, give [sharedBy]: their picture goes
/// next to the icon, overlapping it, and the people group at the end is left
/// out, since the owner is the one pictured.
class FileListTile extends StatelessWidget {
  const FileListTile({
    super.key,
    required this.name,
    required this.kind,
    this.details,
    this.activity,
    this.collaborators = const [],
    this.sharedBy,
    this.below,
    this.onTap,
    this.menu,
  });

  final String name;
  final FileKind kind;

  /// The size, or a folder's file count.
  final String? details;
  final FileActivity? activity;

  /// The people with access apart from the owner, who is the user ("You").
  final List<Collaborator> collaborators;

  /// Who shared it with the user. Left out, the user owns it.
  final Collaborator? sharedBy;

  /// Another line under the size and action, such as the user's role.
  final Widget? below;
  final VoidCallback? onTap;

  /// The row's actions, usually a ⋮ button that opens a menu.
  final Widget? menu;

  // How far the sharer's picture reaches over the icon, and its size.
  static const _pictureSize = 36.0;
  static const _pictureOverlap = 12.0;

  Widget _leading(BuildContext context) {
    final icon = FileTypeIcon(name: name, kind: kind);
    final sharer = sharedBy;
    if (sharer == null) return icon;

    // The picture first and on top, the icon pushed right under its edge.
    const iconLeft = _pictureSize - _pictureOverlap;
    return SizedBox(
      width: iconLeft + FileTypeIcon.size,
      height: FileTypeIcon.size,
      child: Stack(
        children: [
          Positioned(left: iconLeft, child: icon),
          Positioned(
            left: 0,
            top: (FileTypeIcon.size - _pictureSize) / 2,
            child: CollaboratorAvatars(
              collaborators: [sharer],
              size: _pictureSize,
              semanticLabel: 'Shared by ${sharer.name}',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInfo =
        (details != null && details!.isNotEmpty) || activity != null;

    return ListTile(
      onTap: onTap,
      // Less room at the end than the default, so the ⋮ button (which has its
      // own space around its icon) sits close to the screen edge.
      contentPadding: EdgeInsetsDirectional.only(
        start: 16,
        end: menu != null ? 4 : 16,
      ),
      leading: _leading(context),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: hasInfo || below != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasInfo)
                  FileActivityText(details: details, activity: activity),
                if (below != null) ...[
                  if (hasInfo) const SizedBox(height: 4),
                  below!,
                ],
              ],
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Everyone as one group, the owner first, unless someone else owns it
          // and is pictured next to the icon.
          if (sharedBy == null)
            CollaboratorAvatars(
              collaborators: Collaborator.group(collaborators),
              size: 28,
              semanticLabel:
                  CollaboratorAvatars.describe(collaborators) ?? 'Only you',
            ),
          ?menu,
        ],
      ),
    );
  }
}
