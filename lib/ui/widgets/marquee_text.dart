import 'package:flutter/material.dart';

/// One line of text that scrolls sideways, slowly and without end, when it is
/// too long to fit (like a long song title). Text that fits stays still. When
/// the system asks for reduced motion it is cut off with an ellipsis instead.
class MarqueeText extends StatelessWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.pixelsPerSecond = 24,
    this.pause = const Duration(seconds: 2),
    this.gap = 28,
  });

  final String text;
  final TextStyle? style;

  /// How fast the text moves.
  final double pixelsPerSecond;

  /// How long the start of the text rests before each pass.
  final Duration pause;

  /// The space between the end of the text and its next copy.
  final double gap;

  /// Turns the scrolling off everywhere. Tests set this so they can wait for
  /// the screen to settle, since scrolling never ends.
  @visibleForTesting
  static bool enabled = true;

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final still = !enabled || MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: resolved),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final textWidth = painter.width;
        final textHeight = painter.height;
        painter.dispose();

        final fits = textWidth <= constraints.maxWidth;
        if (fits || still) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return SizedBox(
          height: textHeight,
          child: _Scroller(
            text: text,
            style: style,
            textWidth: textWidth,
            width: constraints.maxWidth,
            pixelsPerSecond: pixelsPerSecond,
            pause: pause,
            gap: gap,
          ),
        );
      },
    );
  }
}

class _Scroller extends StatefulWidget {
  const _Scroller({
    required this.text,
    required this.style,
    required this.textWidth,
    required this.width,
    required this.pixelsPerSecond,
    required this.pause,
    required this.gap,
  });

  final String text;
  final TextStyle? style;
  final double textWidth;
  final double width;
  final double pixelsPerSecond;
  final Duration pause;
  final double gap;

  @override
  State<_Scroller> createState() => _ScrollerState();
}

class _ScrollerState extends State<_Scroller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  // One pass moves the text by its own width plus the gap, so the copy that
  // follows lands exactly where the text started.
  double get _travel => widget.textWidth + widget.gap;
  Duration get _scrollTime =>
      Duration(milliseconds: (_travel / widget.pixelsPerSecond * 1000).round());

  void _restart() {
    _controller
      ..duration = widget.pause + _scrollTime
      ..repeat();
  }

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(_Scroller old) {
    super.didUpdateWidget(old);
    if (old.textWidth != widget.textWidth ||
        old.gap != widget.gap ||
        old.pixelsPerSecond != widget.pixelsPerSecond ||
        old.pause != widget.pause) {
      _restart();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
    );
    final total = _controller.duration!.inMilliseconds;
    final rest = widget.pause.inMilliseconds;

    return RepaintBoundary(
      child: ShaderMask(
        // Fades the right edge, so text does not end in a hard cut.
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.88, 1],
        ).createShader(bounds),
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final elapsed = _controller.value * total;
                final moved = elapsed <= rest
                    ? 0.0
                    : (elapsed - rest) / (total - rest) * _travel;
                return Transform.translate(
                  offset: Offset(-moved, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  text,
                  SizedBox(width: widget.gap),
                  // The same words again, for the seam; screen readers skip it.
                  ExcludeSemantics(
                    child: Text(
                      widget.text,
                      style: widget.style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
