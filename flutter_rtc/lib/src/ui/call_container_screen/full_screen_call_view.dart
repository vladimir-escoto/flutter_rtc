
part of "../call_container_screen.dart";

class FullScreenCallView extends StatefulWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer localRenderer;

  const FullScreenCallView({
    required this.callBloc,
    required this.state,
    required this.localRenderer,
    super.key,
  });

  @override
  State<FullScreenCallView> createState() => _FullScreenCallViewState();
}

class _FullScreenCallViewState extends State<FullScreenCallView>
    with SingleTickerProviderStateMixin {
  final Map<String, RTCVideoRenderer> _remoteRenderer = {};

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
    _initializeRenderer();
  }

  @override
  void dispose() {
    for (var renderer in _remoteRenderer.values) {
      renderer.dispose();
    }
    _remoteRenderer.clear();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderer() async {
    for (var member in widget.state.callInfo.remoteMembers) {
      final renderer = RTCVideoRenderer();
      _remoteRenderer[member.id] = renderer;
      await renderer.initialize();
      _updateRenderers(member, renderer, widget.state.isVideoCall);
    }
  }

  void _updateRenderers(Member member, RTCVideoRenderer render, bool isVideo) {
    if (isVideo && member.cameraEnabled && render.textureId != null) {
      render.srcObject = member.mediaStream;
    }
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

  RTCVideoRenderer? get activeRenderer {
    //TODO: Replace with Active remote renderer, only one render in minimized view
    return _remoteRenderer[widget.state.callInfo.remoteMembers[0].id]!;
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    final member = widget.state.callInfo.remoteMembers.first;

    final mainRenderer = isLocalMain ? widget.localRenderer : activeRenderer;
    final secondaryRenderer = isLocalMain ? activeRenderer : widget
        .localRenderer;
    final mainStreamAvailable = isLocalMain
        ? widget.state.localStream != null && widget.state.localCameraOn
        : member.mediaStream != null && member.cameraEnabled;
    final secondaryStreamAvailable = !isLocalMain
        ? widget.state.localStream != null && widget.state.localCameraOn
        : member.mediaStream != null && member.cameraEnabled;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                _buildRenderer(mainStreamAvailable, mainRenderer),
                Text(widget.state.callDuration.toCallFormat(),
                    style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ), // Main Renderer
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.red,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          iconSize: 30,
                          icon: Icon(Icons.minimize,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              widget.callBloc.add(UIEvent(
                                  event: UIEventType.changeOverlay,
                                  value: OverlayStatus.minimized)),
                        ),
                      ]),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: const NetworkImage(
                            "https://i.pravatar.cc/48"),
                        backgroundColor: Colors.grey[800],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.state.isConnected ? "Connected" : "Calling",
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
                ],
              ),
            ),
          ), // Avatar
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
                    ? RTCVideoView(secondaryRenderer!, mirror: !isLocalMain)
                    : const Icon(Icons.person, color: Colors.white, size: 60),
              ),
            ),
          ), //Secondary Renderer
// Call Controllers
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FullScreenCallControls(
              isScreenShareEnabled: widget.state.localScreenShareOn,
              isMicrophoneEnabled: widget.state.localMicOn,
              isCameraEnabled: widget.state.localCameraOn,
              isSpeakerEnabled: widget.state.localSpeakerOn,
              onScreenShareTap: () =>
                  widget.callBloc.add(
                      ToggleLocalControlEvent(
                          control: LocalControlType.screenShare)),
              onCancelCallTap: () => widget.callBloc.add(HangUpCallEvent()),
              onMicrophoneTap: () =>
                  widget.callBloc.add(
                      ToggleLocalControlEvent(control: LocalControlType.mic)),
              onCameraTap: () =>
                  widget.callBloc.add(ToggleLocalControlEvent(
                      control: LocalControlType.camera)),
              onSpeakerTap: () =>
                  widget.callBloc.add(ToggleLocalControlEvent(
                      control: LocalControlType.speaker)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenderer(bool available,
      RTCVideoRenderer? renderer) {
    return available
        ? RTCVideoView(renderer!, mirror: isLocalMain)
        : const Center(child: CircleAvatar(radius: 70,
        backgroundImage: NetworkImage("https://i.pravatar.cc/140")
    ));
  }
}
