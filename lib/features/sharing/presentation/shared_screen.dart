import 'package:flutter/material.dart';

import 'package:om_cryfio/features/files/presentation/file_action_menu.dart';
import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/features/sharing/presentation/invitation_card.dart';
import 'package:om_cryfio/features/sharing/presentation/manage_access_sheet.dart';
import 'package:om_cryfio/features/sharing/presentation/role_chip.dart';
import 'package:om_cryfio/features/sharing/presentation/shared_sample_data.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/coming_soon.dart';
import 'package:om_cryfio/ui/widgets/empty_state.dart';
import 'package:om_cryfio/ui/widgets/file_list_tile.dart';
import 'package:om_cryfio/ui/widgets/search_field.dart';

/// What the user shares and what is shared with them, in three tabs: items
/// others shared with the user, items the user owns that others can reach, and
/// invitations waiting for an answer.
class SharedScreen extends StatefulWidget {
  /// Left out, each list is the normal samples followed by the smallest and
  /// largest cases (see `edgeCase...` in `shared_sample_data.dart`).
  const SharedScreen({super.key, this.withMe, this.byMe, this.invitations});

  final List<SharedWithMe>? withMe;
  final List<SharedByMe>? byMe;
  final List<Invitation>? invitations;

  @override
  State<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  // Sample data, kept here so accepting or declining an invitation shows its
  // effect. Nothing is sent anywhere.
  late final List<SharedWithMe> _withMe = [
    ...(widget.withMe ?? [...sampleSharedWithMe(), ...edgeCaseSharedWithMe()]),
  ];
  late final List<SharedByMe> _byMe = [
    ...(widget.byMe ?? [...sampleSharedByMe(), ...edgeCaseSharedByMe()]),
  ];
  late final List<Invitation> _invitations = [
    ...(widget.invitations ??
        [...sampleInvitations(), ...edgeCaseInvitations()]),
  ];
  final _accepted = <Invitation>{};
  final DateTime _now = DateTime.now();

  // Called with an item's updated sharing after a change in the access sheet.
  // An item nobody can reach any more drops out of "By me".
  void _byMeChanged(SharedByMe next) {
    setState(() {
      final index = _byMe.indexWhere((e) => e.item.name == next.item.name);
      if (index < 0) return;
      if (next.isShared) {
        _byMe[index] = next;
      } else {
        _byMe.removeAt(index);
      }
    });
  }

  int get _waiting => [
    for (final invitation in _invitations)
      if (!invitation.isExpired(_now) && !_accepted.contains(invitation))
        invitation,
  ].length;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shared'),
          bottom: TabBar(
            // Each tab is as wide as its text, so large text scrolls the tabs
            // instead of squeezing a label.
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'With me'),
              const Tab(text: 'By me'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Invitations'),
                    if (_waiting > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Badge(label: Text('$_waiting')),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SharedWithMeTab(items: _withMe),
            _SharedByMeTab(items: _byMe, onChanged: _byMeChanged),
            _InvitationsTab(
              invitations: _invitations,
              accepted: _accepted,
              now: _now,
              onAccept: (invitation) =>
                  setState(() => _accepted.add(invitation)),
              onDecline: (invitation) => setState(() {
                _invitations.remove(invitation);
                _accepted.remove(invitation);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// The search bar above a list, as on the Files screen.
class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SearchField(hint: hint),
    );
  }
}

class _SharedWithMeTab extends StatelessWidget {
  const _SharedWithMeTab({required this.items});

  final List<SharedWithMe> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'Nothing shared with you yet',
        message: 'Files and folders other people share with you appear here.',
      );
    }

    return Column(
      children: [
        const _SearchRow(hint: 'Search shared with me'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              for (final shared in items)
                FileListTile(
                  name: shared.item.name,
                  kind: shared.item.kind,
                  details: shared.item.details,
                  activity: shared.item.activity,
                  // The person who shared it is pictured next to the icon.
                  sharedBy: shared.sharedBy,
                  below: RoleChip(shared.role),
                  onTap: () => showComingSoon(context),
                  // What the menu offers depends on the user's role.
                  menu: FileActionMenuButton(
                    item: shared.item,
                    role: shared.role,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SharedByMeTab extends StatelessWidget {
  const _SharedByMeTab({required this.items, required this.onChanged});

  final List<SharedByMe> items;
  final ValueChanged<SharedByMe> onChanged;

  static String _summary(SharedByMe entry) {
    final people = entry.people.length;
    final pending = entry.pending.length;
    return [
      '$people ${people == 1 ? 'person' : 'people'}',
      if (pending > 0) '$pending pending',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.ios_share,
        title: "You haven't shared anything",
        message: 'Share a file or folder from its menu and it appears here.',
      );
    }

    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return Column(
      children: [
        const _SearchRow(hint: 'Search shared by me'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              for (final entry in items)
                FileListTile(
                  name: entry.item.name,
                  kind: entry.item.kind,
                  details: entry.item.details,
                  activity: entry.item.activity,
                  collaborators: [for (final p in entry.people) p.person],
                  below: Row(
                    children: [
                      Icon(
                        Icons.manage_accounts_outlined,
                        size: 14,
                        color: muted?.color,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _summary(entry),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                      ),
                    ],
                  ),
                  // Tapping the row opens who can reach it.
                  onTap: () =>
                      showManageAccess(context, entry, onChanged: onChanged),
                  menu: FileActionMenuButton(item: entry.item),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvitationsTab extends StatelessWidget {
  const _InvitationsTab({
    required this.invitations,
    required this.accepted,
    required this.now,
    required this.onAccept,
    required this.onDecline,
  });

  final List<Invitation> invitations;
  final Set<Invitation> accepted;
  final DateTime now;
  final ValueChanged<Invitation> onAccept;
  final ValueChanged<Invitation> onDecline;

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return const EmptyState(
        icon: Icons.mail_outline,
        title: 'No invitations',
        message: 'When someone shares with you, the invitation shows up here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: invitations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final invitation = invitations[index];
        return InvitationCard(
          invitation: invitation,
          now: now,
          state: accepted.contains(invitation)
              ? InvitationState.preparing
              : InvitationState.pending,
          onAccept: () => onAccept(invitation),
          onDecline: () => onDecline(invitation),
        );
      },
    );
  }
}
