part of "../call_container_screen.dart";

class FullScreenCallView extends StatefulWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer activeRenderer;

  const FullScreenCallView({
    required this.callBloc,
    required this.state,
    required this.localRenderer,
    required this.activeRenderer,
    super.key,
  });

  @override
  State<FullScreenCallView> createState() => _FullScreenCallViewState();
}

class _FullScreenCallViewState extends State<FullScreenCallView>
    with SingleTickerProviderStateMixin, CallTimerMixin {
  bool isLocalMain = false;

  @override
  DateTime get initialCreatedAt => widget.state.createdAt;

  void _switchRenderers() {
    setState(() => isLocalMain = !isLocalMain);
  }

  @override
  Widget build(BuildContext context) {
    final localMember = widget.state.self;
    final remoteMember = widget.state.callInfo.remoteMembers.first;

    final mainRenderer = isLocalMain ? widget.localRenderer : widget.activeRenderer;
    final secondaryRenderer = isLocalMain ? widget.activeRenderer : widget.localRenderer;

    final mainStreamAvailable =
        isLocalMain ? localMember.isStreamAvailable : remoteMember.isStreamAvailable;
    final secondaryStreamAvailable =
        !isLocalMain ? localMember.isStreamAvailable : remoteMember.isStreamAvailable;

    final mainPhotoUrl =
        isLocalMain ? localMember.photoUrlOrId : remoteMember.photoUrlOrId;
    final secondaryPhotoUrl =
        !isLocalMain ? localMember.photoUrlOrId : remoteMember.photoUrlOrId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          VideoBox(
            renderer: mainRenderer,
            photoUrl: mainPhotoUrl,
            available: mainStreamAvailable,
            mirror: !isLocalMain,
          ),
          // if (secondaryStreamAvailable || widget.state.isVideoCall)
          FloatingDraggableRendererWidget(
            topMargin: 100,
            bottomMargin: 125,
            secondaryStreamAvailable: secondaryStreamAvailable,
            secondaryRenderer: secondaryRenderer,
            isLocalMain: isLocalMain,
            photoUrl: secondaryPhotoUrl,
            onTap: (status, hp, vp) {
              if (status == RenderStatus.expanded) {
                _switchRenderers();
                return true;
              }
              return false;
            },
            onSwitchCamera: () {
              widget.callBloc.add(
                ToggleLocalControlEvent(control: LocalControlType.camera),
              );
            },
          ),
          _buildCallBar(),
          _buildControls(),
        ],
      ),
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
            ? remoteMembers.first.displayNameOrId
            : '${remoteMembers.length} Participants';

    return Positioned(
      left: 16,
      right: 16,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCircleIcon(Icons.close_fullscreen, () {
              widget.callBloc.add(
                UIEvent(
                  event: UIEventType.changeOverlay,
                  value: OverlayStatus.minimized,
                ),
              );
            }),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titleText, style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(height: 4),
                CallDurationText(notifier: durationNotifier),
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

  Positioned _buildControls() => Positioned.fill(
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
