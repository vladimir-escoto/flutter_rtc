// lib/src/ui/widgets/call_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallOverlay extends StatelessWidget {
  final bool isVideoCall;
  final MediaStream? remoteStream;
  final VoidCallback onTap;
  final Duration? callDuration;

  const CallOverlay({
    required this.isVideoCall,
    required this.remoteStream,
    required this.onTap,
    this.callDuration,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      right: 16,
      width: 120,
      height: 160,
      child: GestureDetector(
        onTap: onTap,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildContent(),
              _buildOverlayInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isVideoCall && remoteStream != null) {
      final renderer = RTCVideoRenderer()..initialize();
      renderer.srcObject = remoteStream;

      return RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    return Container(
      color: Colors.black87,
      child: const Center(
        child: Icon(Icons.call, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildOverlayInfo() {
    final durationText = callDuration != null
        ? _formatDuration(callDuration!)
        : 'On Call';

    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          durationText,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
