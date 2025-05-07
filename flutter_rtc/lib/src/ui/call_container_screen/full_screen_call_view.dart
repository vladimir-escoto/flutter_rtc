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
    position = const Offset(0, 0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
    final localMember = widget.state.self;
    final remoteMember = widget.state.callInfo.remoteMembers.first;

    screenSize = MediaQuery.of(context).size;

    final mainRenderer = isLocalMain ? widget.localRenderer : activeRenderer!;
    final secondaryRenderer = isLocalMain ? activeRenderer! : widget.localRenderer;

    final mainStreamAvailable =
        isLocalMain ? localMember.isStreamAvailable : remoteMember.isStreamAvailable;
    final secondaryStreamAvailable =
        !isLocalMain ? localMember.isStreamAvailable : remoteMember.isStreamAvailable;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainRenderer(mainStreamAvailable, mainRenderer),
          _buildCallBar(),
          _buildControls(),
          // if (secondaryStreamAvailable || widget.state.isVideoCall)
          _buildSecondaryRenderer(secondaryStreamAvailable, secondaryRenderer),
        ],
      ),
    );
  }

  FloatingDraggableRendererWidget _buildSecondaryRenderer(
    bool secondaryStreamAvailable,
    RTCVideoRenderer? secondaryRenderer,
  ) {
    return FloatingDraggableRendererWidget(
      topMargin: 125,
      bottomMargin: 150,
      secondaryStreamAvailable: secondaryStreamAvailable,
      secondaryRenderer: secondaryRenderer,
      isLocalMain: isLocalMain,
      onTap: (status, hp, vp) {
        setState(() {
          isLocalMain = !isLocalMain;
        });
        return false;
      },
    );
  }

  Widget _buildCircleIcon(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Positioned _buildCallBar() {
    final remoteMembers = widget.state.remoteMembers;

    final titleText =
        remoteMembers.length == 1
            ? remoteMembers.first.displayName
            : '${remoteMembers.length} participants';

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCircleIcon(Icons.close_fullscreen, () {
              widget.callBloc.add(
                UIEvent(event: UIEventType.changeOverlay, value: OverlayStatus.minimized),
              );
            }),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titleText, style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(height: 4),
                Text(
                  widget.state.callDuration.toCallFormat(),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            _buildCircleIcon(Icons.person_add, () {
              // widget.callBloc.add(
              //   UIEvent(
              //     event: UIEventType.addParticipant,
              //   ),
              // );
            }),
          ],
        ),
      ),
    );
  }

  Positioned _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FullScreenCallControls(
        isScreenShareEnabled: widget.state.localScreenShareOn,
        isMicrophoneEnabled: widget.state.localMicOn,
        isCameraEnabled: widget.state.localCameraOn,
        isSpeakerEnabled: widget.state.localSpeakerOn,
        onScreenShareTap: () {
          widget.callBloc.add(
            ToggleLocalControlEvent(control: LocalControlType.screenShare),
          );
        },
        onCancelCallTap: () => widget.callBloc.add(HangUpCallEvent()),
        onMicrophoneTap: () {
          widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.mic));
        },
        onCameraTap: () {
          widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.camera));
        },
        onSpeakerTap: () {
          widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.speaker));
        },
      ),
    );
  }

  Positioned _buildMainRenderer(bool available, RTCVideoRenderer? renderer) {
    return Positioned.fill(
      child:
          available
              ? RTCVideoView(renderer!, mirror: isLocalMain)
              : const Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/140"),
                ),
              ),
    );
  }
}
