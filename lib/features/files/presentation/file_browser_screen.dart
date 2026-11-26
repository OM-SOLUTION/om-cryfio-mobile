import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:om_cryfio/features/files/application/file_view_mode.dart';
import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/features/files/presentation/edge_case_items.dart';
import 'package:om_cryfio/features/files/presentation/file_action_menu.dart';
import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/coming_soon.dart';
import 'package:om_cryfio/ui/widgets/file_grid_tile.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/folder.dart';
import 'package:om_cryfio/ui/widgets/pill_surface.dart';
import 'package:om_cryfio/ui/widgets/search_field.dart';
import 'package:om_cryfio/ui/widgets/view_mode_toggle.dart';

// Static rows for layout work; replaced by real data later. A file's kind comes
// from its name, so the many extensions below show how each type looks: known
// ones get their kind's color, anything else gets the generic icon with its own
// extension and color. Times are relative to when the app starts, so "Today"
// and "Yesterday" always show.
const _amina = Collaborator('Amina Rahal');
const _youssef = Collaborator('Youssef Berrada');
const _sara = Collaborator('Sara Idrissi');
const _omar = Collaborator('Omar Tazi');
const _lina = Collaborator('Lina Chraibi');

FileActivity _did(FileActivityKind kind, Duration ago) =>
    FileActivity(kind, DateTime.now().subtract(ago));

final _items = [
  FileItem(
    name: 'Documents',
    kind: FileKind.folder,
    details: '12 files',
    activity: _did(FileActivityKind.edited, const Duration(minutes: 25)),
    collaborators: const [_amina, _youssef],
  ),
  FileItem(
    name: 'Photos',
    kind: FileKind.folder,
    details: '48 files',
    activity: _did(FileActivityKind.shared, const Duration(days: 1, hours: 2)),
    collaborators: const [_sara, _omar, _lina, _amina, _youssef],
  ),
  FileItem.file(
    name: 'Contract.pdf',
    details: '1.2 MB',
    activity: _did(FileActivityKind.edited, const Duration(minutes: 40)),
    collaborators: const [_amina, _omar, _sara],
  ),
  FileItem.file(
    name: 'Holiday.jpg',
    details: '3.4 MB',
    activity: _did(FileActivityKind.shared, const Duration(days: 1)),
    collaborators: const [_lina],
  ),
  FileItem.file(
    name: 'Notes.txt',
    details: '4 KB',
    activity: _did(FileActivityKind.renamed, const Duration(days: 3)),
    favorite: true,
  ),
  FileItem.file(
    name: 'Backup.zip',
    details: '220 MB',
    activity: _did(FileActivityKind.uploaded, const Duration(days: 9)),
  ),
  FileItem.file(
    name: 'Report.docx',
    details: '86 KB',
    activity: _did(FileActivityKind.edited, const Duration(hours: 3)),
    collaborators: const [_youssef, _sara],
  ),
  FileItem.file(
    name: 'Budget.xlsx',
    details: '54 KB',
    activity: _did(FileActivityKind.edited, const Duration(days: 1, hours: 5)),
    collaborators: const [_omar],
  ),
  FileItem.file(
    name: 'Slides.pptx',
    details: '12 MB',
    activity: _did(FileActivityKind.moved, const Duration(days: 8)),
    collaborators: const [_amina, _lina, _sara, _omar],
  ),
  FileItem.file(
    name: 'Setup.apk',
    details: '48 MB',
    activity: _did(FileActivityKind.downloaded, const Duration(days: 15)),
  ),
  FileItem.file(
    name: 'config.json',
    details: '2 KB',
    activity: _did(FileActivityKind.edited, const Duration(hours: 1)),
  ),
  FileItem.file(
    name: 'Movie.mkv',
    details: '1.4 GB',
    activity: _did(FileActivityKind.uploaded, const Duration(days: 40)),
    collaborators: const [_youssef],
  ),
  FileItem.file(
    name: 'Song.flac',
    details: '32 MB',
    activity: _did(FileActivityKind.downloaded, const Duration(days: 33)),
  ),
  FileItem.file(
    name: 'ubuntu.torrent',
    details: '18 KB',
    activity: _did(FileActivityKind.uploaded, const Duration(days: 4)),
  ),
  FileItem.file(
    name: 'Disk.iso',
    details: '4.7 GB',
    activity: _did(FileActivityKind.uploaded, const Duration(days: 45)),
  ),
  FileItem.file(
    name: 'Data.sqlite3',
    details: '2.1 MB',
    activity: _did(FileActivityKind.edited, const Duration(days: 1, hours: 8)),
    collaborators: const [_sara, _amina],
  ),
  FileItem.file(
    name: 'README',
    details: '1 KB',
    activity: _did(FileActivityKind.edited, const Duration(days: 10)),
  ),
  // After the normal samples: the smallest and largest of everything, to see
  // the layouts at their limits.
  ...edgeCaseItems(),
];

