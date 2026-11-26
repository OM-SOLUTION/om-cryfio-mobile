/// What was last done to a file or folder.
enum FileActivityKind {
  uploaded('Uploaded'),
  edited('Edited'),
  shared('Shared'),
  renamed('Renamed'),
  moved('Moved'),
  downloaded('Downloaded');

  const FileActivityKind(this.label);

  final String label;
}

/// The last action done to a file or folder, and when.
class FileActivity {
  const FileActivity(this.kind, this.at);

  final FileActivityKind kind;
  final DateTime at;

  /// The time as shown on a row: see [formatActivityTime].
  String time(DateTime now) => formatActivityTime(at, now);
}

/// Someone who has some kind of access to a file or folder.
class Collaborator {
  const Collaborator(this.name);

  final String name;

  /// The owner, the person looking at the screen. The signed-in user is always
  /// the owner of what they see for now.
  static const owner = Collaborator('You');

  /// Everyone who can see something, as a group: the owner first, then the
  /// [others] in order.
  static List<Collaborator> group(List<Collaborator> others) => [
    owner,
    ...others,
  ];

  /// Who has access, in words: "You", or "You and 2 others".
  static String summary(List<Collaborator> others) => switch (others.length) {
    0 => 'You',
    1 => 'You and 1 other',
    final count => 'You and $count others',
  };

  /// Up to two capital letters: the first letters of the first two words.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _clock(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';

/// The time of an action for a row, relative to [now]: "Today, 14:30",
/// "Yesterday, 09:12", a weekday and time within the last week ("Mon, 18:05"),
/// then the date ("Mar 3, 14:30"), with the year when it is not this one.
String formatActivityTime(DateTime at, DateTime now) {
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;

  if (days <= 0) return 'Today, ${_clock(at)}';
  if (days == 1) return 'Yesterday, ${_clock(at)}';
  if (days < 7) return '${_weekdays[at.weekday - 1]}, ${_clock(at)}';

  final date = '${_months[at.month - 1]} ${at.day}';
  return at.year == now.year ? '$date, ${_clock(at)}' : '$date, ${at.year}';
}
