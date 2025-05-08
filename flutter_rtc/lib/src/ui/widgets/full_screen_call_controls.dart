part of "../call_container_screen.dart";

/// Represents a set of controls the user can use on the calling screen
/// to accept/cancel the call, toggle their audio and video state.
class FullScreenCallControls extends StatelessWidget {
  /// Creates a new instance of [FullScreenCallControls].
  const FullScreenCallControls({
    super.key,
    this.isMicrophoneEnabled = false,
    this.isCameraEnabled = false,
    this.isSpeakerEnabled = false,
    this.isScreenShareEnabled = false,
    required this.onCancelCallTap,
    required this.onMicrophoneTap,
    required this.onCameraTap,
    required this.onSpeakerTap,
    required this.onScreenShareTap,
  });

  /// If camera is enabled.
  final bool isCameraEnabled;

  /// If microphone is enabled.
  final bool isMicrophoneEnabled;

  /// If microphone is enabled.
  final bool isSpeakerEnabled;

  /// If screen share is enabled.
  final bool isScreenShareEnabled;

  /// The action to perform when the hang up button is tapped.
  final VoidCallback onCancelCallTap;

  /// The action to perform when the microphone button is tapped.
  final VoidCallback onMicrophoneTap;

  /// The action to perform when the camera button is tapped.
  final VoidCallback onCameraTap;

  /// The action to perform when the Speaker button is tapped.
  final VoidCallback onSpeakerTap;

  /// The action to perform when the Screen Share button is tapped.
  final VoidCallback onScreenShareTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            margin: const EdgeInsets.symmetric(vertical: 16,horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CallControlOption(
                  icon: const Icon(Icons.volume_up),
                  isEnable: isSpeakerEnabled,
                  disableIcon: const Icon(Icons.volume_off),
                  onPressed: onSpeakerTap,
                ),
                CallControlOption(
                  icon: const Icon(Icons.mic_rounded),
                  isEnable: isMicrophoneEnabled,
                  disableIcon: const Icon(Icons.mic_off_rounded),
                  onPressed: onMicrophoneTap,
                ),
                CallControlOption(
                  icon: const Icon(Icons.videocam_rounded),
                  isEnable: isCameraEnabled,
                  disableIcon: const Icon(Icons.videocam_off_rounded),
                  onPressed: onCameraTap,
                ),
                CallControlOption(
                  isEnable: isScreenShareEnabled,
                  icon: const Icon(Icons.screen_share_rounded),
                  disableIcon: const Icon(Icons.stop_screen_share),
                  onPressed: onScreenShareTap,
                ),
                CallControlOption(
                  icon: const Icon(Icons.call_end_rounded),
                  iconColor: Colors.white,
                  backgroundColor: Colors.red,
                  onPressed: onCancelCallTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
