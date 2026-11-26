import 'package:flutter/material.dart';

/// The Alerts tab. Empty for now.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const SizedBox.expand(),
    );
  }
}
