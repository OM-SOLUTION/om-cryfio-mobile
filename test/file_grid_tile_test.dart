import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/activity_chips.dart';
import 'package:om_cryfio/ui/widgets/collaborator_avatars.dart';
import 'package:om_cryfio/ui/widgets/file_activity_text.dart';
import 'package:om_cryfio/ui/widgets/file_grid_tile.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/folder.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

void main() {
  // The scrolling text never stops, which would keep the screen from settling.
  setUpAll(() => MarqueeText.enabled = false);

  Future<void> pumpTile(WidgetTester tester, FileGridTile tile) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(child: SizedBox(width: 160, child: tile)),
        ),
      ),
    );
  }

  testWidgets('a folder is a card with its name and count on the folder', (
    tester,
  ) async {
    await pumpTile(
      tester,
      const FileGridTile(
        name: 'Documents',
        kind: FileKind.folder,
        details: '12 files',
      ),
    );

    expect(find.byType(Folder), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('12 files'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });

  testWidgets('a folder card and a file card have the same padding', (
    tester,
  ) async {
    await pumpTile(
      tester,
      const FileGridTile(name: 'Documents', kind: FileKind.folder),
    );
    final card = tester.getRect(find.byType(Card));
    final folder = tester.getRect(find.byType(Folder));

    expect(folder.left - card.left, FileGridTile.inset);
    expect(card.right - folder.right, FileGridTile.inset);
    expect(folder.top - card.top, FileGridTile.inset);
  });

  testWidgets('a file is a card with its name below the icon', (tester) async {
    await pumpTile(
      tester,
      const FileGridTile(
        name: 'Contract.pdf',
        kind: FileKind.pdf,
        details: '1.2 MB',
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(Folder), findsNothing);
    expect(find.text('Contract.pdf'), findsOneWidget);
  });

  testWidgets('tapping a folder calls onTap', (tester) async {
    var taps = 0;
    await pumpTile(
      tester,
      FileGridTile(
        name: 'Documents',
        kind: FileKind.folder,
        details: '12 files',
        onTap: () => taps++,
      ),
    );

    await tester.tap(find.byType(Folder));

    expect(taps, 1);
  });

  testWidgets('a shared folder says who it is shared with', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTile(
      tester,
      FileGridTile(
        name: 'Photos',
        kind: FileKind.folder,
        details: '48 files',
        collaborators: const [
          Collaborator('Amina Rahal'),
          Collaborator('Omar'),
        ],
        activity: FileActivity(
          FileActivityKind.shared,
          DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Photos, 48 files, Shared, Today, \d\d:\d\d, '
          r'Shared with Amina Rahal, Omar$',
        ),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  group('the footer', () {
    final at = DateTime.now().subtract(const Duration(minutes: 1));

    testWidgets('a file does not show its size', (tester) async {
      await pumpTile(
        tester,
        const FileGridTile(
          name: 'Contract.pdf',
          kind: FileKind.pdf,
          details: '1.2 MB',
        ),
      );

      expect(find.text('1.2 MB'), findsNothing);
      expect(find.byType(FileActivityText), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('a file has its people at the top right of the picture, as '
        'one group with the owner first', (tester) async {
      await pumpTile(
        tester,
        FileGridTile(
          name: 'Contract.pdf',
          kind: FileKind.pdf,
          activity: FileActivity(FileActivityKind.edited, at),
          collaborators: const [Collaborator('Amina Rahal')],
        ),
      );

      final card = tester.getRect(find.byType(Card));
      final people = tester.getRect(find.byType(CollaboratorAvatars));
      final name = tester.getRect(find.text('Contract.pdf'));

      expect(find.byType(CollaboratorAvatars), findsOneWidget);
      // Top right of the picture: above the name, in the right half.
      expect(people.bottom, lessThan(name.top));
      expect(people.center.dx, greaterThan(card.center.dx));
      expect(people.top - card.top, lessThan(FileGridTile.inset + 16));
      // The owner first, and the circles overlap each other.
      final you = tester.getRect(find.text('Y'));
      final amina = tester.getRect(find.text('AR'));
      expect(you.left, lessThan(amina.left));
      expect(amina.left - you.left, lessThan(FileGridTile.avatarSize));
    });

    testWidgets('a file has the menu button at the end of its name row', (
      tester,
    ) async {
      await pumpTile(
        tester,
        const FileGridTile(
          name: 'Contract.pdf',
          kind: FileKind.pdf,
          menu: Icon(Icons.more_vert),
        ),
      );

      final name = tester.getRect(find.text('Contract.pdf'));
      final menu = tester.getRect(find.byIcon(Icons.more_vert));
      final card = tester.getRect(find.byType(Card));

      expect(menu.left, greaterThanOrEqualTo(name.right));
      expect(menu.center.dy, closeTo(name.center.dy, 2));
      expect(
        card.right - menu.right,
        lessThanOrEqualTo(FileGridTile.inset + 8),
      );
    });

    testWidgets('the icon is small, with room around it', (tester) async {
      await pumpTile(
        tester,
        const FileGridTile(name: 'Report.xyz', kind: FileKind.other),
      );

      final icon = tester.getRect(find.byIcon(FileKind.other.icon));
      final picture = tester.getRect(find.byType(AspectRatio).first);

      expect(icon.height, lessThanOrEqualTo(picture.height * 0.55));
      expect(icon.center.dx, closeTo(picture.center.dx, 1));
    });

    testWidgets('a file shows its last action as chips on its picture', (
      tester,
    ) async {
      await pumpTile(
        tester,
        FileGridTile(
          name: 'Contract.pdf',
          kind: FileKind.pdf,
          details: '1.2 MB',
          activity: FileActivity(FileActivityKind.edited, at),
        ),
      );

      final chips = tester.getRect(find.byType(ActivityChips));
      final name = tester.getRect(find.text('Contract.pdf'));
      final card = tester.getRect(find.byType(Card));

      // Above the name, so on the picture, and inside the card.
      expect(chips.bottom, lessThan(name.top));
      expect(card.contains(chips.topLeft), isTrue);
      expect(find.text('Edited'), findsOneWidget);
      expect(find.textContaining('Today, '), findsOneWidget);
    });

    testWidgets('a file with no activity has no chips', (tester) async {
      await pumpTile(
        tester,
        const FileGridTile(name: 'Contract.pdf', kind: FileKind.pdf),
      );

      expect(find.byType(ActivityChips), findsNothing);
    });

    testWidgets('a folder shows its last action as chips on the cover, '
        'under the name and count', (tester) async {
      await pumpTile(
        tester,
        FileGridTile(
          name: 'Documents',
          kind: FileKind.folder,
          details: '12 files',
          activity: FileActivity(FileActivityKind.edited, at),
        ),
      );

      final folder = tester.getRect(find.byType(Folder));
      final action = tester.getRect(find.text('Edited'));
      final time = find.textContaining('Today, ');
      final count = tester.getRect(find.text('12 files'));

      // Inside the folder, below the count, with space between.
      expect(folder.contains(action.center), isTrue);
      expect(folder.contains(tester.getCenter(time)), isTrue);
      expect(action.top, greaterThan(count.bottom));
      // Written once, on the folder; nothing is left under it.
      expect(find.text('12 files'), findsOneWidget);
      expect(find.byType(FileActivityText), findsNothing);
      expect(find.byType(ActivityChips), findsOneWidget);
      // The card is the folder and its padding, nothing more.
      expect(
        tester.getRect(find.byType(Card)).height,
        closeTo(folder.height + 2 * FileGridTile.inset, 0.5),
      );
    });

    testWidgets('a folder with no activity has no chips', (tester) async {
      await pumpTile(
        tester,
        const FileGridTile(name: 'Documents', kind: FileKind.folder),
      );

      expect(find.byType(ActivityChips), findsNothing);
    });

    testWidgets('a folder puts its people on the cover, level with the name', (
      tester,
    ) async {
      await pumpTile(
        tester,
        FileGridTile(
          name: 'Photos',
          kind: FileKind.folder,
          details: '48 files',
          activity: FileActivity(FileActivityKind.shared, at),
          collaborators: const [
            Collaborator('Amina Rahal'),
            Collaborator('Omar Tazi'),
          ],
        ),
      );

      final folder = tester.getRect(find.byType(Folder));
      final people = tester.getRect(find.byType(CollaboratorAvatars));
      final count = tester.getRect(find.text('48 files'));

      // On the folder, at its right, and on the same level as the count.
      expect(folder.contains(people.center), isTrue);
      expect(people.right, greaterThan(folder.center.dx));
      expect(people.bottom, closeTo(count.bottom, 6));
      // And nothing for them under the folder.
      expect(find.byType(Divider), findsNothing);
      expect(find.byType(CollaboratorAvatars), findsOneWidget);
      // The owner is the first of them.
      expect(find.text('Y'), findsOneWidget);
      expect(
        tester.getRect(find.text('Y')).left,
        lessThan(tester.getRect(find.text('AR')).left),
      );
    });

    testWidgets('a file with nobody else shows just your picture', (
      tester,
    ) async {
      await pumpTile(
        tester,
        const FileGridTile(name: 'Notes.txt', kind: FileKind.document),
      );

      expect(find.text('Y'), findsOneWidget);
      expect(find.text('You'), findsNothing);
    });
  });
}
