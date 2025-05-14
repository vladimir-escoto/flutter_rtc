part of "../call_container_screen.dart";

class HoldCallView extends StatefulWidget {
  final CallBloc callBloc;
  final CallBlocState state;

  const HoldCallView({
    super.key,
    required this.callBloc, // make parameters const
    required this.state, // make parameters const
  });

  @override
  State<HoldCallView> createState() => _HoldCallViewState();
}

class _HoldCallViewState extends State<HoldCallView>
    with SingleTickerProviderStateMixin, CallTimerMixin {
  @override
  DateTime get initialCreatedAt => widget.state.createdAt;

  @override
  Widget build(BuildContext context) {
    return BaseCallScreen(
      topBar: _buildCallBar(),
      controls: _buildControls(),
      children: [SizedBox.shrink()],
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
                Text(
                  titleText,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
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
        widget.callBloc.add(
          ToggleLocalControlEvent(control: LocalControlType.mic),
        );
      },
      onCameraTap: () {
        widget.callBloc.add(
          ToggleLocalControlEvent(control: LocalControlType.camera),
        );
      },
      onSpeakerTap: () {
        widget.callBloc.add(
          ToggleLocalControlEvent(control: LocalControlType.speaker),
        );
      },
    ),
  );
}
