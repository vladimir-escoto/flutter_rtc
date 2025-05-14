part of "../call_container_screen.dart";

class DeclineCallView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;

  const DeclineCallView({required this.callBloc, super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return BaseCallScreen(
      controls: _buildControls(),
      children: [
        Align(
          alignment: const FractionalOffset(0.5, 0.25),
          child: RemoteMembersCarousel(
            spacing: 10,
            fontSize: 20,
            members: state.remoteMembers,
            children: [
              Text("Not Answer", style: TextStyle(color: Colors.white, fontSize: 24)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() => DeclineCallControls(
    onCloseCallTap: () => callBloc.add(HangUpCallEvent()),
    onCallAgainTap: () => callBloc.add(StartOutgoingCallEvent()),
    onChatCallTap: () => callBloc.add(HangUpCallEvent()),
  );
}
