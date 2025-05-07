import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/ui/widgets/floating_draggable_widget.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// A specialized widget for rendering a secondary video feed
/// using [FloatingDraggableWidget].
class FloatingDraggableRendererWidget extends StatelessWidget {
  final bool secondaryStreamAvailable;
  final RTCVideoRenderer? secondaryRenderer;
  final bool isLocalMain;
  final TabCallback onTap;
  final double topMargin;
  final double bottomMargin;
  final HorizontalPosition initialHPos;
  final VerticalPosition initialVPos;

  const FloatingDraggableRendererWidget({
    super.key,
    required this.secondaryStreamAvailable,
    required this.secondaryRenderer,
    required this.isLocalMain,
    required this.onTap,
    required this.topMargin,
    required this.bottomMargin,
    this.initialHPos = HorizontalPosition.right,
    this.initialVPos = VerticalPosition.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingDraggableWidget(
      topMargin: topMargin,
      bottomMargin: bottomMargin,
      initialHPos: initialHPos,
      initialVPos: initialVPos,
      onTap: onTap,
      builder: (ctx, status, hPos, vPos) {
        if (!secondaryStreamAvailable) {
          return const Center(child: Icon(Icons.person, color: Colors.white, size: 60));
        }
        return RTCVideoView(secondaryRenderer!, mirror: !isLocalMain);
      },
    );
  }
}
