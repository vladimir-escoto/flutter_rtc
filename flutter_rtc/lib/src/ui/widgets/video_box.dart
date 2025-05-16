import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoBox extends StatelessWidget {
  final RTCVideoRenderer? renderer;
  final String? photoUrl;
  final bool available;
  final bool mirror;

  const VideoBox({
    super.key,
    required this.renderer,
    required this.photoUrl,
    required this.available,
    required this.mirror,
  });

  @override
  Widget build(BuildContext context) {
    if (available && renderer != null && renderer!.renderVideo) {
      return RTCVideoView(renderer!, mirror: mirror);
    } else if (photoUrl != null && photoUrl?.isNotEmpty == true) {
      return Center(
        child: CircleAvatar(radius: 48, backgroundImage: NetworkImage(photoUrl!)),
      );
    }

    return const Center(child: Icon(Icons.person, size: 48, color: Colors.white));
  }
}
