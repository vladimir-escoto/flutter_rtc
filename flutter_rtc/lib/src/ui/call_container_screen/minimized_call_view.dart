part of "../call_container_screen.dart";

class MinimizedCallView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer remoteRenderer;

  const MinimizedCallView({
    required this.callBloc,
    required this.state,
    required this.remoteRenderer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: state.uiPosition.dx,
          top: state.uiPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              final newOffset = state.uiPosition + details.delta;
              callBloc.add(UIEvent(event: UIEventType.dragged, value: newOffset));
            },
            onTap: () {
              callBloc.add(UIEvent(event: UIEventType.maximized));
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
                  state.remoteStream != null && state.remoteCameraOn
                      ? RTCVideoView(remoteRenderer)
                      : Container(color: Colors.black),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Text(
                      mapLifecycleStatusToText(state.lifecycleStatus),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
}

String mapLifecycleStatusToText(CallLifecycleStatus status) {
  switch (status) {
    case CallLifecycleStatus.calling:
      return "Calling";
    case CallLifecycleStatus.incoming:
      return "Incoming";
    case CallLifecycleStatus.ringing:
      return "Ringing";
    case CallLifecycleStatus.connecting:
      return "Connecting";
    case CallLifecycleStatus.connected:
      return "Connected";
    case CallLifecycleStatus.ended:
      return "Ended";
    case CallLifecycleStatus.declined:
      return "Declined";
    case CallLifecycleStatus.failed:
      return "Failed";
    default:
      return "";
  }
}
