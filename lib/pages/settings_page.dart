import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'changeloginname.dart';
import 'changepassword.dart';
import 'notificationsettings.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('igpstoken');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget buildLink(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool noBorder = false,
    Color textColor = Colors.black,
    Color iconColor = Colors.black54,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: noBorder
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1),
                ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                color: textColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
        backgroundColor: Color(0xFF6902FC),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          buildLink(
            'Change login name',
            Icons.account_circle_outlined,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangeLoginNamePage()),
              );
            },
          ),
          buildLink(
            'Change password',
            Icons.lock_reset_outlined,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              );
            },
          ),
          buildLink(
            'Notification settings',
            Icons.notifications_active_outlined,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
              );
            },
          ),
          buildLink(
            'Logout',
            Icons.logout,
            () => _logout(context),
            noBorder: true,
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
