import 'package:flutter/material.dart';

import 'package:om_cryfio/features/sharing/domain/sharing.dart';
import 'package:om_cryfio/features/sharing/presentation/role_chip.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/collaborator_avatars.dart';
import 'package:om_cryfio/ui/widgets/file_type_icon.dart';

/// Where an invitation stands.
enum InvitationState {
  /// Waiting for the user's answer.
  pending,

  /// Accepted; access starts once the keys for it are ready.
  preparing,
}

/// An invitation the user received: who sent it, what it is for, the role it
/// gives and when it ends, with Accept and Decline. An invitation that has
/// expired can no longer be answered.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.invitation,
    required this.now,
    this.state = InvitationState.pending,
    this.onAccept,
    this.onDecline,
  });

  final Invitation invitation;

  /// What "today" is, to work out the expiry.
  final DateTime now;
  final InvitationState state;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expired = invitation.isExpired(now);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: expired ? scheme.error : scheme.onSurfaceVariant,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CollaboratorAvatars(
                  collaborators: [invitation.from],
                  size: 36,
                  ringColor: scheme.surfaceContainerLow,
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: invitation.from.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' invited you'),
                      ],
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Row(
              children: [
                FileTypeIcon(
                  name: invitation.itemName,
                  kind: invitation.itemKind,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    invitation.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RoleChip(invitation.role),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  expired ? Icons.timer_off_outlined : Icons.schedule,
                  size: 16,
                  color: muted?.color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    invitation.expiryText(now),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _footer(context, expired),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, bool expired) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    if (expired) {
      // An expired invitation cannot be accepted: a new one is needed.
      return Text(
        'This invitation has expired. Ask ${invitation.from.name} to send a '
        'new one.',
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
      );
    }

    if (state == InvitationState.preparing) {
      // Access starts only when the keys for it are ready.
      return Row(
        children: [
          Icon(Icons.hourglass_top, size: 18, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Preparing access…',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      );
    }

    // Wraps onto a second line when large text leaves no room side by side.
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        TextButton(onPressed: onDecline, child: const Text('Decline')),
        FilledButton(onPressed: onAccept, child: const Text('Accept')),
      ],
    );
  }
}
