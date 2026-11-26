import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/ui/theme/app_theme.dart';

void main() {
  for (final theme in [AppTheme.light(), AppTheme.dark()]) {
    testWidgets('the app bar keeps the page color while content scrolls under '
        'it (${theme.brightness.name})', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: ListView(
              children: [
                for (var i = 0; i < 40; i++) ListTile(title: Text('Row $i')),
              ],
            ),
          ),
        ),
      );

      Color barColor() {
        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(AppBar),
                matching: find.byType(Material),
              )
              .first,
        );
        return material.color!;
      }

      final page = theme.colorScheme.surface;
      expect(barColor(), page);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(barColor(), page);
    });
  }
}