// The grid's narrowest tile. Phones get one tile per line, which makes a tile
// close to square; wider screens fit more. Lower it for more columns.
const _gridMinTileWidth = 340.0;

// Keeps the last row clear of the floating action button.
const _bottomClearance = 96.0;

// The search strip floats over the files, so they start below its height.
const _stripPaddingTop = AppSpacing.sm;
const _stripPaddingBottom = AppSpacing.md;
const _stripHeight =
    _stripPaddingTop + PillSurface.height + _stripPaddingBottom;

// How far down the strip (0 to 1) its background stays fully opaque before it
// starts to fade. Raise it to push the visible background lower.
const _stripSolidUntil = 0.45;

class FileBrowserScreen extends ConsumerWidget {
  const FileBrowserScreen({super.key});

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload file'),
              onTap: () {
                Navigator.pop(sheetContext);
                showComingSoon(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New folder'),
              onTap: () {
                Navigator.pop(sheetContext);
                showComingSoon(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(fileViewModeProvider);
    void soon() => showComingSoon(context);
    // The page's own color, so the strip melts into the background.
    final stripColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(title: const Text('My files')),
      body: Stack(
        children: [
          // The files fill the whole body and start below the search strip,
          // so they scroll up underneath it.
          Positioned.fill(
            child: switch (mode) {
              ViewMode.list => _ListBody(onOpen: soon),
              ViewMode.grid => _GridBody(onOpen: soon),
            },
          ),
          // The search bar, and next to it the list/grid switch, on a strip
          // that fades from the page color at the top to transparent.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [stripColor, stripColor.withValues(alpha: 0)],
                  stops: const [_stripSolidUntil, 1],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  _stripPaddingTop,
                  AppSpacing.md,
                  _stripPaddingBottom,
                ),
                child: Row(
                  children: [
                    Expanded(child: SearchField(onFilter: soon)),
                    const SizedBox(width: AppSpacing.sm),
                    ViewModeToggle(
                      mode: mode,
                      onChanged: ref.read(fileViewModeProvider.notifier).set,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        top: _stripHeight,
        bottom: _bottomClearance,
      ),
      children: [
        for (final item in _items)
          FileListTile(
            name: item.name,
            kind: item.kind,
            details: item.details,
            activity: item.activity,
            collaborators: item.collaborators,
            onTap: onOpen,
            menu: FileActionMenuButton(item: item),
          ),
      ],
    );
  }
}

class _GridBody extends ConsumerWidget {
  const _GridBody({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final columns = math.max(
          1,
          (constraints.maxWidth / _gridMinTileWidth).floor(),
        );
        final tileWidth =
            (constraints.maxWidth - 2 * gap - (columns - 1) * gap) / columns;

        // Every tile is a padded card: a folder holds just the folder picture,
        // a file a picture over a row with its name. The name grows with the
        // user's text size, so the file height has to as well.
        const inset = FileGridTile.inset;
        final scaler = MediaQuery.textScalerOf(context);
        final picture = (tileWidth - 2 * inset) / Folder.aspectRatio;
        final folderHeight = 2 * inset + picture;
        final filePicture =
            (tileWidth - 2 * inset) / FileGridTile.filePictureAspect;
        final fileHeight =
            2 * inset +
            filePicture +
            FileGridTile.gap +
            FileGridTile.nameRowHeight(scaler);

        final folders = [
          for (final item in _items)
            if (item.isFolder) item,
        ];
        final files = [
          for (final item in _items)
            if (!item.isFolder) item,
        ];

        Widget grid(List<FileItem> items, double height) {
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: height,
            ),
            delegate: SliverChildBuilderDelegate(childCount: items.length, (
              context,
              index,
            ) {
              final item = items[index];
              return FileGridTile(
                name: item.name,
                kind: item.kind,
                details: item.details,
                activity: item.activity,
                collaborators: item.collaborators,
                onTap: onOpen,
                onLongPress: (position) {
                  HapticFeedback.mediumImpact();
                  showFileActionMenu(context, ref, item, position & Size.zero);
                },
                // Files have a ⋮ button next to the name; folders open the
                // menu when held.
                menu: item.isFolder ? null : FileActionMenuButton(item: item),
              );
            }),
          );
        }

        return CustomScrollView(
          slivers: [
            if (folders.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(gap, _stripHeight, gap, 0),
                sliver: grid(folders, folderHeight),
              ),
            if (files.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gap,
                  folders.isEmpty ? _stripHeight : gap,
                  gap,
                  _bottomClearance,
                ),
                sliver: grid(files, fileHeight),
              ),
          ],
        );
      },
    );
  }
}
