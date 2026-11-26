import 'package:flutter/material.dart';

/// The Shared tab. Empty for now: sharing, roles and invitations come later.
class SharedScreen extends StatelessWidget {
  const SharedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared')),
      body: const SizedBox.expand(),
    );
  }
}
