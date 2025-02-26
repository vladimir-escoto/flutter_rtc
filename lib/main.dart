import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterRTC flutterRTC;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    // Initialize the package with the client id.
    flutterRTC = FlutterRTC(clientId: 'client_12345');
    flutterRTC.initialize().then((_) {
      // Listen for call events if needed.
      flutterRTC.callManager.callEvents.listen((event) {
        if (event == CallEvent.remoteStreamAdded) {
          // Assign the remote stream to the renderer.
          setState(() {
            _remoteRenderer.srcObject = flutterRTC.callManager.remoteStream;
          });
        }
      });
      // Also assign the local stream to its renderer.
      setState(() {
        _localRenderer.srcObject = flutterRTC.callManager.localStream;
      });
    });
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    flutterRTC.hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterRTC Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('FlutterRTC Example')),
        body: Column(
          children: [
            Expanded(child: RTCVideoView(_localRenderer)),
            Expanded(
              child: flutterRTC.callManager.remoteStream != null
                  ? RTCVideoView(_remoteRenderer)
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          'Waiting for remote stream...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Make a call to another client (for example, "client_67890").
                    flutterRTC.makeCall('client_67890');
                  },
                  child: const Text('Make Call'),
                ),
                ElevatedButton(
                  onPressed: () {
                    flutterRTC.hangUp();
                  },
                  child: const Text('Hang Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
