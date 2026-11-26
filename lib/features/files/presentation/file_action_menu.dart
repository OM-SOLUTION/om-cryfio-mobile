import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:om_cryfio/features/files/application/file_actions.dart';
import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/ui/widgets/anchored_menu.dart';

/// The ⋮ button of a list row. Opens the item's actions next to the button.
class FileActionMenuButton extends ConsumerWidget {
  const FileActionMenuButton({super.key, required this.item, this.role});

  final FileItem item;

  /// The user's role on the item, which decides what the menu offers. Left out,
  /// the user owns it.
  final ShareRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'More options for ${item.name}',
      icon: const Icon(Icons.more_vert),
      onPressed: () {
        final button = context.findRenderObject()! as RenderBox;
        showFileActionMenu(
          context,
          ref,
          item,
          button.localToGlobal(Offset.zero) & button.size,
          role: role,
        );
      },
    );
  }
}

/// Opens the item's actions next to [anchor] (a rectangle in screen
/// coordinates; a zero-size one for a point such as where a tile was held) and
/// runs the one that is chosen.
Future<void> showFileActionMenu(
  BuildContext context,
  WidgetRef ref,
  FileItem item,
  Rect anchor, {
  ShareRole? role,
}) async {
  final action = await showAnchoredMenu<FileAction>(
    context,
    anchor: anchor,
    items: fileActionMenuItems(item, role: role),
  );
  if (action != null && context.mounted) {
    ref.read(fileActionsProvider).run(context, action, item);
  }
}

/// The menu rows for [item]: one per action, with the destructive one last and
/// set apart.
List<MenuItemData<FileAction>> fileActionMenuItems(
  FileItem item, {
  ShareRole? role,
}) {
  final actions = menuActionsFor(item, role: role);

  return [
    for (final action in actions)
      MenuItemData(
        value: action,
        label: _label(action, item),
        icon: _icon(action, item),
        destructive: action == FileAction.moveToRecycleBin,
        dividerBefore: action == FileAction.moveToRecycleBin,
      ),
  ];
}

// An ellipsis marks actions that ask for more before they act.
String _label(FileAction action, FileItem item) => switch (action) {
  FileAction.download => 'Download',
  FileAction.share => 'Share…',
  FileAction.copy => 'Copy…',
  FileAction.rename => 'Rename',
  FileAction.move => 'Move…',
  FileAction.uploadNewVersion => 'Upload new version',
  FileAction.showVersionHistory => 'Version history',
  FileAction.toggleFavorite =>
    item.favorite ? 'Remove from favorites' : 'Add to favorites',
  FileAction.showDetails => 'Details',
  FileAction.transferOwnership => 'Transfer ownership…',
  FileAction.moveToRecycleBin => 'Move to Recycle Bin',
};

IconData _icon(FileAction action, FileItem item) => switch (action) {
  FileAction.download => Icons.download_outlined,
  FileAction.share => Icons.share_outlined,
  FileAction.copy => Icons.content_copy_outlined,
  FileAction.rename => Icons.drive_file_rename_outline,
  FileAction.move => Icons.drive_file_move_outlined,
  FileAction.uploadNewVersion => Icons.upload_file_outlined,
  FileAction.showVersionHistory => Icons.history,
  FileAction.toggleFavorite => item.favorite ? Icons.star : Icons.star_outline,
  FileAction.showDetails => Icons.info_outline,
  FileAction.transferOwnership => Icons.swap_horiz,
  FileAction.moveToRecycleBin => Icons.delete_outline,
};
