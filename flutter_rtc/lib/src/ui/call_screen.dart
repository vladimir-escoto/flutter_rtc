import 'dart:async';

import 'package:flutter/material.dart';
import 'video_box.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Fully functional call screen with interactive controls and timer.
class CallScreen extends StatefulWidget {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;

  /// Callback to handle call end action.
  final VoidCallback onCallEnd;

  /// Callback to toggle the microphone. Receives the new mic status.
  final Future<void> Function(bool isOn) onToggleMic;

  /// Callback to toggle the camera. Receives the new camera status.
  final Future<void> Function(bool isOn) onToggleCamera;

  /// Callback to switch between front and rear cameras.
  final Future<void> Function() onSwitchCamera;

  /// Callback to toggle the speaker. Receives the new speaker status.
  final Future<void> Function(bool isOn) onToggleSpeaker;

  const CallScreen({
    required this.localRenderer,
    required this.remoteRenderer,
    required this.onCallEnd,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onToggleSpeaker,
    super.key,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isSpeakerOn = true;
  Timer? _callTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _startCallTimer();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  // Starts a periodic timer that updates the call duration every second.
  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  // Formats the elapsed seconds into MM:SS format.
  String get formattedDuration {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video occupies the full background.
          Positioned.fill(child: VideoBox(renderer: widget.remoteRenderer)),
          // Video local in a small inset with rounded corners.
          Positioned(
            top: 40,
            right: 20,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: VideoBox(renderer: widget.localRenderer),
            ),
          ),
          // Caller info and call duration at the top.
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'John Doe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDuration,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Control buttons at the bottom.
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: isMicOn ? Icons.mic : Icons.mic_off,
                  label: "Mic",
                  onPressed: () async {
                    setState(() => isMicOn = !isMicOn);
                    await widget.onToggleMic(isMicOn);
                  },
                ),
                _buildControlButton(
                  icon: Icons.switch_video,
                  label: "Switch",
                  onPressed: () async {
                    await widget.onSwitchCamera();
                  },
                ),
                _buildControlButton(
                  icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
                  label: "Camera",
                  onPressed: () async {
                    setState(() => isCameraOn = !isCameraOn);
                    await widget.onToggleCamera(isCameraOn);
                  },
                ),
                _buildControlButton(
                  icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                  label: "Speaker",
                  onPressed: () async {
                    setState(() => isSpeakerOn = !isSpeakerOn);
                    await widget.onToggleSpeaker(isSpeakerOn);
                  },
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  backgroundColor: Colors.red,
                  label: "End",
                  onPressed: widget.onCallEnd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a circular control button with an icon and label.
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    Color backgroundColor = Colors.grey,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor.withValues(alpha: 0.8),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
