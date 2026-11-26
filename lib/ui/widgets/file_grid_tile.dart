import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/theme/file_type_colors.dart';
import 'package:om_cryfio/ui/widgets/activity_chips.dart';
import 'package:om_cryfio/ui/widgets/collaborator_avatars.dart';
import 'package:om_cryfio/ui/widgets/file_activity_text.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/folder.dart';

/// One file or folder in the grid layout. Every tile is a card with the same
/// padding.
///
/// A folder holds the [Folder] with its name and file count written on its
/// cover, the people with access at the right of them, and the last action and
/// when it happened as chips under them.
///
/// A file holds a picture with its icon in the middle, the people at the top
/// right and the same chips at the bottom left, and under it the name with the
/// row's menu button at the end. The file's size is not shown here.
class FileGridTile extends StatelessWidget {
  const FileGridTile({
    super.key,
    required this.name,
    required this.kind,
    this.details,
    this.activity,
    this.collaborators = const [],
    this.onTap,
    this.onLongPress,
    this.menu,
  });

  final String name;
  final FileKind kind;

  /// A folder's file count, written on its cover. For a file it is only read
  /// out to screen readers, not shown.
  final String? details;
  final FileActivity? activity;
  final List<Collaborator> collaborators;
  final VoidCallback? onTap;

  /// Called with the screen position where the tile was held, so a menu can
  /// open there. Screen readers get the same thing as a "Show actions" action.
  final ValueChanged<Offset>? onLongPress;

  /// The ⋮ button at the end of a file's name, which opens its actions. A folder
  /// has none: it has no room under its cover, and it opens its menu when held.
  final Widget? menu;

  /// Space between a card's edge and its content. A grid needs it to work out
  /// how tall its rows are.
  static const inset = 12.0;

  /// Diameter of the people circles.
  static const avatarSize = 34.0;

  /// Width divided by height of a file card's picture.
  static const filePictureAspect = 1.2;

  /// The space between the picture and the line below it.
  static const gap = AppSpacing.sm;

  /// How tall the row with a file's name and its menu button is. A grid needs it
  /// to work out how tall its rows are.
  static double nameRowHeight(TextScaler scaler) =>
      math.max(_menuSize, scaler.scale(16) * 1.5);

  // The ⋮ button's size, which is also the least height of the name row.
  static const _menuSize = 40.0;

  /// The outline of the people circles on a folder's cover: about the cover's
  /// color, so they look cut out of it.
  static const folderRing = Color(0xFF2F7BD6);

  /// The icon's height as a share of its picture's, which leaves room around
  /// it for the people and the chips.
  static const _iconShare = 0.5;

  String get _label => [
    name,
    ...FileActivityText.parts(details, activity, DateTime.now()),
    ?CollaboratorAvatars.describe(collaborators),
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final onLongPress = this.onLongPress;

    return Semantics(
      container: true,
      button: onTap != null,
      label: _label,
      // The inner tap targets are hidden from screen readers below, so the
      // tile has to expose its own actions.
      onTap: onTap,
      onLongPressHint: 'Show actions',
      onLongPress: onLongPress == null
          ? null
          : () {
              // No touch point here, so open the menu from the tile's center.
              final box = context.findRenderObject()! as RenderBox;
              onLongPress(box.localToGlobal(box.size.center(Offset.zero)));
            },
      excludeSemantics: true,
      child: GestureDetector(
        onLongPressStart: onLongPress == null
            ? null
            : (details) => onLongPress(details.globalPosition),
        child: kind == FileKind.folder
            ? _buildFolder(context)
            : _buildFileCard(context),
      ),
    );
  }

  Widget _buildFolder(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Folder(
                title: name,
                subtitle: details,
                // The people sit on the cover, level with the name and count,
                // as one group with the owner first.
                trailing: CollaboratorAvatars(
                  collaborators: Collaborator.group(collaborators),
                  size: avatarSize,
                  ringColor: folderRing,
                ),
                // The last action and when, as chips under the name, count and
                // people.
                footer: activity == null
                    ? null
                    : ActivityChips(activity: activity!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = FileTypeColors.forFile(kind, name);
    final background = accent == null
        ? scheme.secondaryContainer
        : FileTypeColors.containerFor(accent, theme.brightness);
    final iconColor = accent == null
        ? scheme.onSecondaryContainer
        : FileTypeColors.iconFor(accent, theme.brightness);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: filePictureAspect,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  // Clips the fade behind the chips to the rounded corners.
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Stack(
                      children: [
                        // The icon, small, with room all around it.
                        Positioned.fill(
                          child: Center(
                            child: FractionallySizedBox(
                              heightFactor: _iconShare,
                              child: FittedBox(
                                child: Icon(
                                  kind.icon,
                                  size: 64,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Everyone with access, as one group, owner first.
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: CollaboratorAvatars(
                            collaborators: Collaborator.group(collaborators),
                            size: avatarSize,
                            ringColor: Color.alphaBlend(
                              background,
                              scheme.surfaceContainerLow,
                            ),
                            semanticLabel:
                                CollaboratorAvatars.describe(collaborators) ??
                                'Only you',
                          ),
                        ),
                        // The last action and when, as the same chips as on a
                        // folder. A soft dark fade behind them keeps their white
                        // text readable on a pale picture.
                        if (activity != null) ...[
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 96,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.4),
                                    Colors.black.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: AppSpacing.sm,
                            right: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: ActivityChips(activity: activity!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: gap),
              SizedBox(
                height: nameRowHeight(MediaQuery.textScalerOf(context)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (menu != null)
                      SizedBox(
                        width: _menuSize,
                        height: _menuSize,
                        child: menu,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
