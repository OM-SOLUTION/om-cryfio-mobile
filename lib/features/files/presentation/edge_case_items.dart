import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/file_kind.dart';

/// Twenty different people, for the most people an item can be shared with in
/// the samples.
const crowd = [
  Collaborator('Amina Rahal'),
  Collaborator('Youssef Berrada'),
  Collaborator('Sara Idrissi'),
  Collaborator('Omar Tazi'),
  Collaborator('Lina Chraibi'),
  Collaborator('Karim Alaoui'),
  Collaborator('Nadia Benjelloun'),
  Collaborator('Hamza Fassi'),
  Collaborator('Salma Lahlou'),
  Collaborator('Yassine Bennani'),
  Collaborator('Imane Tahiri'),
  Collaborator('Reda Squalli'),
  Collaborator('Meryem Ouazzani'),
  Collaborator('Anas Kettani'),
  Collaborator('Houda Berrada'),
  Collaborator('Mehdi Cherkaoui'),
  Collaborator('Zineb Sebti'),
  Collaborator('Ayoub Mansouri'),
  Collaborator('Khadija Amrani'),
  Collaborator('Tarik Zniber'),
];

/// The longest file name the backend takes: 255 characters, with spaces to wrap
/// at and an extension at the end.
final longestName = () {
  const unit = 'A very long name that keeps on going ';
  // 251 characters of words, then ".zip": 255 in all.
  return '${(unit * 8).substring(0, 251)}.zip';
}();

/// A long name with no space anywhere in it, which nothing can wrap.
const unbreakableName =
    'ThisFileNameHasNoSpacesAtAllAndJustKeepsGoingAndGoingAndGoing'
    'AndGoingAndGoingAndGoingAndGoingAndGoing.pdf';

FileActivity _did(FileActivityKind kind, Duration ago) =>
    FileActivity(kind, DateTime.now().subtract(ago));

/// Items at the smallest and largest of everything the Files screens show, so
/// the layouts can be seen, and tested, at their limits:
///
/// - names of one character up to the 255 the backend takes, with and without
///   spaces, accents and right-to-left letters;
/// - extensions of none, one letter, twelve (the most that counts) and thirteen
///   (too long, so it counts as none);
/// - sizes from empty to the 2 GiB largest upload, and folders from empty to
///   thousands of files;
/// - nobody else with access up to twenty people;
/// - an action that just happened, and one from years ago.
List<FileItem> edgeCaseItems() => [
  // Smallest.
  FileItem.file(
    name: 'a',
    details: '0 B',
    activity: _did(FileActivityKind.uploaded, Duration.zero),
  ),
  FileItem.file(
    name: 'x.c',
    details: '1 B',
    activity: _did(FileActivityKind.renamed, const Duration(minutes: 1)),
    collaborators: const [Collaborator('Al')],
  ),
  FileItem(
    name: 'Empty',
    kind: FileKind.folder,
    details: '0 files',
    activity: _did(FileActivityKind.moved, const Duration(seconds: 30)),
  ),
  FileItem(
    name: 'Single',
    kind: FileKind.folder,
    details: '1 file',
    activity: _did(FileActivityKind.uploaded, const Duration(hours: 5)),
    collaborators: const [Collaborator('Omar')],
  ),
  // Largest.
  FileItem.file(
    name: longestName,
    details: '2.0 GB',
    activity: _did(FileActivityKind.edited, const Duration(days: 3)),
    collaborators: crowd,
  ),
  FileItem.file(
    name: unbreakableName,
    details: '2.0 GB',
    activity: _did(FileActivityKind.shared, const Duration(days: 400)),
    collaborators: crowd.take(4).toList(),
  ),
  FileItem(
    name: 'Everything we ever kept for the project, in one folder',
    kind: FileKind.folder,
    details: '9,999 files',
    activity: _did(FileActivityKind.downloaded, const Duration(days: 2000)),
    collaborators: crowd.take(3).toList(),
  ),
  // Extensions.
  FileItem.file(
    name: 'twelve.abcdefghijkl',
    details: '12 KB',
    activity: _did(FileActivityKind.edited, const Duration(hours: 1)),
  ),
  FileItem.file(
    name: 'thirteen.abcdefghijklm',
    details: '13 KB',
    activity: _did(FileActivityKind.edited, const Duration(hours: 2)),
  ),
  FileItem.file(
    name: 'No extension at all',
    details: '999 B',
    activity: _did(FileActivityKind.edited, const Duration(hours: 3)),
  ),
  // Accents and right-to-left letters.
  FileItem.file(
    name: 'Résumé final de l’été 2026.pdf',
    details: '210 KB',
    activity: _did(FileActivityKind.edited, const Duration(days: 4)),
  ),
  FileItem.file(
    name: 'مستند مهم جدا.docx',
    details: '64 KB',
    activity: _did(FileActivityKind.edited, const Duration(days: 5)),
    collaborators: const [Collaborator('منى علي')],
  ),
  // The number of people either side of what fits: 1, 2 and 3 circles are
  // shown in full, and four or more end with "+N".
  FileItem.file(
    name: 'Shared with two.txt',
    details: '3 KB',
    activity: _did(FileActivityKind.shared, const Duration(days: 6)),
    collaborators: crowd.take(2).toList(),
  ),
  FileItem.file(
    name: 'Shared with three.txt',
    details: '3 KB',
    activity: _did(FileActivityKind.shared, const Duration(days: 7)),
    collaborators: crowd.take(3).toList(),
  ),
];
