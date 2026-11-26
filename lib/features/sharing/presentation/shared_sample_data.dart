import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/features/files/presentation/edge_case_items.dart';
import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/file_kind.dart';

// Static rows for layout work; replaced by real data later. Times are relative
// to when they are asked for, so "Today" and the invitation expiry always show.
const _amina = Collaborator('Amina Rahal');
const _youssef = Collaborator('Youssef Berrada');
const _sara = Collaborator('Sara Idrissi');
const _omar = Collaborator('Omar Tazi');
const _lina = Collaborator('Lina Chraibi');

DateTime _ago(Duration ago) => DateTime.now().subtract(ago);

FileActivity _did(FileActivityKind kind, Duration ago) =>
    FileActivity(kind, _ago(ago));

/// Items other people shared with the user.
List<SharedWithMe> sampleSharedWithMe() => [
  SharedWithMe(
    item: FileItem.file(
      name: 'Contract.pdf',
      details: '1.2 MB',
      activity: _did(FileActivityKind.edited, const Duration(hours: 2)),
    ),
    sharedBy: _amina,
    role: ShareRole.editor,
  ),
  SharedWithMe(
    item: FileItem(
      name: 'Family photos',
      kind: FileKind.folder,
      details: '48 files',
      activity: _did(FileActivityKind.uploaded, const Duration(days: 1)),
    ),
    sharedBy: _omar,
    role: ShareRole.viewer,
  ),
  SharedWithMe(
    item: FileItem.file(
      name: 'Budget.xlsx',
      details: '54 KB',
      activity: _did(FileActivityKind.edited, const Duration(days: 3)),
    ),
    sharedBy: _sara,
    role: ShareRole.editor,
  ),
  SharedWithMe(
    item: FileItem.file(
      name: 'Project.zip',
      details: '220 MB',
      activity: _did(FileActivityKind.uploaded, const Duration(days: 12)),
    ),
    sharedBy: _lina,
    role: ShareRole.viewer,
  ),
];

/// Items the user owns that other people can reach.
List<SharedByMe> sampleSharedByMe() => [
  SharedByMe(
    item: FileItem(
      name: 'Documents',
      kind: FileKind.folder,
      details: '12 files',
      activity: _did(FileActivityKind.shared, const Duration(minutes: 25)),
      collaborators: const [_amina, _youssef],
    ),
    people: const [
      SharedPerson(_amina, role: ShareRole.editor, trust: KeyTrust.verified),
      SharedPerson(_youssef),
    ],
    pending: [
      PendingInvite(_lina, ShareRole.viewer, _ago(const Duration(days: 2))),
    ],
  ),
  SharedByMe(
    item: FileItem.file(
      name: 'Holiday.jpg',
      details: '3.4 MB',
      activity: _did(FileActivityKind.shared, const Duration(days: 1)),
      collaborators: const [_lina],
    ),
    people: const [SharedPerson(_lina, trust: KeyTrust.verified)],
  ),
  SharedByMe(
    item: FileItem.file(
      name: 'Slides.pptx',
      details: '12 MB',
      activity: _did(FileActivityKind.edited, const Duration(days: 8)),
      collaborators: const [_amina, _lina, _sara, _omar],
    ),
    people: const [
      SharedPerson(_amina, role: ShareRole.editor, trust: KeyTrust.verified),
      SharedPerson(_lina),
      SharedPerson(_sara, role: ShareRole.editor),
      SharedPerson(_omar),
    ],
  ),
];

/// Invitations the user received: one fresh, one close to its end, one over.
List<Invitation> sampleInvitations() => [
  Invitation(
    from: _amina,
    itemName: 'Q4 report.pdf',
    itemKind: FileKind.pdf,
    role: ShareRole.editor,
    sentAt: _ago(const Duration(days: 1)),
  ),
  Invitation(
    from: _omar,
    itemName: 'Design files',
    itemKind: FileKind.folder,
    role: ShareRole.viewer,
    sentAt: _ago(const Duration(days: 5, hours: 6)),
  ),
  Invitation(
    from: _sara,
    itemName: 'Old notes.txt',
    itemKind: FileKind.document,
    role: ShareRole.viewer,
    sentAt: _ago(const Duration(days: 9)),
  ),
];

