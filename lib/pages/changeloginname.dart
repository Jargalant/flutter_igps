import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLoginNamePage extends StatefulWidget {
  const ChangeLoginNamePage({super.key});

  @override
  State<ChangeLoginNamePage> createState() => _ChangeLoginNamePageState();
}

class _ChangeLoginNamePageState extends State<ChangeLoginNamePage> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final newLogin = _controller.text.trim();
    if (newLogin.isEmpty) {
      _showAlert('Please enter a new login name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.itsystem.mn/igps/changelogin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'oldLoginName': newLogin,
          'newLoginName': newLogin,
        }),
      );

      final data = jsonDecode(response.body);
      final status = data['status'] ?? 0;

      switch (status) {
        case 1:
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('loginName', newLogin);
          _showAlert('Login name changed successfully.');
          break;
        case 2:
          _showAlert('Access denied.');
          break;
        default:
          _showAlert('Server error. Please try again.');
      }
    } on SocketException {
      _showAlert('Error. Please try again.');
    } catch (_) {
      _showAlert('Error. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notice'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Login Name')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'New login name'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
