part of "../call_container_screen.dart";

class IncomingCallView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer localRenderer;

  const IncomingCallView({
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
        if (state.isVideoCall)
          VideoBox(
            renderer: localRenderer,
            photoUrl: state.self.photoUrlOrId,
            available: state.isVideoCall,
            mirror: true,
          ),
        Align(
          alignment: const FractionalOffset(0.5, 0.25),
          child: RemoteMembersCarousel(
            spacing: 10,
            members: state.remoteMembers,
            children: [
              Icon(state.isVideoCall ? Icons.videocam : Icons.call, color: Colors.white),
              Text("Incoming Call", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() => IncomingCallControls(
    isVideoCall: state.isVideoCall,
    onDeclineCallTap: (reason) => callBloc.add(DeclineIncomingCallEvent(reason)),
    onAcceptCallTap: () => callBloc.add(AcceptIncomingCallEvent()),
    onCallSwitch: (isVideo) {
      callBloc.add(SwitchCallModeEvent(isVideo ? CallMode.video : CallMode.audio));
    },
  );
}
