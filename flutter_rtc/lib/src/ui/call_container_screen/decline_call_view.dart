import 'package:flutter/material.dart';

import '../../bloc/call_bloc.dart';
import '../../bloc/call_events.dart';

class DeclineCallView extends StatelessWidget {
  final CallBloc callBloc;

  const DeclineCallView({required this.callBloc, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            const Text(
              'Call failed or declined',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => callBloc.add(RedialCallEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
