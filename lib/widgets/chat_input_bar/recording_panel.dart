import 'package:flutter/material.dart';

/// Panel shown during audio recording.
class RecordingPanel extends StatelessWidget {
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const RecordingPanel({
    super.key,
    required this.duration,
    required this.animationDuration,
    required this.onStop,
    required this.onCancel,
  });

  String get _formattedTime {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animationDuration,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cancel button
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: onCancel,
          ),
          // Active mic icon
          Icon(Icons.mic, color: Colors.redAccent),
          SizedBox(width: 12),
          // Timer
          Text(_formattedTime, style: TextStyle(fontSize: 16)),
          SizedBox(width: 12),
          // Slide to cancel hint
          Text('Slide up to cancel', style: TextStyle(fontSize: 14)),
          SizedBox(width: 12),
          // Stop button
          IconButton(
            icon: Icon(Icons.send, color: Colors.green),
            onPressed: onStop,
          ),
        ],
      ),
    );
  }
}