const _longSharer = Collaborator(
  'Maximilian Alexander von Hohenzollern-Sigmaringen',
);

/// Shared with me, at the smallest and largest: a one-character name, the
/// longest name with the longest sharer's name, and the biggest folder.
List<SharedWithMe> edgeCaseSharedWithMe() => [
  SharedWithMe(
    item: FileItem.file(
      name: 'a',
      details: '0 B',
      activity: _did(FileActivityKind.uploaded, Duration.zero),
    ),
    sharedBy: const Collaborator('Al'),
    role: ShareRole.viewer,
  ),
  SharedWithMe(
    item: FileItem.file(
      name: longestName,
      details: '2.0 GB',
      activity: _did(FileActivityKind.edited, const Duration(days: 400)),
    ),
    sharedBy: _longSharer,
    role: ShareRole.editor,
  ),
  SharedWithMe(
    item: FileItem(
      name: 'Everything we ever kept for the project, in one folder',
      kind: FileKind.folder,
      details: '9,999 files',
      activity: _did(FileActivityKind.shared, const Duration(days: 2000)),
    ),
    sharedBy: _omar,
    role: ShareRole.viewer,
  ),
];

// People with an invitation still open, none of them in `crowd`.
const _inviteeNames = [
  'Rachid Benkirane',
  'Soukaina Daoudi',
  'Walid Chakir',
  'Ghita Moussaoui',
  'Bilal Erraji',
  'Hajar Lamrani',
];

/// Shared by me, at the smallest and largest: one person, and twenty with six
/// invitations still open (so the access sheet has to scroll).
List<SharedByMe> edgeCaseSharedByMe() => [
  SharedByMe(
    item: FileItem.file(
      name: 'Solo.txt',
      details: '1 B',
      activity: _did(FileActivityKind.shared, Duration.zero),
      collaborators: const [Collaborator('Al')],
    ),
    people: const [SharedPerson(Collaborator('Al'))],
  ),
  SharedByMe(
    item: FileItem(
      name: 'Everyone',
      kind: FileKind.folder,
      details: '9,999 files',
      activity: _did(FileActivityKind.shared, const Duration(days: 30)),
      collaborators: crowd,
    ),
    people: [
      for (final (index, person) in crowd.indexed)
        SharedPerson(
          person,
          role: index.isEven ? ShareRole.editor : ShareRole.viewer,
          trust: index % 3 == 0 ? KeyTrust.verified : KeyTrust.firstUse,
        ),
    ],
    pending: [
      for (final (index, name) in _inviteeNames.indexed)
        PendingInvite(
          Collaborator(name),
          index.isEven ? ShareRole.viewer : ShareRole.editor,
          // From just now to nearly the end of the seven days.
          _ago(Duration(days: index, hours: index == 0 ? 0 : 20)),
        ),
    ],
  ),
  SharedByMe(
    item: FileItem.file(
      name: longestName,
      details: '2.0 GB',
      activity: _did(FileActivityKind.edited, const Duration(days: 400)),
      collaborators: crowd.take(4).toList(),
    ),
    people: [for (final person in crowd.take(4)) SharedPerson(person)],
  ),
];

/// Invitations at the smallest and largest: one just sent (the full seven days
/// left), one with a few hours left, one with the longest name from the longest
/// sender, and one that ended long ago.
List<Invitation> edgeCaseInvitations() => [
  Invitation(
    from: const Collaborator('Al'),
    itemName: 'a',
    itemKind: FileKind.other,
    role: ShareRole.viewer,
    sentAt: _ago(Duration.zero),
  ),
  Invitation(
    from: _lina,
    itemName: 'Almost over.pdf',
    itemKind: FileKind.pdf,
    role: ShareRole.editor,
    sentAt: _ago(const Duration(days: 6, hours: 20)),
  ),
  Invitation(
    from: _longSharer,
    itemName: longestName,
    itemKind: FileKind.archive,
    role: ShareRole.viewer,
    sentAt: _ago(const Duration(days: 3)),
  ),
  Invitation(
    from: _youssef,
    itemName: 'Long gone.docx',
    itemKind: FileKind.document,
    role: ShareRole.editor,
    sentAt: _ago(const Duration(days: 60)),
  ),
];
