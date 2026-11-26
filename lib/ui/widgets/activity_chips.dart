import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_activity.dart';

/// The last action on a file and when it happened, as two pill chips such as
/// "Shared" and "Yesterday, 18:19": an icon and the text, in white on a
/// translucent white fill. Meant for a dark or colored surface like a folder's
/// cover or a file's picture, so they look the same on both. They stay
/// at one fixed text size and wrap to a second line if they
/// do not fit.
class ActivityChips extends StatelessWidget {
  const ActivityChips({
    super.key,
    required this.activity,
    this.now,
    this.fontSize = 14,
  });

  /// The text size. The same everywhere, so the chips look the same on a folder
  /// and on a file.
  final double fontSize;

  final FileActivity activity;

  /// What "today" is. Left out, the current time.
  final DateTime? now;

  static IconData iconFor(FileActivityKind kind) => switch (kind) {
    FileActivityKind.uploaded => Icons.upload_outlined,
    FileActivityKind.edited => Icons.edit_outlined,
    FileActivityKind.shared => Icons.people_outline,
    FileActivityKind.renamed => Icons.drive_file_rename_outline,
    FileActivityKind.moved => Icons.drive_file_move_outlined,
    FileActivityKind.downloaded => Icons.download_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: fontSize * 0.6,
      runSpacing: fontSize * 0.5,
      children: [
        _Chip(
          icon: iconFor(activity.kind),
          label: activity.kind.label,
          fontSize: fontSize,
        ),
        _Chip(
          icon: Icons.schedule,
          label: activity.time(now ?? DateTime.now()),
          fontSize: fontSize,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.fontSize,
  });

  final IconData icon;
  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.8,
          vertical: fontSize * 0.4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: fontSize * 1.2, color: Colors.white),
            SizedBox(width: fontSize * 0.4),
            // Cut off rather than overflow if the room is very narrow.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
