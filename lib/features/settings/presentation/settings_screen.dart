import 'package:flutter/material.dart';

/// The Settings tab. Empty for now.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SizedBox.expand(),
    );
  }
}
