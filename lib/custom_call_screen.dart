import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

class CustomCallScreen extends StatelessWidget {
  final CallBloc bloc;
  final CallBlocState state;

  const CustomCallScreen({super.key, required this.bloc, required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    debugPrint('[HomeScreen] build');
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black87,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("MY CUSTOM CALL VIEW"),
            Text(state.self.id),
            ...state.callInfo.remoteMembers.map((r) => Text(r.displayNameOrId)),
            CallControlOption(
              icon: const Icon(Icons.call_end_rounded),
              iconColor: Colors.white,
              backgroundColor: Colors.red,
              onPressed: () => bloc.add(HangUpCallEvent()),
              padding: const EdgeInsets.all(24),
            ),
          ],
        ),
      ),
    );
  }
}
