import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/activity_chips.dart';
import 'package:om_cryfio/ui/widgets/file_grid_tile.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';

void main() {
  final activity = FileActivity(
    FileActivityKind.shared,
    DateTime(2026, 11, 24, 18, 19),
  );

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          backgroundColor: Colors.blue,
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: child),
          ),
        ),
      ),
    );
  }

  Widget chips() =>
      ActivityChips(activity: activity, now: DateTime(2026, 11, 25, 9));

  testWidgets('two chips: the action and the time', (tester) async {
    await pump(tester, chips());

    expect(find.text('Shared'), findsOneWidget);
    expect(find.text('Yesterday, 18:19'), findsOneWidget);
  });

  testWidgets('each chip is a full pill', (tester) async {
    await pump(tester, chips());

    final pills = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where(
          (box) =>
              box.decoration is ShapeDecoration &&
              (box.decoration as ShapeDecoration).shape is StadiumBorder,
        );
    expect(pills.length, 2);
  });

  testWidgets('the icon is plain, in the same white as the text', (
    tester,
  ) async {
    await pump(tester, chips());

    // No round badge behind the icons.
    final badges = tester.widgetList<Container>(find.byType(Container)).where((
      c,
    ) {
      final decoration = c.decoration;
      return decoration is BoxDecoration && decoration.shape == BoxShape.circle;
    });
    expect(badges, isEmpty);
    for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
      expect(icon.color, Colors.white);
    }
    expect(tester.widget<Text>(find.text('Shared')).style?.color, Colors.white);
  });

  testWidgets('a file picture and a folder use the very same chips', (
    tester,
  ) async {
    await pump(
      tester,
      FileGridTile(name: 'Photos', kind: FileKind.folder, activity: activity),
    );
    final onFolder = tester.widget<ActivityChips>(find.byType(ActivityChips));
    final folderSize = tester.getSize(find.text('Shared'));
    final folderStyle = tester.widget<Text>(find.text('Shared')).style;

    await pump(
      tester,
      FileGridTile(name: 'a.pdf', kind: FileKind.pdf, activity: activity),
    );
    final onFile = tester.widget<ActivityChips>(find.byType(ActivityChips));
    final fileStyle = tester.widget<Text>(find.text('Shared')).style;

    // One widget, with nothing to set a different look.
    expect(onFile.runtimeType, onFolder.runtimeType);
    expect(fileStyle?.color, folderStyle?.color);
    expect(fileStyle?.fontWeight, folderStyle?.fontWeight);
    expect(fileStyle?.fontSize, folderStyle?.fontSize);
    expect(tester.getSize(find.text('Shared')).height, folderSize.height);
  });
}
