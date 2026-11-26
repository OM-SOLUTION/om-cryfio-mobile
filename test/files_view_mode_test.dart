import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/app/app.dart';
import 'package:om_cryfio/ui/widgets/file_grid_tile.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/search_field.dart';
import 'package:om_cryfio/ui/widgets/view_mode_toggle.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

void main() {
  // The scrolling text never stops, which would keep the screen from settling.
  setUpAll(() => MarqueeText.enabled = false);

  Future<void> openFiles(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OmCryfioApp()));
    await tester.pumpAndSettle();
  }

  Future<void> chooseView(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the search bar has its own line, with the view switch next to it',
    (tester) async {
      await openFiles(tester);

      final search = tester.getRect(find.byType(SearchField));
      final toggle = tester.getRect(find.byType(ViewModeToggle));
      final title = tester.getRect(find.text('My files'));

      expect(search.top, greaterThan(title.bottom));
      expect(toggle.left, greaterThanOrEqualTo(search.right));
      expect((toggle.center.dy - search.center.dy).abs(), lessThan(1));
      // The old app bar buttons are gone.
      expect(find.byTooltip('Search'), findsNothing);
      expect(find.byTooltip('Filter'), findsOneWidget);
    },
  );

  testWidgets('the files start below the search bar and scroll under it', (
    tester,
  ) async {
    await openFiles(tester);

    final search = tester.getRect(find.byType(SearchField));
    final first = find.byType(FileListTile).first;
    expect(tester.getRect(first).top, greaterThanOrEqualTo(search.bottom));

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Rows now pass behind the bar instead of stopping under it.
    final tops = [
      for (final tile in tester.widgetList(find.byType(FileListTile)))
        tester.getRect(find.byWidget(tile)).top,
    ];
    expect(tops.any((top) => top < search.bottom), isTrue);
  });

  testWidgets('the search bar and switch fit a small phone at 2x text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await openFiles(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(SearchField), findsOneWidget);
  });

  testWidgets('files start in the list view', (tester) async {
    await openFiles(tester);

    expect(find.byType(FileListTile), findsWidgets);
    expect(find.byType(FileGridTile), findsNothing);
  });

  testWidgets('the toggle switches between list and grid', (tester) async {
    await openFiles(tester);

    await chooseView(tester, 'Grid view');
    expect(find.byType(FileGridTile), findsWidgets);
    expect(find.byType(FileListTile), findsNothing);

    await chooseView(tester, 'List view');
    expect(find.byType(FileListTile), findsWidgets);
    expect(find.byType(FileGridTile), findsNothing);
  });

  testWidgets('the chosen view survives switching tabs', (tester) async {
    await openFiles(tester);
    await chooseView(tester, 'Grid view');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.settings_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.folder_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FileGridTile), findsWidgets);
  });

  for (final scale in [1.0, 1.3, 1.6]) {
    testWidgets('no grid tile overflows at ${scale}x text', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await openFiles(tester);
      await chooseView(tester, 'Grid view');
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the grid fits a small phone at 2x text', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await openFiles(tester);
    await chooseView(tester, 'Grid view');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // A layout overflow would have thrown while pumping.
    expect(tester.takeException(), isNull);
    expect(find.byType(FileGridTile), findsWidgets);
  });
}
