/// Real extensions are short and plain: letters, digits, `_`, `+` and `-`.
final _plausible = RegExp(r'^[a-z0-9_+-]{1,12}$');

/// [extension] in lower case and without a leading dot, or an empty string if
/// it does not look like a real extension: one to twelve letters, digits, `_`,
/// `+` or `-`. This keeps text such as ` Final version` (from a name like
/// `Meeting notes. Final version`) from being taken for one.
String normalizeExtension(String extension) {
  final text = extension.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
  return _plausible.hasMatch(text) ? text : '';
}

/// The extension of [name] in lower case and without the dot, or an empty
/// string if it has none (see [normalizeExtension]). A name that only starts
/// with a dot, such as `.gitignore`, has no extension.
String fileExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return normalizeExtension(name.substring(dot + 1));
}
