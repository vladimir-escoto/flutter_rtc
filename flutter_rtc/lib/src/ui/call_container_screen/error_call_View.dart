part of "../call_container_screen.dart";

class CallErrorView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;

  const CallErrorView({super.key, required this.callBloc, required this.state});

  @override
  Widget build(BuildContext context) {
    return BaseCallScreen(
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'Call error: ${state.errorMessage ?? 'Unknown error'}',
                style: const TextStyle(color: Colors.red),
              ),
              Center(
                child: IconButton(
                  icon: Icon(Icons.call_end, color: Colors.red, size: 40),
                  onPressed: () => callBloc.add(HangUpCallEvent()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
