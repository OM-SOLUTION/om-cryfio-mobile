import 'package:flutter/material.dart';

/// The Files tab. Empty for now: the file list and grid come later.
class FileBrowserScreen extends StatelessWidget {
  const FileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My files')),
      body: const SizedBox.expand(),
    );
  }
}
