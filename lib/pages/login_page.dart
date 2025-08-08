import 'package:flutter/material.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendFcmTokenToServer(String login, String? fcmToken) async {
  if (fcmToken == null || login.isEmpty) return;

  try {
    final response = await http.post(
      Uri.parse('https://api.itsystem.mn/registerfcm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'login': login,
        'fcmtoken': fcmToken,
      }),
    );
    if (response.statusCode == 200) {
      print('FCM token registered successfully');
    } else {
      print('Failed to register FCM token: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending FCM token: $e');
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final login = _usernameController.text.trim();
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      _showAlert('Please enter login and password');
      return;
    }

    String? fcmToken = await FirebaseMessaging.instance.getToken();

    final response = await http.post(
      Uri.parse('https://api.itsystem.mn/usersignin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': login,
        'password': password,
        'fcmtoken': fcmToken,
      }),
    );

    final json = jsonDecode(response.body);
if (response.statusCode == 200 && json['token'] != null) {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('igpstoken', json['token']);
  await prefs.setString('login', login); // Save login/email

  await sendFcmTokenToServer(login, fcmToken);

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const HomePage()),
  );
} else {
  _showAlert('Invalid login name or password');
}

  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    const inputTextColor = Colors.grey;
    const inputLabelColor = Colors.grey;
    const inputBorderColor = Color(0xFFCCCCCC);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: screenHeight * 0.55,
              child: Image.asset(
                'assets/signin.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                alignment: Alignment.topCenter,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: inputTextColor),
                    decoration: InputDecoration(
                      labelText: 'Login',
                      labelStyle: const TextStyle(color: inputLabelColor),
                      prefixIcon: const Icon(Icons.person, color: Colors.grey),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: inputBorderColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: inputBorderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: inputBorderColor, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: inputTextColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: inputLabelColor),
                      prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: inputBorderColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: inputBorderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: inputBorderColor, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A02FF),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6A02FF),
                    ),
                    child: const Text(
                      "Don't have an account. Create new account",
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    children: [
                      const Text(
                        'Powered by',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/itsystem.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
