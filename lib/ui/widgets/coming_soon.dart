import 'package:flutter/material.dart';

/// Feedback for actions that have no behavior yet.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Coming soon')));
}
