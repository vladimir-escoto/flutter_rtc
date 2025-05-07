import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

/// Generates a random 6-digit client ID.
String generate6DigitClientId() {
  final random = Random();
  final number = random.nextInt(10);
  return number.toString();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CallCoordinator.instance.initialize();
  runApp(MyApp());
}

final globalNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      builder: (context, child) {
        return CallOverlay(
          child: child!,
          //     outgoingView: (context, bloc, state) {
          //   return Container(
          //     width: double.infinity,
          //     height: double.infinity,
          //     color: Colors.black87,
          //     child: Center(
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Text("Test Builder"),
          //           Text(state.self.id),
          //           Text(state.callInfo.members.first.id),
          //
          //           CallControlOption(
          //             icon: const Icon(Icons.call_end_rounded),
          //             iconColor: Colors.white,
          //             backgroundColor: Colors.red,
          //             onPressed: () =>
          //                bloc.add(HangUpCallEvent()),
          //             padding: const EdgeInsets.all(24),
          //           ),
          //         ],
          //       ),
          //     ),
          //   );
          // }
        );
      },
      home: HomeScreen(),
    );
  }
}

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint('[HomeScreen] build');
//     return Scaffold(
//       appBar: AppBar(title: Text('Universal Call Overlay Example')),
//       body: Center(
//         child: ElevatedButton(
//           child: Text("Start New Call"),
//           onPressed: () => CallCoordinator.instance.simulateCall(),
//         ),
//       ),
//     );
//   }
// }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _callIdController = TextEditingController();

  final clientId = generate6DigitClientId();

  @override
  void initState() {
    super.initState();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  void dispose() {
    _callIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final flutterRTC = FlutterRTCWidget.of(context);

    CallCoordinator.instance.onGlobalEvent.listen((event) {
      if (event is SignalingEvent && event.type == SignalingEventType.connected) {
        CallCoordinator.instance.registerUser(clientId);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('RTC Demo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Client ID: $clientId',
              style: TextStyle(
                decoration: TextDecoration.none,
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _callIdController,
              decoration: const InputDecoration(
                labelText: 'Call ID (target) or Group call user1:user2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim();
                    if (targetId.isNotEmpty) {
                      CallCoordinator.instance.startSingleCall(
                        clientId,
                        targetId,
                        mode: CallMode.video,
                      );
                    }
                  },
                  child: const Text('Make Video Call'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim();
                    if (targetId.isNotEmpty) {
                      CallCoordinator.instance.startSingleCall(clientId, targetId);
                    }
                  },
                  child: const Text('Make Audio Call'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    CallCoordinator.instance.clearAllSessions();
                  },
                  child: const Text('Clear All Sessions'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    if (targetId.isNotEmpty) {
                      CallCoordinator.instance.simulateCall(
                        userId: clientId,
                        members: [Member(id: targetId.first), Member(id: targetId.last)],
                      );
                    }
                  },
                  child: const Text('Group Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
