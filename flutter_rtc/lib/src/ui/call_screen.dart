import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../call_manager.dart';

/// A full-screen modal call UI provided by the library.
class CallScreen extends StatefulWidget {
  final CallManager callManager;
  final VoidCallback onHangUp;
  const CallScreen({required this.callManager, required this.onHangUp, super.key});
  @override
  CallScreenState createState() => CallScreenState();
}

class CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    // Update UI when call events occur.
    widget.callManager.callEvents.listen((event) {
      setState(() {});
    });
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (widget.callManager.localStream != null) {
      _localRenderer.srcObject = widget.callManager.localStream;
    }
    if (widget.callManager.remoteStream != null) {
      _remoteRenderer.srcObject = widget.callManager.remoteStream;
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Call'), backgroundColor: Colors.black),
      body: Stack(
        children: [
          // Remote video fills the screen.
          Positioned.fill(
            child: widget.callManager.remoteStream != null
                ? RTCVideoView(_remoteRenderer)
                : Container(
              color: Colors.black,
              child: const Center(
                child: Text('Waiting for remote stream...', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          // Local video in a small overlay.
          Positioned(
            top: 40,
            right: 20,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.callManager.localStream != null
                  ? RTCVideoView(_localRenderer)
                  : Container(color: Colors.grey),
            ),
          ),
          // Hang-up button.
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                ),
                onPressed: widget.onHangUp,
                child: const Icon(Icons.call_end, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
