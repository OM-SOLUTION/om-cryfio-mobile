import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/app/app.dart';
import 'package:om_cryfio/features/files/application/file_actions.dart';
import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/ui/widgets/anchored_menu.dart';
import 'package:om_cryfio/ui/widgets/file_grid_tile.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

/// Records which action ran on which item, instead of showing "Coming soon".
class _SpyActions extends FileActions {
  final calls = <String>[];

  void _log(String name, FileItem item) => calls.add('$name:${item.name}');

  @override
  void download(BuildContext context, FileItem item) => _log('download', item);
  @override
  void share(BuildContext context, FileItem item) => _log('share', item);
  @override
  void copy(BuildContext context, FileItem item) => _log('copy', item);
  @override
  void rename(BuildContext context, FileItem item) => _log('rename', item);
  @override
  void move(BuildContext context, FileItem item) => _log('move', item);
  @override
  void uploadNewVersion(BuildContext context, FileItem item) =>
      _log('uploadNewVersion', item);
  @override
  void showVersionHistory(BuildContext context, FileItem item) =>
      _log('showVersionHistory', item);
  @override
  void toggleFavorite(BuildContext context, FileItem item) =>
      _log('toggleFavorite', item);
  @override
  void showDetails(BuildContext context, FileItem item) =>
      _log('showDetails', item);
  @override
  void transferOwnership(BuildContext context, FileItem item) =>
      _log('transferOwnership', item);
  @override
  void moveToRecycleBin(BuildContext context, FileItem item) =>
      _log('moveToRecycleBin', item);
}

