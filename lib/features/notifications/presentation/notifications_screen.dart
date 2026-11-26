import 'package:flutter/material.dart';

import 'package:om_cryfio/ui/widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const EmptyState(
        icon: Icons.notifications_none,
        title: 'No notifications',
        message: 'Invitations, transfers and file activity appear here.',
      ),
    );
  }
}
