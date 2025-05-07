part of "../call_container_screen.dart";

class MinimizedCallView extends StatefulWidget {
  final CallBloc callBloc;
  final CallBlocState state;

  const MinimizedCallView({required this.callBloc, required this.state, super.key});

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

  Future<void> _updateRenderers(
    Member member,
    RTCVideoRenderer render,
    bool isVideo,
  ) async {
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
        FloatingDraggableWidget(
          topMargin: 100,
          bottomMargin: 16,
          initialHPos: HorizontalPosition.right,
          initialVPos: VerticalPosition.top,
          backgroundColor: Colors.grey.shade800,
          onTap: (status, hp, vp) {
            widget.callBloc.add(
              UIEvent(event: UIEventType.changeOverlay, value: OverlayStatus.expanded),
            );
            return true;
          },
          builder: (ctx, status, hPos, vPos) {
            if (!(activeRenderer?.renderVideo ?? false)) {
              return const Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/141"),
                ),
              );
            }
            return RTCVideoView(activeRenderer!, mirror: false);
          },
        ),
      ],
    );
  }

  RTCVideoRenderer? get activeRenderer {
    //TODO: Replace with Active remote renderer, only one render in minimized view
    return _remoteRenderer[widget.state.callInfo.remoteMembers[0].id]!;
  }
}
