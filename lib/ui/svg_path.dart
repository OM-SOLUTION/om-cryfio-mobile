import 'package:flutter/painting.dart';

final _token = RegExp(r'[A-Za-z]|-?\d*\.?\d+');
final _letter = RegExp('[A-Za-z]');

/// Parses SVG path data into a [Path].
///
/// Supports M, L, H, V, C, S and Z, in both absolute (upper case) and relative
/// (lower case) form, which is what design tools export for simple shapes.
/// Any other command throws a [FormatException].
Path parseSvgPath(String data) {
  final tokens = [for (final match in _token.allMatches(data)) match[0]!];
  final path = Path();
  var command = '';
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;
  // The last cubic curve's second control point, which a following S command
  // mirrors to get its own first control point.
  Offset? lastControl;
  var i = 0;

  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (_letter.hasMatch(tokens[i])) {
      command = tokens[i++];
      if (command == 'Z' || command == 'z') {
        path.close();
        x = startX;
        y = startY;
        continue;
      }
    }

    // A relative command measures from where the previous one ended.
    final relative = command == command.toLowerCase();
    final originX = relative ? x : 0.0;
    final originY = relative ? y : 0.0;
    Offset? control;

    switch (command.toUpperCase()) {
      case 'M':
        x = originX + next();
        y = originY + next();
        startX = x;
        startY = y;
        path.moveTo(x, y);
        command = relative ? 'l' : 'L'; // More pairs after a moveto are lines.
      case 'L':
        x = originX + next();
        y = originY + next();
        path.lineTo(x, y);
      case 'H':
        x = originX + next();
        path.lineTo(x, y);
      case 'V':
        y = originY + next();
        path.lineTo(x, y);
      case 'C':
        final x1 = originX + next();
        final y1 = originY + next();
        final x2 = originX + next();
        final y2 = originY + next();
        x = originX + next();
        y = originY + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        control = Offset(x2, y2);
      case 'S':
        final x1 = lastControl == null ? x : 2 * x - lastControl.dx;
        final y1 = lastControl == null ? y : 2 * y - lastControl.dy;
        final x2 = originX + next();
        final y2 = originY + next();
        x = originX + next();
        y = originY + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        control = Offset(x2, y2);
      default:
        throw FormatException('Unsupported path command "$command".');
    }
    lastControl = control;
  }
  return path;
}
