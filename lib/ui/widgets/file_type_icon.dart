import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_kind.dart';
import 'package:om_cryfio/ui/theme/file_type_colors.dart';

/// The small icon in front of a file or folder in a list: its kind's own icon in
/// its color, or for a type we have no picture for the plain file icon in the
/// color of its extension. It has no box around it.
class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({super.key, required this.name, required this.kind});

  final String name;
  final FileKind kind;

  /// Width and height of the space the icon sits in.
  static const size = 40.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    // Unknown types are colored by their extension; with none, the theme's.
    final accent = FileTypeColors.forFile(kind, name) ?? scheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: ExcludeSemantics(
          child: Icon(
            kind.icon,
            size: 32,
            color: FileTypeColors.iconFor(accent, brightness),
          ),
        ),
      ),
    );
  }
}
