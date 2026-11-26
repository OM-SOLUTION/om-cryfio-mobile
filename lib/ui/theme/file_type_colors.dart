import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_kind.dart';
import 'package:om_cryfio/ui/file_name.dart';

/// The ten named colors a file type can get: the primary colors red, yellow and
/// blue, the secondary colors orange, green and purple, and four more (lime,
/// teal, indigo and pink). Each is a hue in degrees. A file's extension picks
/// one of them.
abstract final class FileIconColors {
  static const primary = <String, double>{
    'red': 0,
    'yellow': 37.32057416267943,
    'blue': 220,
  };

  static const secondary = <String, double>{
    'orange': 20,
    'green': 130,
    'purple': 280,
  };

  static const more = <String, double>{
    'lime': 80,
    'teal': 175,
    'indigo': 250,
    'pink': 330,
  };

  /// All ten: primary colors first, then secondary, then the rest.
  static const all = <String, double>{...primary, ...secondary, ...more};
}

/// The color of each kind of file, and a stable color for any other extension.
abstract final class FileTypeColors {
  static const folder = Color(0xFF3592E9);
  static const pdf = Color(0xFFE5484D);
  static const document = Color(0xFF3E7BFA);
  static const image = Color(0xFF2FB67C);
  static const archive = Color(0xFFF5A524);

  static const _hueSeed = 5118;

  /// The color of [kind], or null for [FileKind.other]: those files get a color
  /// from their extension instead (see [hueForExtension]).
  static Color? forKind(FileKind kind) => switch (kind) {
    FileKind.folder => folder,
    FileKind.pdf => pdf,
    FileKind.document => document,
    FileKind.image => image,
    FileKind.archive => archive,
    FileKind.other => null,
  };

  /// The color of an unknown type, from the hue its extension always gets.
  static Color forExtension(String extension) {
    // Vivid, like the colors of the known kinds above.
    return HSLColor.fromAHSL(
      1,
      hueForExtension(extension),
      0.75,
      0.55,
    ).toColor();
  }

  /// The color for a file called [name] of [kind]: its kind's color, or for an
  /// unknown type the color of its extension. Null for a file with neither.
  static Color? forFile(FileKind kind, String name) {
    final extension = fileExtension(name);
    return forKind(kind) ??
        (extension.isEmpty ? null : forExtension(extension));
  }

  /// The background behind an icon of [color]: a light wash of it.
  static Color containerFor(Color color, Brightness brightness) =>
      color.withValues(alpha: brightness == Brightness.dark ? 0.24 : 0.16);

  /// The icon itself, brightened a little on a dark theme so it stays clear.
  static Color iconFor(Color color, Brightness brightness) =>
      brightness == Brightness.dark
      ? Color.lerp(color, Colors.white, 0.3)!
      : color;

  /// A hue in degrees (0 up to 360) for an extension: one of the named colors
  /// of [FileIconColors]. The same extension always gets the same one, on every
  /// run and device, and different ones are likely to differ.
  static double hueForExtension(String extension) {
    // FNV-1a, because String.hashCode is not promised to stay the same. The
    // seed was picked so that the sample files each get their own color and
    // about twenty common extensions use all the colors, at most twice each.
    // Changing the seed, or the order or number of named colors, recolors every
    // type.
    var hash = 0x811C9DC5 ^ _hueSeed;
    for (final unit in extension.toLowerCase().codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    // The low bits of this hash depend only on the low bits of each letter, so
    // use higher ones.
    final hues = FileIconColors.all.values.toList();
    return hues[(hash >> 16) % hues.length];
  }
}
