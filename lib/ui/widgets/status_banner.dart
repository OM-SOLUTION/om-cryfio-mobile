import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/theme/app_theme.dart';

enum StatusKind { info, success, warning, error }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.kind = StatusKind.info,
    this.title,
  });

  final String message;
  final StatusKind kind;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = theme.extension<StatusColors>()!;

    final (background, foreground, icon) = switch (kind) {
      StatusKind.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.info_outline,
      ),
      StatusKind.success => (
        status.successContainer,
        status.onSuccessContainer,
        Icons.check_circle_outline,
      ),
      StatusKind.warning => (
        status.warningContainer,
        status.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      StatusKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
    };

    // A live region makes screen readers announce the banner when it appears.
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, color: foreground)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
