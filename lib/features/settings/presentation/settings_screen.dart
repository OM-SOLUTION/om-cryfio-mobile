import 'package:flutter/material.dart';

import 'package:om_cryfio/app/dev_tools.dart';
import 'package:om_cryfio/ui/theme/app_theme.dart';
import 'package:om_cryfio/ui/widgets/coming_soon.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void soon() => showComingSoon(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('Your name'),
            subtitle: Text('name@example.com'),
          ),
          const _SectionHeader('Security'),
          _NavTile(
            icon: Icons.devices_outlined,
            title: 'Sessions',
            onTap: soon,
          ),
          _NavTile(
            icon: Icons.lock_outline,
            title: 'Password and recovery',
            onTap: soon,
          ),
          const _SectionHeader('Preferences'),
          _NavTile(
            icon: Icons.notifications_outlined,
            title: 'Notification preferences',
            onTap: soon,
          ),
          const _SectionHeader('Storage'),
          // Sample usage for layout work.
          const ListTile(
            title: Text('2.4 GB of 5 GB used'),
            subtitle: Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(
                value: 0.48,
                semanticsLabel: 'Storage used',
              ),
            ),
          ),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: soon,
          ),
          ...devSettingsTiles(context),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
