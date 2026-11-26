import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/ui/svg_path.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/folder.dart';
import 'package:om_cryfio/ui/widgets/folder_paths.dart';

void main() {
  group('Folder', () {
    Future<void> pumpFolder(WidgetTester tester, {FolderColors? colors}) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 200, child: Folder(colors: colors)),
            ),
          ),
        ),
      );
    }

    testWidgets('draws at its aspect ratio', (tester) async {
      await pumpFolder(tester);

      final size = tester.getSize(find.byType(Folder));
      expect(size.width / size.height, closeTo(Folder.aspectRatio, 1e-6));
      expect(find.bySemanticsLabel('Folder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts a color override', (tester) async {
      await pumpFolder(tester, colors: FolderColors.fromBase(Colors.red));

      expect(tester.takeException(), isNull);
    });

    testWidgets('writes the title and subtitle on the cover', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: Folder(title: 'References', subtitle: '3 files'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('References'), findsOneWidget);
      expect(find.text('3 files'), findsOneWidget);
      // Screen readers get one label with everything.
      expect(
        find.bySemanticsLabel('Folder, References, 3 files'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('cuts a long title short at small size and 2x text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: Folder(
                  title: 'A folder with a very long name indeed',
                  subtitle: '1,204 files',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('its size matches the shapes in the SVG', () {
      final back = parseSvgPath(folderBackData).getBounds();

      expect(back.left, closeTo(102.8, 0.5));
      expect(back.top, closeTo(133.4, 0.5));
      expect(back.width, closeTo(588.1, 0.5));
      expect(back.height, closeTo(526.9, 0.5));
      expect(Folder.aspectRatio, closeTo(back.width / back.height, 0.01));
    });

    test('the other shapes sit inside the back panel', () {
      final back = parseSvgPath(folderBackData).getBounds().inflate(0.5);

      for (final data in [
        folderPageRightData,
        folderPageLeftData,
        folderAccentData,
        folderCoverData,
      ]) {
        final bounds = parseSvgPath(data).getBounds();
        expect(back.contains(bounds.topLeft), isTrue);
        expect(back.contains(bounds.bottomRight), isTrue);
      }
    });
  });

  group('FolderColors.fromBase', () {
    const base = Color(0xFF2255CC);
    final colors = FolderColors.fromBase(base);

    double brightness(Color color) => HSVColor.fromColor(color).value;

    test('uses the given color as the folder color', () {
      expect(colors.backTop, base);
      expect(colors.cover, base);
    });

    test('fades the back panel to a deeper shade', () {
      expect(brightness(colors.backBottom), lessThan(brightness(base)));
    });

    test('shades the page edge between the two', () {
      expect(brightness(colors.pageShade), lessThan(brightness(base)));
      expect(
        brightness(colors.pageShade),
        greaterThan(brightness(colors.backBottom)),
      );
    });

    test('keeps the pages white', () {
      expect(colors.page, Colors.white);
    });

    test('the standard palette is the blue from the design', () {
      expect(FolderColors.standard.backTop, const Color(0xFF3592E9));
      expect(FolderColors.standard.backBottom, const Color(0xFF2D3FA5));
    });
  });

  group('parseSvgPath', () {
    test('reads absolute commands', () {
      final bounds = parseSvgPath('M10 5L30 5C40 5 50 15 50 25H20V45L10 40Z')
          .getBounds();

      expect(bounds, const Rect.fromLTRB(10, 5, 50, 45));
    });

    test('reads relative commands from the current point', () {
      final bounds = parseSvgPath('m10 5 l20 0 v10 h-20 z').getBounds();

      expect(bounds, const Rect.fromLTRB(10, 5, 30, 15));
    });

    test('reads comma separated and run-together numbers', () {
      final bounds = parseSvgPath('M0,0c0,10-5,20-10,20').getBounds();

      expect(bounds.left, closeTo(-10, 1e-9));
      expect(bounds.bottom, closeTo(20, 1e-9));
    });

    test('continues a command that repeats its numbers', () {
      final bounds = parseSvgPath('M0 0 L10 0 10 10').getBounds();

      expect(bounds, const Rect.fromLTRB(0, 0, 10, 10));
    });

    test('mirrors the previous control point for smooth curves', () {
      // The S curve's first control point is the previous one mirrored through
      // the join, so a smooth S-bend continues in the same direction.
      final smooth = parseSvgPath('M0 0 C0 10 10 10 10 20 S20 30 20 40');
      final explicit = parseSvgPath(
        'M0 0 C0 10 10 10 10 20 C10 30 20 30 20 40',
      );

      expect(smooth.getBounds(), explicit.getBounds());
    });

    test('reads smooth curves written without a curve before them', () {
      final bounds = parseSvgPath('M0 0 s10 10 20 0').getBounds();

      expect(bounds.right, closeTo(20, 1e-9));
    });

    test('rejects commands it does not support', () {
      expect(() => parseSvgPath('M0 0Q1 1 2 2'), throwsFormatException);
      expect(() => parseSvgPath('M0 0a1 1 0 0 1 2 2'), throwsFormatException);
    });
  });
}
