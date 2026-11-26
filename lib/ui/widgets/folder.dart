import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/svg_path.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/folder_paths.dart';

/// A closed folder with two pages tucked inside, drawn from the shapes in
/// `design/folder-closed.svg`. It scales to the width it is given, and the
/// optional [title] and [subtitle] are written on its cover.
class Folder extends StatelessWidget {
  const Folder({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.footer,
    this.colors,
  });

  final String? title;

  /// Shown under the [title], usually how many files the folder holds.
  final String? subtitle;

  /// Put on the cover at the right, level with the [title] and [subtitle],
  /// such as the people the folder is shared with.
  final Widget? trailing;

  /// Put on the cover under the [title], [subtitle] and [trailing], with some
  /// space between, such as chips for the last action.
  final Widget? footer;

  /// Overrides the theme's [FolderColors].
  final FolderColors? colors;

  /// Width divided by height of the folder.
  static const aspectRatio = _FolderShapes.width / _FolderShapes.height;

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? Theme.of(context).extension<FolderColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      image: true,
      label: ['Folder', ?title, ?subtitle].join(', '),
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The text is sized from the folder, so it stays in proportion.
            final width = constraints.maxWidth;
            final inset = width * 0.075;

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _FolderPainter(palette)),
                ),
                if (title != null ||
                    subtitle != null ||
                    trailing != null ||
                    footer != null)
                  Positioned(
                    left: inset,
                    right: inset,
                    bottom: width * 0.065,
                    // The cover has a fixed size, so large system text is
                    // capped here. The semantics label still has everything.
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (title != null)
                                      Text(
                                        title!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontSize: math.max(width * 0.075, 12),
                                        ),
                                      ),
                                    if (subtitle != null)
                                      Text(
                                        subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontSize: math.max(width * 0.058, 10),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (trailing != null) ...[
                                SizedBox(width: inset / 2),
                                trailing!,
                              ],
                            ],
                          ),
                          if (footer != null) ...[
                            // Room between the name, count and people above and
                            // the footer, in proportion to the folder.
                            SizedBox(height: width * 0.07),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The shapes, in the SVG's own coordinates.
class _FolderShapes {
  /// The folder's bounds inside the SVG's 793.7 x 793.7 artboard.
  static const left = 102.8;
  static const top = 133.4;
  static const width = 588.1;
  static const height = 526.9;

  static final back = parseSvgPath(folderBackData);
  static final pageRight = parseSvgPath(folderPageRightData);
  static final pageLeft = parseSvgPath(folderPageLeftData);
  static final accent = parseSvgPath(folderAccentData);
  static final cover = parseSvgPath(folderCoverData);
}

class _FolderPainter extends CustomPainter {
  const _FolderPainter(this.colors);

  final FolderColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the folder's part of the artboard to the box.
    canvas
      ..scale(
        size.width / _FolderShapes.width,
        size.height / _FolderShapes.height,
      )
      ..translate(-_FolderShapes.left, -_FolderShapes.top);

    // Back to front, as in the SVG.
    canvas
      ..drawPath(
        _FolderShapes.back,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(396.85, 134.6421),
            const Offset(396.85, 656.6712),
            [colors.backTop, colors.backBottom],
          ),
      )
      ..drawPath(_FolderShapes.pageRight, Paint()..color = colors.page)
      ..drawPath(_FolderShapes.pageLeft, Paint()..color = colors.page)
      ..drawPath(_FolderShapes.accent, Paint()..color = colors.pageShade)
      ..drawPath(
        _FolderShapes.cover,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(396.85, 654.0553),
            const Offset(396.85, 309.1912),
            [colors.cover, colors.cover.withValues(alpha: 0.5)],
            const [0.3, 1],
          ),
      );
  }

  @override
  bool shouldRepaint(_FolderPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
