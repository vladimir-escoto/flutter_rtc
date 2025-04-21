import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

/// Generates a random 6-digit client ID.
String generate6DigitClientId() {
  final random = Random();
  final number = random.nextInt(10);
  return number.toString();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  final clientId = generate6DigitClientId();
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp(clientId: clientId));
}

class MyApp extends StatelessWidget {
  final String clientId;

  const MyApp({required this.clientId, super.key});

  @override
  Widget build(BuildContext context) {
    // The FlutterRTCWidget encapsulates the MaterialApp and internal navigator.
    return FlutterRTCWidget(
      navigatorKey: GlobalKey<NavigatorState>(),
      clientId: clientId,
      child: HomeScreen(clientId: clientId),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String clientId;

  const HomeScreen({required this.clientId, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _callIdController = TextEditingController();

  @override
  void dispose() {
    _callIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flutterRTC = FlutterRTCWidget.of(context);

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
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim();
                    if (targetId.isNotEmpty) {
                      flutterRTC?.makeVideCall(targetId);
                    }
                  },
                  child: const Text('Make Video Call'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim();
                    if (targetId.isNotEmpty) {
                      flutterRTC?.makeAudioCall(targetId);
                    }
                  },
                  child: const Text('Make Audio Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
