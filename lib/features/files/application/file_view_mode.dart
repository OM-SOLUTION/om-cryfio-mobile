import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:om_cryfio/ui/widgets/view_mode_toggle.dart';

class FileViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() => ViewMode.list;

  void set(ViewMode mode) => state = mode;
}

/// How the Files screen lays out its items. Not remembered between launches.
final fileViewModeProvider = NotifierProvider<FileViewModeNotifier, ViewMode>(
  FileViewModeNotifier.new,
);
