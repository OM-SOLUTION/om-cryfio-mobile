import 'package:om_cryfio/features/files/domain/file_item.dart';
import 'package:om_cryfio/ui/file_activity.dart';
import 'package:om_cryfio/ui/file_kind.dart';

/// What someone may do with a file or folder they can reach.
enum ShareRole {
  /// Controls sharing, restoring, deleting for good and transfer.
  owner('Owner'),

  /// Views and downloads, uploads, renames and deletes into the Recycle Bin.
  editor('Editor'),

  /// Views and downloads.
  viewer('Viewer');

  const ShareRole(this.label);

  final String label;
}

/// Whether a contact's public key was checked by comparing safety codes, or is
/// only trusted because it was the first one seen and has not changed since.
enum KeyTrust {
  verified('Verified'),
  firstUse('Trusted on first use');

  const KeyTrust(this.label);

  final String label;
}

/// Someone an item is shared with: who, in which role, and how far their key is
/// trusted.
class SharedPerson {
  const SharedPerson(
    this.person, {
    this.role = ShareRole.viewer,
    this.trust = KeyTrust.firstUse,
  });

  final Collaborator person;
  final ShareRole role;
  final KeyTrust trust;

  SharedPerson copyWith({ShareRole? role}) =>
      SharedPerson(person, role: role ?? this.role, trust: trust);
}

/// An invitation that has been sent but not accepted yet.
class PendingInvite {
  const PendingInvite(this.person, this.role, this.sentAt);

  final Collaborator person;
  final ShareRole role;
  final DateTime sentAt;

  /// How long an invitation can be accepted for.
  static const lifetime = Duration(days: 7);

  DateTime get expiresAt => sentAt.add(lifetime);

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  /// Whole days left, rounding up, so "1" until the very end.
  int daysLeft(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? 0 : (left.inHours / 24).ceil();
  }

  /// "Expires in 5 days", "Expires today", or "Expired".
  String expiryText(DateTime now) {
    if (isExpired(now)) return 'Expired';
    final days = daysLeft(now);
    return switch (days) {
      <= 1 => 'Expires today',
      final n => 'Expires in $n days',
    };
  }
}

/// An item someone else shared with the user: it is theirs, and the user holds
/// [role] on it.
class SharedWithMe {
  const SharedWithMe({
    required this.item,
    required this.sharedBy,
    required this.role,
  });

  final FileItem item;

  /// The owner.
  final Collaborator sharedBy;

  /// Editor or Viewer.
  final ShareRole role;
}

/// An item the user owns that other people can reach.
class SharedByMe {
  const SharedByMe({
    required this.item,
    required this.people,
    this.pending = const [],
  });

  final FileItem item;

  /// Everyone with active access.
  final List<SharedPerson> people;

  /// Invitations not answered yet.
  final List<PendingInvite> pending;

  /// The same entry with other people and invitations. The item's own list of
  /// people follows [people].
  SharedByMe copyWith({
    List<SharedPerson>? people,
    List<PendingInvite>? pending,
  }) {
    final nextPeople = people ?? this.people;
    return SharedByMe(
      item: item.copyWith(
        collaborators: [for (final p in nextPeople) p.person],
      ),
      people: nextPeople,
      pending: pending ?? this.pending,
    );
  }

  /// Whether anyone but the owner can still reach it, or has been invited.
  bool get isShared => people.isNotEmpty || pending.isNotEmpty;
}

/// An invitation the user received. Access starts only once it is accepted and
/// the keys for it are ready.
class Invitation {
  const Invitation({
    required this.from,
    required this.itemName,
    required this.itemKind,
    required this.role,
    required this.sentAt,
  });

  final Collaborator from;
  final String itemName;
  final FileKind itemKind;
  final ShareRole role;
  final DateTime sentAt;

  DateTime get expiresAt => sentAt.add(PendingInvite.lifetime);

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  String expiryText(DateTime now) =>
      PendingInvite(from, role, sentAt).expiryText(now);
}