void main() {
  // The scrolling text never stops, which would keep the screen from settling.
  setUpAll(() => MarqueeText.enabled = false);

  late _SpyActions spy;

  setUp(() => spy = _SpyActions());

  /// Opens the Files screen on a tall phone, so a long menu fits.
  Future<void> openFiles(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [fileActionsProvider.overrideWithValue(spy)],
        child: const OmCryfioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openRowMenu(WidgetTester tester, String name) async {
    await tester.tap(find.byTooltip('More options for $name'));
    await tester.pumpAndSettle();
  }

  Future<void> switchToGrid(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Grid view'));
    await tester.pumpAndSettle();
  }

  Finder menuItems() => find.descendant(
    of: find.byType(AnchoredMenu<FileAction>),
    matching: find.byType(InkWell),
  );

  testWidgets('every action reaches its own method', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    const item = FileItem(name: 'x', kind: FileKind.pdf, details: '');

    for (final action in FileAction.values) {
      spy.run(context, action, item);
    }

    expect(spy.calls, [
      for (final action in FileAction.values) '${action.name}:x',
    ]);
  });

  group('menu animation', () {
    Finder menu() => find.byType(AnchoredMenu<FileAction>);

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: menu(), matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    double scale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find
              .ancestor(of: menu(), matching: find.byType(ScaleTransition))
              .first,
        )
        .scale
        .value;

    testWidgets('fades in and grows a little, then settles', (tester) async {
      await openFiles(tester);

      await tester.tap(find.byTooltip('More options for Documents'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // Partway through: visible but not finished.
      expect(opacity(tester), allOf(greaterThan(0), lessThan(1)));
      expect(scale(tester), allOf(greaterThan(0.9), lessThan(1)));

      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), 1);
      expect(scale(tester), 1);
    });

    testWidgets('is full size from the first frame, so nothing slides', (
      tester,
    ) async {
      await openFiles(tester);

      await tester.tap(find.byTooltip('More options for Contract.pdf'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final early = tester.getSize(menu());
      await tester.pumpAndSettle();

      // The menu is laid out at its final size at once. Only its opacity and
      // scale change, so there is no growth from the top.
      expect(tester.getSize(menu()), early);
    });

    testWidgets('a held tile opens its menu at the finger', (tester) async {
      await openFiles(tester);
      await switchToGrid(tester);
      final tile = find.byType(FileGridTile).first;
      final finger = tester.getCenter(tile);

      await tester.longPress(tile);
      await tester.pumpAndSettle();

      // The tile is in the upper left, so the menu hangs down from the finger.
      // It may shift sideways to stay on screen, so the finger only has to be
      // somewhere along its top edge.
      final rect = tester.getRect(menu());
      expect(rect.top, closeTo(finger.dy, 1));
      expect(rect.left, lessThanOrEqualTo(finger.dx));
      expect(rect.right, greaterThanOrEqualTo(finger.dx));
    });

    testWidgets('a menu near the bottom corner opens up and to the left', (
      tester,
    ) async {
      await openFiles(tester);
      await switchToGrid(tester);
      final tile = find.widgetWithText(FileGridTile, 'Backup.zip');
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.longPress(tile);
      await tester.pumpAndSettle();

      final rect = tester.getRect(menu());
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(rect.left, greaterThanOrEqualTo(8));
      expect(rect.top, greaterThanOrEqualTo(8));
      expect(rect.right, lessThanOrEqualTo(screen.width - 8));
      expect(rect.bottom, lessThanOrEqualTo(screen.height - 8));
    });
  });

  testWidgets('the ⋮ of a list row sits close to the screen edge', (
    tester,
  ) async {
    await openFiles(tester);

    final button = tester.getRect(find.byTooltip('More options for Documents'));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    // The button ends 8 from the edge and is 40 wide, so its 24 icon sits 16
    // from the edge, level with the 16 on the left.
    expect(screen.width - button.right, 8);
    expect(button.width, 40);
  });

  group('list row menu', () {
    testWidgets('a file offers all eleven actions', (tester) async {
      await openFiles(tester);
      await openRowMenu(tester, 'Contract.pdf');

      expect(menuItems(), findsNWidgets(11));
      for (final label in [
        'Download',
        'Share…',
        'Copy…',
        'Rename',
        'Move…',
        'Upload new version',
        'Version history',
        'Add to favorites',
        'Details',
        'Transfer ownership…',
        'Move to Recycle Bin',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('a folder leaves out the file-only actions', (tester) async {
      await openFiles(tester);
      await openRowMenu(tester, 'Documents');

      expect(menuItems(), findsNWidgets(7));
      for (final label in [
        'Download',
        'Copy…',
        'Upload new version',
        'Version history',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.text('Share…'), findsOneWidget);
    });

    testWidgets('the favorite entry follows the item', (tester) async {
      await openFiles(tester);

      await openRowMenu(tester, 'Notes.txt');
      expect(find.text('Remove from favorites'), findsOneWidget);
    });

    testWidgets('choosing an action runs it on that item', (tester) async {
      await openFiles(tester);
      await openRowMenu(tester, 'Documents');

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(spy.calls, ['rename:Documents']);
    });

    testWidgets('closing the menu runs nothing', (tester) async {
      await openFiles(tester);
      await openRowMenu(tester, 'Documents');

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(spy.calls, isEmpty);
      expect(menuItems(), findsNothing);
    });
  });

  group('grid tile menu', () {
    testWidgets('holding a folder opens the folder menu', (tester) async {
      await openFiles(tester);
      await switchToGrid(tester);

      await tester.longPress(find.byType(FileGridTile).first);
      await tester.pumpAndSettle();

      expect(menuItems(), findsNWidgets(7));
      await tester.tap(find.text('Share…'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['share:Documents']);
    });

    testWidgets('holding a file opens the file menu', (tester) async {
      await openFiles(tester);
      await switchToGrid(tester);

      final contract = find.widgetWithText(FileGridTile, 'Contract.pdf');
      await tester.scrollUntilVisible(
        contract,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Scrolling stops as soon as an edge shows; bring the whole tile in.
      await tester.ensureVisible(contract);
      await tester.pumpAndSettle();
      await tester.longPress(contract);
      await tester.pumpAndSettle();

      expect(menuItems(), findsNWidgets(11));
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['download:Contract.pdf']);
    });

    testWidgets('the ⋮ next to a file name opens its menu', (tester) async {
      await openFiles(tester);
      await switchToGrid(tester);
      final button = find.byTooltip('More options for Contract.pdf');
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      // It was brought to the top edge, where the search bar floats over it.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 200));
      await tester.pumpAndSettle();

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(menuItems(), findsNWidgets(11));
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['download:Contract.pdf']);
    });

    testWidgets('a folder has no ⋮ button, only the hold', (tester) async {
      await openFiles(tester);
      await switchToGrid(tester);

      expect(find.byTooltip('More options for Documents'), findsNothing);
    });

    testWidgets('a plain tap does not open the menu', (tester) async {
      await openFiles(tester);
      await switchToGrid(tester);

      await tester.tap(find.byType(FileGridTile).first);
      await tester.pump();

      expect(menuItems(), findsNothing);
    });

    testWidgets('screen readers get a long-press action', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFiles(tester);
      await switchToGrid(tester);

      final data = tester
          .getSemantics(find.byType(FileGridTile).first)
          .getSemanticsData();

      expect(data.hasAction(SemanticsAction.longPress), isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  });
}
