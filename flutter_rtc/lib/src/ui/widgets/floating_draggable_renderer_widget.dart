import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/ui/widgets/floating_draggable_widget.dart';
import 'package:flutter_rtc/src/ui/widgets/video_box.dart';
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
  final VoidCallback? onSwitchCamera;
  final HorizontalPosition initialHPos;
  final VerticalPosition initialVPos;
  final String? photoUrl;

  const FloatingDraggableRendererWidget({
    super.key,
    required this.secondaryStreamAvailable,
    required this.secondaryRenderer,
    required this.isLocalMain,
    required this.onTap,
    required this.onSwitchCamera,
    required this.topMargin,
    required this.bottomMargin,
    required this.photoUrl,
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
      backgroundColor: Colors.grey.shade800,
      onTap: onTap,
      builder: (ctx, status, hPos, vPos) {
        Widget content = VideoBox(
          renderer: secondaryRenderer!,
          photoUrl: photoUrl,
          available: secondaryStreamAvailable,
          mirror: !isLocalMain,
        );

        if (isLocalMain) {
          return Stack(
            children: [
              Positioned.fill(child: content),
              if (isLocalMain && status == RenderStatus.expanded) ...[
                Positioned(
                  top: 8,
                  right: 8,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white54,
                    onPressed: onSwitchCamera,
                    child: const Icon(Icons.switch_camera, color: Colors.white),
                  ),
                ),
              ],
            ],
          );
        }
        return content;
      },
    );
  }
}
