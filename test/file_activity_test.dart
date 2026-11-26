import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/collaborator_avatars.dart';
import 'package:om_cryfio/ui/widgets/file_activity_text.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

void main() {
  // A Wednesday.
  final now = DateTime(2026, 11, 25, 15, 30);

  group('formatActivityTime', () {
    test('today and yesterday say so, with the time', () {
      expect(
        formatActivityTime(DateTime(2026, 11, 25, 9, 5), now),
        'Today, 09:05',
      );
      expect(
        formatActivityTime(DateTime(2026, 11, 24, 23, 59), now),
        'Yesterday, 23:59',
      );
    });

    test('yesterday counts calendar days, not 24 hours', () {
      final justAfterMidnight = DateTime(2026, 11, 25, 0, 10);
      expect(
        formatActivityTime(DateTime(2026, 11, 24, 23, 50), justAfterMidnight),
        'Yesterday, 23:50',
      );
    });

    test('the last week is a weekday and a time', () {
      expect(
        formatActivityTime(DateTime(2026, 11, 22, 18, 5), now),
        'Sun, 18:05',
      );
    });

    test('older this year is a date and a time', () {
      expect(
        formatActivityTime(DateTime(2026, 3, 3, 14, 30), now),
        'Mar 3, 14:30',
      );
    });

    test('another year is a date with the year', () {
      expect(
        formatActivityTime(DateTime(2025, 12, 31, 8, 0), now),
        'Dec 31, 2025',
      );
    });
  });

  group('Collaborator.initials', () {
    test('are the first letters of the first two words', () {
      expect(const Collaborator('Amina Rahal').initials, 'AR');
      expect(const Collaborator('youssef ben ali').initials, 'YB');
      expect(const Collaborator('Omar').initials, 'O');
      expect(const Collaborator('  ').initials, '');
    });
  });

  group('Collaborator group', () {
    test('puts the owner first, then the others in order', () {
      const others = [Collaborator('Amina Rahal'), Collaborator('Omar Tazi')];

      expect(Collaborator.group(others).map((c) => c.name), [
        'You',
        'Amina Rahal',
        'Omar Tazi',
      ]);
      expect(Collaborator.group(const []).map((c) => c.name), ['You']);
    });

    test('says who has access in words', () {
      const one = Collaborator('A');

      expect(Collaborator.summary(const []), 'You');
      expect(Collaborator.summary(const [one]), 'You and 1 other');
      expect(Collaborator.summary(const [one, one, one]), 'You and 3 others');
    });
  });

  group('FileActivityText', () {
    test('lists the parts in order and skips missing ones', () {
      final activity = FileActivity(
        FileActivityKind.edited,
        DateTime(2026, 11, 25, 14, 30),
      );

      expect(FileActivityText.parts('12 MB', activity, now), [
        '12 MB',
        'Edited',
        'Today, 14:30',
      ]);
      expect(FileActivityText.parts(null, activity, now), [
        'Edited',
        'Today, 14:30',
      ]);
      expect(FileActivityText.parts('12 MB', null, now), ['12 MB']);
      expect(FileActivityText.parts('', null, now), isEmpty);
    });

    testWidgets('is one line with the parts between bars', (tester) async {
      final activity = FileActivity(
        FileActivityKind.edited,
        DateTime(2026, 11, 25, 14, 30),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FileActivityText(
              details: '12 MB',
              activity: activity,
              now: now,
            ),
          ),
        ),
      );

      expect(find.text('12 MB | Edited | Today, 14:30'), findsOneWidget);
    });
  });

  group('MarqueeText', () {
    const long = 'A long line of text that cannot possibly fit in the space';

    Future<void> pump(
      WidgetTester tester, {
      double width = 120,
      String text = long,
      bool reduceMotion = false,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: MarqueeText(text)),
              ),
            ),
          ),
        ),
      );
    }

    double offsetOfFirstText(WidgetTester tester) =>
        tester.getTopLeft(find.text(long).first).dx;

    setUp(() => MarqueeText.enabled = true);
    tearDown(() => MarqueeText.enabled = false);

    testWidgets('text that fits stays still and plain', (tester) async {
      await pump(tester, text: 'Short', width: 200);

      expect(
        find.descendant(
          of: find.byType(MarqueeText),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
      expect(find.text('Short'), findsOneWidget);
    });

    testWidgets('text that is too long rests, then scrolls slowly', (
      tester,
    ) async {
      await pump(tester);
      final start = offsetOfFirstText(tester);

      // Resting at the start for the first moments.
      await tester.pump(const Duration(seconds: 1));
      expect(offsetOfFirstText(tester), start);

      // Then moving left.
      await tester.pump(const Duration(seconds: 2));
      final later = offsetOfFirstText(tester);
      expect(later, lessThan(start));

      // Slowly: well under 40 pixels a second.
      await tester.pump(const Duration(seconds: 1));
      expect(later - offsetOfFirstText(tester), lessThan(40));
    });

    testWidgets('it goes on without end, back to the start each pass', (
      tester,
    ) async {
      await pump(tester);
      final start = offsetOfFirstText(tester);
      final textWidth = tester.getSize(find.text(long).first).width;
      // A pass is the text plus the gap, at 24 pixels a second, after a pause.
      final pass = Duration(
        milliseconds: 2000 + ((textWidth + 28) / 24 * 1000).round(),
      );

      await tester.pump(pass * 3);
      expect(offsetOfFirstText(tester), closeTo(start, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('with reduced motion it is cut off and does not move', (
      tester,
    ) async {
      await pump(tester, reduceMotion: true);

      expect(
        find.descendant(
          of: find.byType(MarqueeText),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
      final text = tester.widget<Text>(find.text(long));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
    });

    testWidgets('screen readers hear the text once', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsLabel(long), findsOneWidget);
      semantics.dispose();
    });
  });

  group('CollaboratorAvatars', () {
    Future<void> pump(WidgetTester tester, List<Collaborator> people) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: CollaboratorAvatars(collaborators: people)),
        ),
      );
    }

    const people = [
      Collaborator('Amina Rahal'),
      Collaborator('Youssef Berrada'),
      Collaborator('Sara Idrissi'),
      Collaborator('Omar Tazi'),
      Collaborator('Lina Chraibi'),
    ];

    testWidgets('nobody draws nothing', (tester) async {
      await pump(tester, const []);

      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(CollaboratorAvatars)), Size.zero);
    });

    testWidgets('up to three people each get their initials', (tester) async {
      await pump(tester, people.take(3).toList());

      expect(find.text('AR'), findsOneWidget);
      expect(find.text('YB'), findsOneWidget);
      expect(find.text('SI'), findsOneWidget);
    });

    testWidgets('more than three end with a count of the rest', (tester) async {
      await pump(tester, people);

      expect(find.text('AR'), findsOneWidget);
      expect(find.text('YB'), findsOneWidget);
      expect(find.text('SI'), findsNothing);
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('the width matches what widthFor says', (tester) async {
      await pump(tester, people.take(2).toList());

      expect(
        tester.getSize(find.byType(CollaboratorAvatars)).width,
        CollaboratorAvatars.widthFor(2, 24),
      );
    });

    testWidgets('screen readers hear everyone', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, people);

      expect(
        find.bySemanticsLabel(
          'Shared with Amina Rahal, Youssef Berrada, Sara Idrissi, '
          'Omar Tazi, Lina Chraibi',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('FileListTile', () {
    testWidgets('shows the line, the people and the menu in order', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FileListTile(
              name: 'Contract.pdf',
              kind: FileKind.pdf,
              details: '1.2 MB',
              activity: FileActivity(
                FileActivityKind.edited,
                DateTime.now().subtract(const Duration(minutes: 1)),
              ),
              collaborators: const [Collaborator('Amina Rahal')],
              menu: const Icon(Icons.more_vert),
            ),
          ),
        ),
      );

      final avatars = tester.getRect(find.byType(CollaboratorAvatars));
      final menu = tester.getRect(find.byIcon(Icons.more_vert));
      expect(avatars.right, lessThanOrEqualTo(menu.left));
      expect(find.textContaining('1.2'), findsOneWidget);
    });

    testWidgets('fits at 2x text on a narrow screen', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FileListTile(
              name: 'A rather long name for a contract.pdf',
              kind: FileKind.pdf,
              details: '1.2 MB',
              activity: FileActivity(FileActivityKind.edited, DateTime.now()),
              collaborators: const [
                Collaborator('Amina Rahal'),
                Collaborator('Omar Tazi'),
                Collaborator('Sara Idrissi'),
              ],
              menu: const Icon(Icons.more_vert),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
