import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

/// Generates a random 6-digit client ID.
String generate6DigitClientId() {
  final random = Random();
  final number = random.nextInt(900000) + 100000;
  return number.toString();
}

void main() {
  final clientId = generate6DigitClientId();
  runApp(MyApp(clientId: clientId));
}

class MyApp extends StatelessWidget {
  final String clientId;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  MyApp({required this.clientId, super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FlutterRTC Demo',
      home: HomeScreen(clientId: clientId, navigatorKey: navigatorKey),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String clientId;
  final GlobalKey<NavigatorState> navigatorKey;
  const HomeScreen({required this.clientId, required this.navigatorKey, super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterRTC flutterRTC;
  final TextEditingController _callIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize FlutterRTC with the client ID and navigator key.
    flutterRTC = FlutterRTC(clientId: widget.clientId, navigatorKey: widget.navigatorKey);
    flutterRTC.initialize().then((_) {
      print("FlutterRTC initialized with clientId: ${widget.clientId}");
    });
  }

  @override
  void dispose() {
    _callIdController.dispose();
    flutterRTC.hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    flutterRTC.checkNotificationPermission(context);
    return Scaffold(
      appBar: AppBar(title: const Text('FlutterRTC Home')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Client ID: ${widget.clientId}'),
            const SizedBox(height: 20),
            TextField(
              controller: _callIdController,
              decoration: const InputDecoration(
                labelText: 'Call ID (target)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final targetId = _callIdController.text.trim();
                if (targetId.isNotEmpty) {
                  print("Initiating call to $targetId");
                  flutterRTC.makeCall(targetId);
                }
              },
              child: const Text('Make Call'),
            ),
          ],
        ),
      ),
    );
  }
}
