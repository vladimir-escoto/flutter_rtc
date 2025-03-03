// lib/incoming_call_screen.dart
import 'package:flutter/material.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    Key? key,
    required this.callerName,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Contact info.
            Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/100"),
                ),
                const SizedBox(height: 16),
                Text(
                  callerName,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Incoming Call",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
            // Bottom: Accept and Decline buttons.
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: onDecline,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    onPressed: onAccept,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
