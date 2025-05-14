part of "../call_container_screen.dart";

/// Represents a set of controls the user can use on the calling screen
/// to accept/cancel the call, toggle their audio and video state.
class IncomingCallControls extends StatefulWidget {
  /// Creates a new instance of [IncomingCallControls].
  const IncomingCallControls({
    super.key,
    this.isVideoCall = false,
    required this.onAcceptCallTap,
    required this.onDeclineCallTap,
    required this.onCallSwitch,
    this.messages = const [
      "Busy right now, please wait",
      "In a meeting, i'll call after",
      "Can't talk, text me",
    ],
  });

  final List<String> messages;

  /// If the call is a video call.
  final bool isVideoCall;

  /// The action to perform when the accept call button is tapped.
  final VoidCallback onAcceptCallTap;

  /// The action to perform when the hang up button is tapped.
  final ValueChanged<String> onDeclineCallTap;

  /// The action to perform when the camera button is tapped.
  final ValueChanged<bool> onCallSwitch;

  @override
  State<IncomingCallControls> createState() => _IncomingCallControlsState();
}

class _IncomingCallControlsState extends State<IncomingCallControls> {
  bool isExpanded = false;
  static const _animDuration = Duration(milliseconds: 200);
  static const _animCurve = Curves.easeInOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      //decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.5)),
      padding: const EdgeInsets.only(bottom: 64, left: 16, right: 16),
      child: Column(
        children: [
          CallControlOption(
            icon: const Icon(Icons.chat),
            iconColor: Colors.white,
            backgroundColor: Colors.grey.withValues(alpha: 0.5),
            onPressed: () => setState(() => isExpanded = !isExpanded),
            padding: const EdgeInsets.all(16),
            iconSize: 24,
          ),
          AnimatedSize(
            duration: _animDuration,
            curve: _animCurve,
            child: isExpanded
                ? Column(children: [
              const SizedBox(height: 16),
              ..._buildAnimatedMessages()
            ],
            ) : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CallControlOption(
                icon: const Icon(Icons.call_end_rounded),
                iconColor: Colors.white,
                backgroundColor: Colors.redAccent,
                onPressed: () => widget.onDeclineCallTap(""),
                padding: const EdgeInsets.all(16),
                iconSize: 48,
              ),

              CallModeSwitch(isVideo: widget.isVideoCall,
                  onChanged: widget.onCallSwitch),

              CallControlOption(
                icon: Icon(widget.isVideoCall ? Icons.videocam : Icons.call),
                iconColor: Colors.white,
                backgroundColor: Colors.green,
                onPressed: widget.onAcceptCallTap,
                padding: const EdgeInsets.all(16),
                iconSize: 48,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedMessages() {
    return widget.messages.map((msg) {
      return AnimatedOpacity(
        duration: _animDuration,
        curve: _animCurve,
        opacity: isExpanded ? 1.0 : 0.0,
        child: _MessageBadge(
          text: msg,
          onTap: widget.onDeclineCallTap,
        ),
      );
    }).toList();
  }
}


class _MessageBadge extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTap;

  const _MessageBadge({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(text),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class CallModeSwitch extends StatelessWidget {
  final bool isVideo;
  final ValueChanged<bool> onChanged;

  const CallModeSwitch({
    super.key,
    required this.isVideo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = Colors.white.withValues(alpha: 0.2);

    final activeCircleColor = Theme
        .of(context)
        .colorScheme
        .primary
        .withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionButton(
            icon: Icons.videocam,
            selected: isVideo,
            activeColor: activeCircleColor,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 8),
          _OptionButton(
            icon: Icons.call,
            selected: !isVideo,
            activeColor: activeCircleColor,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? activeColor : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 24,
          color: selected ? Colors.white : Colors.grey.shade300,
        ),
      ),
    );
  }
}




