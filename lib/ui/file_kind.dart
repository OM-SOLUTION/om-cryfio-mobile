import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/file_name.dart';

/// The families of file the app has a look for. Anything else is [other].
enum FileKind { folder, document, image, pdf, archive, other }

extension FileKindIcon on FileKind {
  IconData get icon => switch (this) {
    FileKind.folder => Icons.folder_outlined,
    FileKind.document => Icons.description_outlined,
    FileKind.image => Icons.image_outlined,
    FileKind.pdf => Icons.picture_as_pdf_outlined,
    FileKind.archive => Icons.archive_outlined,
    FileKind.other => Icons.insert_drive_file_outlined,
  };
}

const _documentExtensions = {'doc', 'docx', 'odt', 'rtf', 'txt', 'md'};
const _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'heic',
  'bmp',
  'svg',
};
const _archiveExtensions = {'zip', 'rar', '7z', 'tar', 'gz', 'tgz'};

/// The kind of a file, worked out from its extension. A folder cannot be told
/// from its name, so this never returns [FileKind.folder].
FileKind fileKindForName(String name) {
  final extension = fileExtension(name);
  if (extension == 'pdf') return FileKind.pdf;
  if (_documentExtensions.contains(extension)) return FileKind.document;
  if (_imageExtensions.contains(extension)) return FileKind.image;
  if (_archiveExtensions.contains(extension)) return FileKind.archive;
  return FileKind.other;
}
