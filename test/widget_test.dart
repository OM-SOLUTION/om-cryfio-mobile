import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/app/app.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

void main() {
  // The scrolling text never stops, which would keep the screen from settling.
  setUpAll(() => MarqueeText.enabled = false);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OmCryfioApp()));
    await tester.pumpAndSettle();
  }

  // Tab icons also appear inside screens, so look only in the navigation bar.
  Finder navIcon(IconData icon) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(icon),
  );

  Future<void> openTab(WidgetTester tester, IconData icon) async {
    await tester.tap(navIcon(icon));
    await tester.pumpAndSettle();
  }

  testWidgets('app starts on the file browser', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'My files'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await pumpApp(tester);

    await openTab(tester, Icons.people_outline);
    expect(find.widgetWithText(AppBar, 'Shared'), findsOneWidget);
    expect(find.text('With me'), findsOneWidget);

    await openTab(tester, Icons.notifications_outlined);
    expect(find.text('No notifications'), findsOneWidget);

    await openTab(tester, Icons.settings_outlined);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

    await openTab(tester, Icons.folder_outlined);
    expect(find.widgetWithText(AppBar, 'My files'), findsOneWidget);
  });

  testWidgets('log out is a placeholder for now', (tester) async {
    await pumpApp(tester);
    await openTab(tester, Icons.settings_outlined);

    await tester.scrollUntilVisible(find.text('Log out'), 200);
    await tester.tap(find.text('Log out'));
    await tester.pump();

    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
