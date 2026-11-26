import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:om_cryfio/features/files/application/file_actions.dart';
import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/features/sharing/presentation/shared_sample_data.dart';
import 'package:om_cryfio/features/sharing/presentation/shared_screen.dart';
import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/file_kind.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/collaborator_avatars.dart';
import 'package:om_cryfio/ui/widgets/file_type_icon.dart';
import 'package:om_cryfio/ui/widgets/marquee_text.dart';

void main() {
  // The scrolling text never stops, which would keep the screen from settling.
  setUpAll(() => MarqueeText.enabled = false);

  Future<void> openShared(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: SharedScreen(
            withMe: sampleSharedWithMe(),
            byMe: sampleSharedByMe(),
            invitations: sampleInvitations(),
          ),
        ),
      ),
    );
  }

  // The access sheet opens at 60% of the screen, so use a tall phone to see all
  // of it without scrolling.
  void useTallPhone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 1400);
    addTearDown(tester.view.reset);
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(Tab, label));
    await tester.pumpAndSettle();
  }

  group('what each role may do', () {
    final file = FileItem.file(name: 'a.pdf', details: '');
    const folder = FileItem(name: 'F', kind: FileKind.folder, details: '');

    test('the owner gets everything, left out or not', () {
      expect(menuActionsFor(file), fileMenuActions);
      expect(menuActionsFor(file, role: ShareRole.owner), fileMenuActions);
      expect(menuActionsFor(folder), folderMenuActions);
    });

    test('an editor cannot share or transfer, but can change content', () {
      final actions = menuActionsFor(file, role: ShareRole.editor);

      expect(actions, isNot(contains(FileAction.share)));
      expect(actions, isNot(contains(FileAction.transferOwnership)));
      expect(
        actions,
        containsAll([
          FileAction.download,
          FileAction.rename,
          FileAction.uploadNewVersion,
          FileAction.moveToRecycleBin,
        ]),
      );
    });

    test('a viewer can only look, download and copy', () {
      final actions = menuActionsFor(file, role: ShareRole.viewer);

      expect(actions, [
        FileAction.download,
        FileAction.copy,
        FileAction.showVersionHistory,
        FileAction.toggleFavorite,
        FileAction.showDetails,
      ]);
    });

    test('order stays the same as the full menu', () {
      final editor = menuActionsFor(file, role: ShareRole.editor);
      final positions = [for (final a in editor) fileMenuActions.indexOf(a)];

      expect(positions, [...positions]..sort());
    });

    test('a folder offers a viewer no copy', () {
      final actions = menuActionsFor(folder, role: ShareRole.viewer);

      expect(actions, isNot(contains(FileAction.copy)));
      expect(actions, isNot(contains(FileAction.share)));
    });
  });

  group('invitation expiry', () {
    final sent = DateTime(2026, 11, 20, 12);

    test('lasts seven days', () {
      final invite = PendingInvite(
        const Collaborator('A'),
        ShareRole.viewer,
        sent,
      );

      expect(invite.expiresAt, DateTime(2026, 11, 27, 12));
    });

    test('says how long is left', () {
      final invite = PendingInvite(
        const Collaborator('A'),
        ShareRole.viewer,
        sent,
      );

      expect(
        invite.expiryText(DateTime(2026, 11, 21, 12)),
        'Expires in 6 days',
      );
      expect(invite.expiryText(DateTime(2026, 11, 26, 20)), 'Expires today');
      expect(invite.expiryText(DateTime(2026, 11, 27, 12)), 'Expired');
      expect(invite.expiryText(DateTime(2026, 12, 5)), 'Expired');
      expect(invite.isExpired(DateTime(2026, 11, 27, 11, 59)), isFalse);
    });
  });

  group('the Shared screen', () {
    testWidgets('has three tabs, starting with what is shared with me', (
      tester,
    ) async {
      await openShared(tester);

      expect(find.widgetWithText(Tab, 'With me'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'By me'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Invitations'), findsOneWidget);
      expect(find.text('Contract.pdf'), findsOneWidget);
    });

    testWidgets('each item shared with me shows my role and who shared it', (
      tester,
    ) async {
      await openShared(tester);

      expect(find.text('Editor'), findsWidgets);
      expect(find.text('Viewer'), findsWidgets);
      // Said by the picture, not in words.
      expect(find.textContaining('from '), findsNothing);
      // The sharer is the owner, so "You" is not in the row.
      expect(find.text('AR'), findsOneWidget);
      expect(find.text('Y'), findsNothing);
    });

    testWidgets('the sharer is pictured next to the icon, overlapping it', (
      tester,
    ) async {
      await openShared(tester);

      final row = find.ancestor(
        of: find.text('Contract.pdf'),
        matching: find.byType(ListTile),
      );
      final picture = tester.getRect(
        find.descendant(of: row, matching: find.byType(CollaboratorAvatars)),
      );
      final icon = tester.getRect(
        find.descendant(of: row, matching: find.byType(FileTypeIcon)),
      );
      final menu = tester.getRect(
        find.descendant(
          of: row,
          matching: find.byTooltip('More options for Contract.pdf'),
        ),
      );

      // On the left of the icon, reaching over its edge.
      expect(picture.left, lessThan(icon.left));
      expect(picture.right, greaterThan(icon.left));
      // Only one picture in the row, and none by the menu at the end.
      expect(
        find.descendant(of: row, matching: find.byType(CollaboratorAvatars)),
        findsOneWidget,
      );
      expect(menu.left, greaterThan(icon.right));
    });

    testWidgets('a viewer menu is shorter than an editor menu', (tester) async {
      await openShared(tester);

      await tester.tap(find.byTooltip('More options for Contract.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More options for Family photos'));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Rename'), findsNothing);
      expect(find.text('Share…'), findsNothing);
    });

    testWidgets('shared by me lists my items with who can reach them', (
      tester,
    ) async {
      await openShared(tester);
      await openTab(tester, 'By me');

      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('2 people · 1 pending'), findsOneWidget);
      // Here the user is the owner, first in the group.
      expect(find.text('Y'), findsWidgets);
    });

    testWidgets('tapping an item I shared opens who has access', (
      tester,
    ) async {
      useTallPhone(tester);
      await openShared(tester);
      await openTab(tester, 'By me');

      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      expect(find.text('People with access'), findsOneWidget);
      expect(find.text('Full control'), findsOneWidget);
      expect(find.text('Amina Rahal'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Trusted on first use'), findsOneWidget);
      expect(find.text('Waiting for an answer'), findsOneWidget);
      expect(find.textContaining('Expires in 5 days'), findsOneWidget);
      expect(find.text('Invite people'), findsOneWidget);
      expect(find.text('Transfer ownership…'), findsOneWidget);
    });

    testWidgets('inviting people is still a placeholder', (tester) async {
      useTallPhone(tester);
      await openShared(tester);
      await openTab(tester, 'By me');
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Invite people'));
      await tester.pump();

      expect(find.text('Coming soon'), findsOneWidget);
    });
  });

  group('the access sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      useTallPhone(tester);
      await openShared(tester);
      await openTab(tester, 'By me');
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
    }

    Finder roleButton(String name) => find.byTooltip('Access for $name');
    final cancelInvite = find.byTooltip('Cancel invitation for Lina Chraibi');

    testWidgets('every role button is the same size, in the same column', (
      tester,
    ) async {
      await openSheet(tester);

      final amina = tester.getRect(roleButton('Amina Rahal'));
      final youssef = tester.getRect(roleButton('Youssef Berrada'));
      // The cancel icon is small, and ends at the same right edge.
      final cancel = tester.getRect(find.byIcon(Icons.close));

      expect(amina.size, youssef.size);
      expect(cancel.width, lessThan(amina.width / 2));
      expect(youssef.left, amina.left);
      expect(youssef.right, amina.right);
      expect(cancel.right, closeTo(amina.right, 0.5));
      // The Owner label ends at the same edge.
      expect(
        tester.getRect(find.text('Owner')).right,
        lessThanOrEqualTo(amina.right),
      );
    });

    testWidgets('opens partway, and dragging it down closes it', (
      tester,
    ) async {
      await openSheet(tester);

      // Opens at 60% of the screen, so the page behind still shows above it.
      final top = tester.getTopLeft(find.byType(Material).last).dy;
      expect(top, greaterThan(1400 * 0.3));
      expect(find.text('Documents'), findsWidgets);

      await tester.fling(
        find.text('People with access'),
        const Offset(0, 900),
        2000,
      );
      await tester.pumpAndSettle();

      expect(find.text('People with access'), findsNothing);
    });

    testWidgets('the trust icon and its text share a center line', (
      tester,
    ) async {
      await openSheet(tester);

      final icon = tester.getCenter(find.byIcon(Icons.verified_outlined)).dy;
      final label = tester.getCenter(find.text('Verified')).dy;
      expect(icon, closeTo(label, 1));
    });

    testWidgets('names are written out, not cut off', (tester) async {
      await openSheet(tester);

      for (final name in ['Amina Rahal', 'Youssef Berrada', 'Lina Chraibi']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
        expect(paragraph.didExceedMaxLines, isFalse, reason: name);
      }
    });

    testWidgets('the role button opens Editor, Viewer and Remove access', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(roleButton('Amina Rahal'));
      await tester.pumpAndSettle();

      expect(find.text('Editor'), findsWidgets);
      expect(find.text('Viewer'), findsWidgets);
      expect(find.text('Remove access'), findsOneWidget);
      // The current role is marked.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('choosing a role changes it', (tester) async {
      await openSheet(tester);

      await tester.tap(roleButton('Amina Rahal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Viewer').last);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: roleButton('Amina Rahal'),
          matching: find.text('Viewer'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Remove access takes the person out of the sheet and the '
        'list', (tester) async {
      await openSheet(tester);

      await tester.tap(roleButton('Youssef Berrada'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove access'));
      await tester.pumpAndSettle();

      expect(roleButton('Youssef Berrada'), findsNothing);
      expect(roleButton('Amina Rahal'), findsOneWidget);
      // Behind the sheet, the row now counts one person.
      expect(find.text('1 person · 1 pending'), findsOneWidget);
    });

    testWidgets('Cancel withdraws a pending invitation', (tester) async {
      await openSheet(tester);

      expect(find.textContaining('invited'), findsNothing);
      await tester.tap(cancelInvite);
      await tester.pumpAndSettle();

      expect(find.text('Waiting for an answer'), findsNothing);
      expect(find.text('2 people'), findsOneWidget);
    });

    testWidgets('when nobody is left the item leaves "By me"', (tester) async {
      await openSheet(tester);

      for (final name in ['Amina Rahal', 'Youssef Berrada']) {
        await tester.tap(roleButton(name));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove access'));
        await tester.pumpAndSettle();
      }
      await tester.tap(cancelInvite);
      await tester.pumpAndSettle();

      // Close the sheet.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Documents'), findsNothing);
      expect(find.text('Holiday.jpg'), findsOneWidget);
    });
  });

  testWidgets('every tab and the access sheet fit a small phone at 2x text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await openShared(tester);
    await openTab(tester, 'By me');
    await openTab(tester, 'Invitations');
    await openTab(tester, 'By me');
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    // A layout overflow would have thrown while pumping.
    expect(tester.takeException(), isNull);
  });

  group('the Invitations tab', () {
    testWidgets('shows a badge with the invitations still open', (
      tester,
    ) async {
      await openShared(tester);

      // Two can be answered, the third has expired.
      expect(find.byType(Badge), findsOneWidget);
      expect(
        tester.widget<Badge>(find.byType(Badge)).label.toString(),
        contains('2'),
      );
    });

    testWidgets('lists each invitation with its role and expiry', (
      tester,
    ) async {
      await openShared(tester);
      await openTab(tester, 'Invitations');

      expect(find.text('Q4 report.pdf'), findsOneWidget);
      expect(find.text('Design files'), findsOneWidget);
      expect(find.text('Expires in 6 days'), findsOneWidget);
      expect(find.text('Expires in 2 days'), findsOneWidget);
      expect(find.text('Accept'), findsNWidgets(2));
      expect(find.text('Decline'), findsNWidgets(2));
    });

    testWidgets('an expired invitation cannot be answered', (tester) async {
      await openShared(tester);
      await openTab(tester, 'Invitations');
      await tester.scrollUntilVisible(
        find.text('Old notes.txt'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Expired'), findsOneWidget);
      expect(find.textContaining('has expired'), findsOneWidget);
      // Only the two open invitations have buttons.
      expect(find.text('Accept'), findsNWidgets(2));
    });

    testWidgets('accepting shows that access is being prepared', (
      tester,
    ) async {
      await openShared(tester);
      await openTab(tester, 'Invitations');

      await tester.tap(find.text('Accept').first);
      await tester.pumpAndSettle();

      expect(find.text('Preparing access…'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      // One fewer is waiting for an answer.
      expect(
        tester.widget<Badge>(find.byType(Badge)).label.toString(),
        contains('1'),
      );
    });

    testWidgets('declining removes the invitation', (tester) async {
      await openShared(tester);
      await openTab(tester, 'Invitations');

      await tester.tap(find.text('Decline').first);
      await tester.pumpAndSettle();

      expect(find.text('Q4 report.pdf'), findsNothing);
      expect(find.text('Design files'), findsOneWidget);
    });

    testWidgets('with none left it says so', (tester) async {
      await openShared(tester);
      await openTab(tester, 'Invitations');

      await tester.tap(find.text('Decline').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decline').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Old notes.txt'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      // The expired one is still there, since it cannot be declined either.
      expect(find.text('Old notes.txt'), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
    });
  });
}
