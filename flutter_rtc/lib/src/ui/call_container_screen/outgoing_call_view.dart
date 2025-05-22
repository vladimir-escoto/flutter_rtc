part of "../call_container_screen.dart";

class OutgoingCallView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer? localRenderer;

  const OutgoingCallView({
    required this.callBloc,
    required this.state,
    required this.localRenderer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCallScreen(
      controls: _buildControls(),
      children: [
        if (state.isVideoCall && state.self.cameraEnabled)
          VideoBox(
            renderer: localRenderer,
            photoUrl: state.self.photoUrlOrId,
            available: true,
            mirror: true,
          ),
        Align(
          alignment: const FractionalOffset(0.5, 0.25),
          child: RemoteMembersCarousel(
            spacing: 10,
            members: state.remoteMembers,
            children: [
              Icon(state.isVideoCall ? Icons.videocam : Icons.call, color: Colors.white),
              Text(state.lifecycleStatus.name, style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildControls() =>OutgoingCallControls(
    isMicrophoneEnabled:state.localMicOn,
    isCameraEnabled: state.localCameraOn,
    isSpeakerEnabled: state.localSpeakerOn,
    onCancelCallTap: () =>callBloc.add(HangUpCallEvent()),
    onMicrophoneTap: () => callBloc.add(ToggleLocalControlEvent(control: LocalControlType.mic)),
    // onCameraTap: () => callBloc.add(ToggleLocalControlEvent(control: LocalControlType.camera)),
    onSpeakerTap: () => callBloc.add(ToggleLocalControlEvent(control: LocalControlType.speaker)),
  );
}