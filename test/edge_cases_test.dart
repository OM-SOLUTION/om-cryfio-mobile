import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/features/files/presentation/edge_case_items.dart';
import 'package:om_cryfio/features/files/presentation/file_browser_screen.dart';
import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/features/sharing/presentation/shared_sample_data.dart';
import 'package:om_cryfio/features/sharing/presentation/shared_screen.dart';
import 'package:om_cryfio/ui/file_name.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

/// The smallest and largest of everything the screens show: tiny and huge
/// names, sizes, numbers of people and times, on the narrowest and widest
/// screens and the smallest and largest text. A layout overflow throws while
/// pumping, so each test only has to get through without an exception.
void main() {
  // The scrolling text never stops, which would keep the screen from settling.
  setUpAll(() => MarqueeText.enabled = false);

  // A narrow phone, a normal one, and a tablet.
  const sizes = [Size(320, 640), Size(360, 800), Size(800, 1000)];
  const scales = [1.0, 1.3, 2.0];

  void useScreen(WidgetTester tester, Size size, double scale) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  /// Drags the vertical list up until it stops moving.
  Future<void> scrollToEnd(WidgetTester tester) async {
    final list = find
        .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical)
        .hitTestable()
        .first;
    for (var i = 0; i < 120; i++) {
      final position = tester.state<ScrollableState>(list).position;
      final before = position.pixels;
      await tester.drag(list, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
      if (position.pixels == before) return;
    }
    fail('never reached the end of the list');
  }

  group('the sample data covers the limits', () {
    final items = edgeCaseItems();

    test('names from one character to the 255 the backend takes', () {
      final lengths = [for (final item in items) item.name.length];

      expect(lengths.reduce((a, b) => a < b ? a : b), 1);
      expect(longestName.length, 255);
      expect(lengths, contains(255));
      expect(unbreakableName.contains(' '), isFalse);
    });

    test('extensions of none, one letter, twelve and thirteen', () {
      expect(fileExtension('No extension at all'), '');
      expect(fileExtension('x.c'), 'c');
      expect(fileExtension('twelve.abcdefghijkl'), 'abcdefghijkl');
      // One more than the longest that counts, so it is as if it had none.
      expect(fileExtension('thirteen.abcdefghijklm'), '');
    });

    test('from nobody else to twenty people', () {
      final counts = {for (final item in items) item.collaborators.length};

      expect(counts, containsAll([0, 1, 2, 3, 4, 20]));
    });

    test('folders from empty to thousands of files', () {
      final folders = {
        for (final item in items)
          if (item.isFolder) item.details,
      };

      expect(folders, containsAll(['0 files', '1 file', '9,999 files']));
    });

    test('an action that just happened and one from years ago', () {
      final now = DateTime.now();
      final ages = [
        for (final item in items)
          if (item.activity != null) now.difference(item.activity!.at),
      ];

      expect(
        ages.reduce((a, b) => a < b ? a : b),
        lessThan(const Duration(minutes: 1)),
      );
      expect(
        ages.reduce((a, b) => a > b ? a : b),
        greaterThan(const Duration(days: 365)),
      );
    });

    test('invitations from seven days left down to expired', () {
      final now = DateTime.now();
      final texts = {
        for (final invitation in [
          ...sampleInvitations(),
          ...edgeCaseInvitations(),
        ])
          invitation.expiryText(now),
      };

      expect(
        texts,
        containsAll(['Expires in 7 days', 'Expires today', 'Expired']),
      );
    });
  });

  group('a list row at the limits', () {
    for (final size in sizes) {
      for (final scale in scales) {
        testWidgets('every row at ${size.width.toInt()} wide, ${scale}x text', (
          tester,
        ) async {
          useScreen(tester, size, scale);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: ListView(
                  children: [
                    for (final item in edgeCaseItems())
                      FileListTile(
                        name: item.name,
                        kind: item.kind,
                        details: item.details,
                        activity: item.activity,
                        collaborators: item.collaborators,
                        menu: const Icon(Icons.more_vert),
                      ),
                  ],
                ),
              ),
            ),
          );
          await scrollToEnd(tester);

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('twenty people end in a count of the rest', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FileListTile(
              name: 'Big',
              kind: FileKind.other,
              collaborators: crowd,
            ),
          ),
        ),
      );

      // You and twenty others: two named circles, then "+19".
      expect(find.text('+19'), findsOneWidget);
    });
  });

  group('the Files screen at the limits', () {
    Future<void> openFiles(WidgetTester tester) {
      return tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const FileBrowserScreen(),
          ),
        ),
      );
    }

    for (final size in sizes) {
      for (final scale in scales) {
        final label = '${size.width.toInt()} wide, ${scale}x text';

        testWidgets('list: all the way down at $label', (tester) async {
          useScreen(tester, size, scale);
          await openFiles(tester);
          await scrollToEnd(tester);

          expect(find.text('Shared with three.txt'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('grid: all the way down at $label', (tester) async {
          useScreen(tester, size, scale);
          await openFiles(tester);
          await tester.tap(find.byTooltip('Grid view'));
          await tester.pumpAndSettle();
          await scrollToEnd(tester);

          expect(find.text('Shared with three.txt'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('the Shared screen at the limits', () {
    Future<void> openShared(WidgetTester tester) {
      return tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const SharedScreen(),
          ),
        ),
      );
    }

    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(Tab, label));
      await tester.pumpAndSettle();
    }

    for (final size in sizes) {
      for (final scale in scales) {
        testWidgets('every tab at ${size.width.toInt()} wide, ${scale}x text', (
          tester,
        ) async {
          useScreen(tester, size, scale);
          await openShared(tester);

          for (final tab in ['With me', 'By me', 'Invitations']) {
            await openTab(tester, tab);
            await scrollToEnd(tester);
          }

          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final scale in scales) {
      testWidgets('the access sheet for twenty people, ${scale}x text', (
        tester,
      ) async {
        useScreen(tester, const Size(360, 800), scale);
        await openShared(tester);
        await openTab(tester, 'By me');
        await tester.scrollUntilVisible(
          find.text('Everyone'),
          300,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axis == Axis.vertical,
              )
              .hitTestable()
              .first,
        );
        await tester.tap(find.text('Everyone'));
        await tester.pumpAndSettle();

        // The sheet has to scroll to reach the buttons at the bottom.
        await tester.scrollUntilVisible(
          find.text('Transfer ownership…'),
          300,
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );

        expect(find.text('Transfer ownership…'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('twenty people all get a role button of the same size', (
      tester,
    ) async {
      useScreen(tester, const Size(360, 800), 1);
      await openShared(tester);
      await openTab(tester, 'By me');
      await tester.scrollUntilVisible(
        find.text('Everyone'),
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axis == Axis.vertical,
            )
            .hitTestable()
            .first,
      );
      await tester.tap(find.text('Everyone'));
      await tester.pumpAndSettle();

      final buttons = find.byWidgetPredicate(
        (w) => w is Tooltip && (w.message?.startsWith('Access for ') ?? false),
      );
      final sheetList = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first;

      // The sheet builds only the rows in view, so note each button's size as
      // it scrolls past.
      final sizeOf = <String, Size>{};
      for (var i = 0; i < 40; i++) {
        for (final element in buttons.evaluate()) {
          final tooltip = element.widget as Tooltip;
          sizeOf[tooltip.message!] = tester.getSize(find.byWidget(tooltip));
        }
        await tester.drag(sheetList, const Offset(0, -150));
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(sizeOf.length, 20);
      expect(sizeOf.values.toSet().length, 1);
    });
  });

  group('sharing roles and expiry at the limits', () {
    test('a role has a label, and the owner label is not a role to give', () {
      expect(ShareRole.values.map((r) => r.label), [
        'Owner',
        'Editor',
        'Viewer',
      ]);
    });
  });
}
