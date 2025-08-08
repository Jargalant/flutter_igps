import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  String? igpsToken = prefs.getString('igpstoken');
  String? savedLogin = prefs.getString('login');

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  String? fcmToken = await messaging.getToken();
  print('FCM Token: $fcmToken');

  // On token refresh, send new token + saved login to server
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print('FCM Token refreshed: $newToken');
    if (savedLogin != null && newToken.isNotEmpty) {
      await sendFcmTokenToServer(savedLogin, newToken);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
  });

  runApp(MyApp(startAtHome: igpsToken != null));
}

class MyApp extends StatelessWidget {
  final bool startAtHome;
  const MyApp({super.key, required this.startAtHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iGPS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: startAtHome ? const HomePage() : const LoginPage(),
    );
  }
}
