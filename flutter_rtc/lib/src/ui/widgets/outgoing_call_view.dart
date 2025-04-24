part of "../call_container_screen.dart";

class OutgoingCallView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer localRenderer;

  const OutgoingCallView({
    required this.callBloc,
    required this.state,
    required this.localRenderer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (state.isVideoCall && state.localStream != null)
            Positioned.fill(child: RTCVideoView(localRenderer, mirror: true))
          else
            const Positioned.fill(
              child: Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/140"),
                ),
              ),
            ),
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: const NetworkImage("https://i.pravatar.cc/48"),
                  backgroundColor: Colors.grey[800],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Calling",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      "Contact Name",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: OutgoingCallControls(
              isMicrophoneEnabled:state.localMicOn,
              isCameraEnabled: state.localCameraOn,
              isSpeakerEnabled: state.localSpeakerOn,
              onCancelCallTap: () =>callBloc.add(HangUpCallEvent()),
              onMicrophoneTap: () => callBloc.add(ToggleLocalControlEvent(control: LocalControlType.mic)),
              onCameraTap: () => callBloc.add(ToggleLocalControlEvent(control: LocalControlType.camera)),
              onSpeakerTap: () => callBloc.add(ToggleLocalControlEvent(control: LocalControlType.speaker)),
            ),
            // child: Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     IconButton(
            //       iconSize: 30,
            //       icon: Icon(
            //         state.localMicOn ? Icons.mic : Icons.mic_off,
            //         color: Colors.white,
            //       ),
            //       onPressed:
            //           () => callBloc.add(
            //         ToggleLocalControlEvent(control: LocalControlType.mic),
            //       ),
            //     ),
            //     IconButton(
            //       iconSize: 30,
            //       icon: Icon(
            //         state.localSpeakerOn ? Icons.volume_up : Icons.volume_off,
            //         color: Colors.white,
            //       ),
            //       onPressed:
            //           () => callBloc.add(
            //         ToggleLocalControlEvent(control: LocalControlType.speaker),
            //       ),
            //     ),
            //     FloatingActionButton(
            //       heroTag: "endCall",
            //       backgroundColor: Colors.red,
            //       onPressed: () => callBloc.add(HangUpCallEvent()),
            //       child: const Icon(Icons.call_end),
            //     ),
            //   ],
            // ),
          ),
        ],
      ),
    );
  }
}