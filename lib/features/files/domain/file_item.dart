import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/file_kind.dart';

/// A file or folder as the Files screens show it.
class FileItem {
  const FileItem({
    required this.name,
    required this.kind,
    required this.details,
    this.activity,
    this.collaborators = const [],
    this.favorite = false,
  });

  /// A file (not a folder), whose kind is worked out from its name.
  factory FileItem.file({
    required String name,
    required String details,
    FileActivity? activity,
    List<Collaborator> collaborators = const [],
    bool favorite = false,
  }) {
    return FileItem(
      name: name,
      kind: fileKindForName(name),
      details: details,
      activity: activity,
      collaborators: collaborators,
      favorite: favorite,
    );
  }

  final String name;
  final FileKind kind;

  /// A file's size such as "1.2 MB", or "12 files" for a folder.
  final String details;

  /// The last thing done to it and when, if known.
  final FileActivity? activity;

  /// The people who have some kind of access, apart from the owner.
  final List<Collaborator> collaborators;
  final bool favorite;

  /// The same item with other people having access.
  FileItem copyWith({List<Collaborator>? collaborators}) => FileItem(
    name: name,
    kind: kind,
    details: details,
    activity: activity,
    collaborators: collaborators ?? this.collaborators,
    favorite: favorite,
  );

  bool get isFolder => kind == FileKind.folder;
  bool get shared => collaborators.isNotEmpty;
}
