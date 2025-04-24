part of "../call_container_screen.dart";

class IncomingCallView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;

  const IncomingCallView({required this.callBloc, required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage("https://i.pravatar.cc/100"),
            ),
            const SizedBox(height: 16),
            const Text(
              "Incoming Call",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            Text(
              state.isVideoCall ? "Video Call" : "Audio Call",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'declined',
                    backgroundColor: Colors.red,
                    onPressed: () {
                      callBloc.add(DeclineIncomingCallEvent(reason: "declined by user"));
                    },
                    child: const Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    heroTag: 'Call',
                    backgroundColor: Colors.green,
                    onPressed: () {
                      //callBloc.add(AcceptIncomingCallEvent(data: {});
                      },
                    child: const Icon(Icons.call),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}