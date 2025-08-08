import 'package:flutter/material.dart';
import 'settings_page.dart';

class ChangeLoginNamePage extends StatelessWidget {
  const ChangeLoginNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Login Name'),
        backgroundColor: const Color(0xFF6902FC),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // or push SettingsPage if needed
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Settings'),
        ),
      ),
    );
  }
}
