import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/ui/widgets/coming_soon.dart';

/// Everything a file or folder menu can do.
enum FileAction {
  download,
  share,
  copy,
  rename,
  move,
  uploadNewVersion,
  showVersionHistory,
  toggleFavorite,
  showDetails,
  transferOwnership,
  moveToRecycleBin,
}

/// The actions in a file's menu, in the order they appear.
const fileMenuActions = [
  FileAction.download,
  FileAction.share,
  FileAction.copy,
  FileAction.rename,
  FileAction.move,
  FileAction.uploadNewVersion,
  FileAction.showVersionHistory,
  FileAction.toggleFavorite,
  FileAction.showDetails,
  FileAction.transferOwnership,
  FileAction.moveToRecycleBin,
];

/// The actions in a folder's menu, in the order they appear. Folders cannot be
/// downloaded or copied, and have no versions.
const folderMenuActions = [
  FileAction.share,
  FileAction.rename,
  FileAction.move,
  FileAction.toggleFavorite,
  FileAction.showDetails,
  FileAction.transferOwnership,
  FileAction.moveToRecycleBin,
];

// What an Editor may do, and what a Viewer may do, of the actions above.
const _editorActions = {
  FileAction.download,
  FileAction.copy,
  FileAction.rename,
  FileAction.move,
  FileAction.uploadNewVersion,
  FileAction.showVersionHistory,
  FileAction.toggleFavorite,
  FileAction.showDetails,
  FileAction.moveToRecycleBin,
};
const _viewerActions = {
  FileAction.download,
  FileAction.copy,
  FileAction.showVersionHistory,
  FileAction.toggleFavorite,
  FileAction.showDetails,
};

/// The actions in the menu of [item] for someone who holds [role] on it, in the
/// order they appear. Left out, or for the Owner, that is all of them: sharing
/// and transferring belong to the Owner alone.
List<FileAction> menuActionsFor(FileItem item, {ShareRole? role}) {
  final all = item.isFolder ? folderMenuActions : fileMenuActions;
  return switch (role) {
    null || ShareRole.owner => all,
    ShareRole.editor => [
      for (final action in all)
        if (_editorActions.contains(action)) action,
    ],
    ShareRole.viewer => [
      for (final action in all)
        if (_viewerActions.contains(action)) action,
    ],
  };
}

/// What happens when a menu action is chosen. Every method is a placeholder
/// that says "Coming soon"; replace its body with the real behavior. The roles
/// listed are who may use the action.
class FileActions {
  const FileActions();

  /// Decrypts the file on the device and saves it. Owner, Editor, Viewer.
  void download(BuildContext context, FileItem item) => showComingSoon(context);

  /// Opens sharing: invite people, set their roles, revoke access. Owner.
  void share(BuildContext context, FileItem item) => showComingSoon(context);

  /// Makes a new file in the user's own storage: decrypts the source and
  /// encrypts it again under a new key. Files only. Owner, Editor, Viewer.
  void copy(BuildContext context, FileItem item) => showComingSoon(context);

  /// Renames the item. Owner, Editor.
  void rename(BuildContext context, FileItem item) => showComingSoon(context);

  /// Moves the item to another folder. Owner; an Editor only inside the shared
  /// folder they were given.
  void move(BuildContext context, FileItem item) => showComingSoon(context);

  /// Uploads a new version of the file. Files only. Owner, Editor.
  void uploadNewVersion(BuildContext context, FileItem item) =>
      showComingSoon(context);

  /// Lists the file's versions and restores one. Files only. Everyone can look;
  /// Owner and Editor can restore.
  void showVersionHistory(BuildContext context, FileItem item) =>
      showComingSoon(context);

  /// Adds the item to the user's favorites, or removes it. Owner, Editor,
  /// Viewer.
  void toggleFavorite(BuildContext context, FileItem item) =>
      showComingSoon(context);

  /// Shows size, owner, dates and who the item is shared with. Owner, Editor,
  /// Viewer.
  void showDetails(BuildContext context, FileItem item) =>
      showComingSoon(context);

  /// Proposes a new owner, who has to accept. Owner.
  void transferOwnership(BuildContext context, FileItem item) =>
      showComingSoon(context);

  /// Moves the item to the Recycle Bin, where it stays for 7 days. Owner,
  /// Editor.
  void moveToRecycleBin(BuildContext context, FileItem item) =>
      showComingSoon(context);

  /// Runs [action] on [item].
  void run(BuildContext context, FileAction action, FileItem item) {
    switch (action) {
      case FileAction.download:
        download(context, item);
      case FileAction.share:
        share(context, item);
      case FileAction.copy:
        copy(context, item);
      case FileAction.rename:
        rename(context, item);
      case FileAction.move:
        move(context, item);
      case FileAction.uploadNewVersion:
        uploadNewVersion(context, item);
      case FileAction.showVersionHistory:
        showVersionHistory(context, item);
      case FileAction.toggleFavorite:
        toggleFavorite(context, item);
      case FileAction.showDetails:
        showDetails(context, item);
      case FileAction.transferOwnership:
        transferOwnership(context, item);
      case FileAction.moveToRecycleBin:
        moveToRecycleBin(context, item);
    }
  }
}

final fileActionsProvider = Provider<FileActions>((ref) {
  return const FileActions();
});
