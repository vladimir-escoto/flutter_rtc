part of "../call_container_screen.dart";

/// Represents a set of controls the user can use on the calling screen
/// to accept/cancel the call, toggle their audio and video state.
class DeclineCallControls extends StatefulWidget {
  /// Creates a new instance of [DeclineCallControls].
  const DeclineCallControls({
    super.key,
    required this.onCallAgainTap,
    required this.onCloseCallTap,
    required this.onChatCallTap,
  });

  /// The action to perform when the user what to call again
  final VoidCallback onCallAgainTap;

  /// The action to open the user chat
  final VoidCallback onChatCallTap;

  /// The action to perform when the hang up button is tapped.
  final VoidCallback onCloseCallTap;

  @override
  State<DeclineCallControls> createState() => _DeclineCallControlsState();
}

class _DeclineCallControlsState extends State<DeclineCallControls> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CallControlOption(
                icon: Icon(Icons.close),
                iconColor: Colors.black,
                backgroundColor: Colors.white,
                onPressed: widget.onCloseCallTap,
                padding: const EdgeInsets.all(16),
                iconSize: 40,
                label: "Close",
              ),
              CallControlOption(
                icon: const Icon(Icons.chat),
                iconColor: Colors.white,
                backgroundColor: Colors.grey.withValues(alpha: 0.5),
                onPressed: widget.onChatCallTap,
                padding: const EdgeInsets.all(16),
                iconSize: 40,
                label: "Chat",
              ),
              CallControlOption(
                icon: const Icon(Icons.call),
                iconColor: Colors.white,
                backgroundColor: Colors.green,
                onPressed: widget.onCallAgainTap,
                padding: const EdgeInsets.all(16),
                iconSize: 40,
                label: "Call Again",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
