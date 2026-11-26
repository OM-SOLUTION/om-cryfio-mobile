import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

/// The line under a file's name: "12 MB | Edited | Today, 14:30". It stays on
/// one line; when it is too long for the space it scrolls (see [MarqueeText]).
class FileActivityText extends StatelessWidget {
  const FileActivityText({
    super.key,
    this.details,
    this.activity,
    this.style,
    this.now,
  });

  /// The file's size, or a folder's file count.
  final String? details;
  final FileActivity? activity;
  final TextStyle? style;

  /// What "today" is. Left out, the current time.
  final DateTime? now;

  /// The parts, in order, with no empty ones.
  static List<String> parts(
    String? details,
    FileActivity? activity,
    DateTime now,
  ) => [
    if (details != null && details.isNotEmpty) details,
    if (activity != null) activity.kind.label,
    if (activity != null) activity.time(now),
  ];

  @override
  Widget build(BuildContext context) {
    final texts = parts(details, activity, now ?? DateTime.now());
    if (texts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return MarqueeText(
      texts.join(' | '),
      style:
          style ??
          theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );
  }
}
