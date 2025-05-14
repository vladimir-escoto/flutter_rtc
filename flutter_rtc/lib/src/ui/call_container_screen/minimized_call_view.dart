part of "../call_container_screen.dart";

class MinimizedCallView extends StatefulWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer renderer;

  const MinimizedCallView({
    required this.callBloc,
    required this.state,
    required this.renderer,
    super.key,
  });

  @override
  State<MinimizedCallView> createState() => _MinimizedCallViewState();
}

class _MinimizedCallViewState extends State<MinimizedCallView> with CallTimerMixin {
  @override
  DateTime get initialCreatedAt => widget.state.createdAt;

  @override
  Widget build(BuildContext context) {
    final remoteMember = widget.state.callInfo.remoteMembers.first;

    return FloatingDraggableWidget(
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
        Widget content;
        if (!(widget.renderer.renderVideo)) {
          content = _buildCircleAvatar(remoteMember.photoUrlOrId);
        } else {
          content = RTCVideoView(widget.renderer, mirror: false);
        }
        return Stack(children: [Positioned.fill(child: content), _buildTimer()]);
      },
    );
  }

  Widget _buildCircleAvatar(String url) =>
      Center(child: CircleAvatar(radius: 48, backgroundImage: NetworkImage(url)));

  Positioned _buildTimer() => Positioned(
    bottom: 8.0,
    left: 0.0,
    right: 0.0,
    child: CallDurationText(notifier: durationNotifier),
  );
}
