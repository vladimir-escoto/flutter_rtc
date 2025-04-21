import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoBox extends StatelessWidget {
  final RTCVideoRenderer renderer;

  const VideoBox({required this.renderer, super.key});

  @override
  Widget build(BuildContext context) {
    return RTCVideoView(renderer);
  }
}
