import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty) {
      await _showDialog('Input Error', 'Please fill all fields');
      return;
    }

    if (newPass.length < 8) {
      await _showDialog('Validation Error', 'New password must be at least 8 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('igpstoken');
      final loginName = prefs.getString('login');

      if (loginName == null) {
        await _showDialog('Error', 'Login name not found. Please log in again.');
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.itsystem.mn/igps/resetpassword'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'loginName': loginName,
          'oldPassword': oldPass,
          'newPassword': newPass,
        }),
      );

      final res = jsonDecode(response.body);
      final status = res['status'];

      if (status == 1) {
        await _showDialog('Success', 'Password changed successfully');
        _oldPassController.clear();
        _newPassController.clear();
      } else if (status == 401) {
        await _showDialog('Error', 'Old password is incorrect');
      } else {
        await _showDialog('Error', 'Unknown error. Please try again.');
      }
    } catch (e) {
      await _showDialog('Server Error', 'Server not reachable. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _oldPassController,
              decoration: const InputDecoration(labelText: 'Old password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPassController,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
