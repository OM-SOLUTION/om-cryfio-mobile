import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/file_kind.dart';
import 'package:om_cryfio/ui/theme/file_type_colors.dart';

void main() {
  group('fileKindForName', () {
    test('recognizes the known families', () {
      expect(fileKindForName('Contract.pdf'), FileKind.pdf);
      expect(fileKindForName('Report.docx'), FileKind.document);
      expect(fileKindForName('Notes.txt'), FileKind.document);
      expect(fileKindForName('Holiday.jpg'), FileKind.image);
      expect(fileKindForName('Backup.zip'), FileKind.archive);
    });

    test('ignores capitals', () {
      expect(fileKindForName('PHOTO.JPG'), FileKind.image);
      expect(fileKindForName('Manual.PDF'), FileKind.pdf);
    });

    test('treats everything else as other', () {
      expect(fileKindForName('Budget.xlsx'), FileKind.other);
      expect(fileKindForName('Setup.apk'), FileKind.other);
      expect(fileKindForName('README'), FileKind.other);
      expect(fileKindForName('.gitignore'), FileKind.other);
    });

    test('goes by the last extension', () {
      expect(fileKindForName('backup.tar.gz'), FileKind.archive);
      expect(fileKindForName('photo.jpg.exe'), FileKind.other);
    });
  });

  group('FileItem.file', () {
    test('works out its kind from its name', () {
      final item = FileItem.file(name: 'Contract.pdf', details: '1 MB');

      expect(item.kind, FileKind.pdf);
      expect(item.isFolder, isFalse);
    });

    test('is shared when it has collaborators', () {
      final alone = FileItem.file(name: 'a.xyz', details: '');
      final shared = FileItem.file(
        name: 'a.xyz',
        details: '',
        collaborators: const [Collaborator('Amina Rahal')],
        favorite: true,
      );

      expect(alone.shared, isFalse);
      expect(shared.shared, isTrue);
      expect(shared.favorite, isTrue);
    });
  });

  group('FileTypeColors', () {
    test('gives every kind but other a color', () {
      for (final kind in FileKind.values) {
        expect(
          FileTypeColors.forKind(kind),
          kind == FileKind.other ? isNull : isNotNull,
          reason: kind.name,
        );
      }
    });

    test('the known kinds look different from each other', () {
      final colors = {
        for (final kind in FileKind.values) ?FileTypeColors.forKind(kind),
      };

      expect(colors.length, FileKind.values.length - 1);
    });

    test('an extension always gets the same hue, whatever its case', () {
      expect(
        FileTypeColors.hueForExtension('xyz'),
        FileTypeColors.hueForExtension('xyz'),
      );
      expect(
        FileTypeColors.hueForExtension('XYZ'),
        FileTypeColors.hueForExtension('xyz'),
      );
    });

    test('a hue is always one of the named colors', () {
      for (final extension in ['a', 'xyz', 'torrent', 'verylongextension']) {
        final hue = FileTypeColors.hueForExtension(extension);
        expect(FileIconColors.all.values, contains(hue));
      }
    });

    test('common extensions use every named color, none more than twice', () {
      const extensions = [
        'xyz',
        'abc',
        'json',
        'apk',
        'xlsx',
        'pptx',
        'mkv',
        'flac',
        'torrent',
        'iso',
        'sqlite3',
        'csv',
        'html',
        'py',
        'exe',
        'mp3',
        'psd',
        'epub',
      ];
      final counts = <double, int>{};
      for (final extension in extensions) {
        counts.update(
          FileTypeColors.hueForExtension(extension),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      expect(counts.length, FileIconColors.all.length);
      expect(counts.values.every((count) => count <= 2), isTrue);
    });

    test('the sample files of the Files screen each get their own color', () {
      const extensions = [
        'xlsx',
        'pptx',
        'apk',
        'json',
        'mkv',
        'flac',
        'torrent',
        'iso',
        'sqlite3',
      ];
      final hues = {
        for (final extension in extensions)
          FileTypeColors.hueForExtension(extension),
      };

      expect(hues.length, extensions.length);
    });

    test('forFile uses the kind color, else the extension color', () {
      expect(FileTypeColors.forFile(FileKind.pdf, 'a.pdf'), FileTypeColors.pdf);
      expect(
        FileTypeColors.forFile(FileKind.other, 'a.xyz'),
        FileTypeColors.forExtension('xyz'),
      );
      expect(FileTypeColors.forFile(FileKind.other, 'README'), isNull);
    });

    test('icons are brightened on a dark theme only', () {
      const color = FileTypeColors.pdf;

      expect(FileTypeColors.iconFor(color, Brightness.light), color);
      expect(FileTypeColors.iconFor(color, Brightness.dark), isNot(color));
    });
  });
}
