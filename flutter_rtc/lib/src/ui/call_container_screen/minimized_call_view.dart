part of "../call_container_screen.dart";

class MinimizedCallView extends StatefulWidget {
  final CallBloc callBloc;
  final CallBlocState state;

  const MinimizedCallView({
    required this.callBloc,
    required this.state,
    super.key,
  });

  @override
  State<MinimizedCallView> createState() => _MinimizedCallViewState();
}

class _MinimizedCallViewState extends State<MinimizedCallView> {

  final Map<String, RTCVideoRenderer> _remoteRenderer = {};

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  @override
  void dispose() {
    for (var renderer in _remoteRenderer.values) {
      renderer.dispose();
    }
    _remoteRenderer.clear();
    super.dispose();
  }

  Future<void> _initializeRenderer() async {
    for (var member in widget.state.callInfo.remoteMembers) {

      final renderer = _remoteRenderer.putIfAbsent(member.id, () {
        return RTCVideoRenderer();
      });

      await renderer.initialize();

      _updateRenderers(member, renderer, widget.state.isVideoCall);
    }
  }

  Future<void> _updateRenderers(Member member, RTCVideoRenderer render, bool isVideo) async {
    // // 1. Ensure renderer is initialized
    // if (render.textureId == null) {
    //   await render.initialize();
    // }

    if (!isVideo) {
      // If it's not a video track, clear any video src
      if (render.srcObject != null) {
        render.srcObject = null;
      }
      return;
    }

    // 2. Video case
    if (member.cameraEnabled) {
      // Assign only if it's different
      if (render.srcObject != member.mediaStream) {
        render.srcObject = member.mediaStream;
      }
    } else {
      // Disable video: clear srcObject
      if (render.srcObject != null) {
        render.srcObject = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: widget.state.uiPosition.dx,
          top: widget.state.uiPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              final newOffset = widget.state.uiPosition + details.delta;
              widget.callBloc.add(
                  UIEvent(event: UIEventType.dragged, value: newOffset));
            },
            onTap: () {
              widget.callBloc.add(UIEvent(event: UIEventType.changeOverlay,
                  value: OverlayStatus.expanded));
            },
            child: Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  //TODO: Replace with Active remote renderer, only one render in minimized view
                  activeRenderer != null ? RTCVideoView(activeRenderer!)
                      : Container(color: Colors.black),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Column(
                      children: [
                        Text(
                          "Connected",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        Text(widget.state.callDuration.toCallFormat(),
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 5,
                    right: 5,
                    child: Icon(Icons.call, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  RTCVideoRenderer? get activeRenderer {
    //TODO: Replace with Active remote renderer, only one render in minimized view
    return _remoteRenderer[widget.state.callInfo.remoteMembers[0].id]!;
  }
}


