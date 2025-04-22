import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../bloc/call_bloc.dart';
import '../../bloc/call_enums.dart';
import '../../bloc/call_events.dart';
import '../../bloc/call_state.dart';

class CallScreenView extends StatefulWidget {
  final CallBlocOld callBloc;
  final CallBlocState state;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;

  const CallScreenView({
    required this.callBloc,
    required this.state,
    required this.localRenderer,
    required this.remoteRenderer,
    super.key,
  });

  @override
  State<CallScreenView> createState() => _CallScreenViewState();
}

class _CallScreenViewState extends State<CallScreenView> with SingleTickerProviderStateMixin {
  bool isLocalMain = false;
  late Offset position;
  late Size screenSize;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    position = const Offset(20, 80);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchRenderers() {
    setState(() => isLocalMain = !isLocalMain);
  }

  Offset _closestCorner(Offset offset) {
    final corners = [
      const Offset(20, 80),
      Offset(screenSize.width - 120, 80),
      Offset(20, screenSize.height - 220),
      Offset(screenSize.width - 120, screenSize.height - 220),
    ];

    corners.sort((a, b) => (a - offset).distance.compareTo((b - offset).distance));
    return corners.first;
  }

  void _animateToClosestCorner(Offset offset) {
    final closest = _closestCorner(offset);
    _animation = Tween<Offset>(begin: position, end: closest).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
      setState(() => position = _animation.value);
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;

    final mainRenderer = isLocalMain ? widget.localRenderer : widget.remoteRenderer;
    final secondaryRenderer = isLocalMain ? widget.remoteRenderer : widget.localRenderer;
    final mainStreamAvailable = isLocalMain
        ? widget.state.localStream != null && widget.state.localCameraOn
        : widget.state.remoteStream != null && widget.state.remoteCameraOn;
    final secondaryStreamAvailable = !isLocalMain
        ? widget.state.localStream != null && widget.state.localCameraOn
        : widget.state.remoteStream != null && widget.state.remoteCameraOn;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: mainStreamAvailable
                ? RTCVideoView(mainRenderer, mirror: isLocalMain)
                : const Center(
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage("https://i.pravatar.cc/140"),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: const NetworkImage("https://i.pravatar.cc/48"),
                  backgroundColor: Colors.grey[800],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.state.lifecycleStatus == CallLifecycleStatus.connected
                          ? "Connected"
                          : "Calling",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "Contact Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
              onPanUpdate: (details) => setState(() => position += details.delta),
              onPanEnd: (details) => _animateToClosestCorner(position),
              onTap: _switchRenderers,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey,
                ),
                child: secondaryStreamAvailable
                    ? RTCVideoView(secondaryRenderer, mirror: !isLocalMain)
                    : const Icon(Icons.person, color: Colors.white, size: 60),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 30,
                  icon: Icon(
                    widget.state.localMicOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  ),
                  onPressed: () => widget.callBloc.add(
                    ToggleLocalControlEvent(control: LocalControlType.mic),
                  ),
                ),
                IconButton(
                  iconSize: 30,
                  icon: Icon(
                    widget.state.localSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: () => widget.callBloc.add(
                    ToggleLocalControlEvent(control: LocalControlType.speaker),
                  ),
                ),
                FloatingActionButton(
                  heroTag: "endCall",
                  backgroundColor: Colors.red,
                  onPressed: () => widget.callBloc.add(HangUpCallEvent()),
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
