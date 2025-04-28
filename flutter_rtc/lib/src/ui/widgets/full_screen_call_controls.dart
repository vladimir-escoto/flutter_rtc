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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CallControlOption(
                  icon: isSpeakerEnabled
                      ? const Icon(Icons.volume_up)
                      : const Icon(Icons.volume_off),
                  padding: const EdgeInsets.all(16),
                  onPressed: onSpeakerTap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CallControlOption(
                  icon: isMicrophoneEnabled
                      ? const Icon(Icons.mic_rounded)
                      : const Icon(Icons.mic_off_rounded),
                  padding: const EdgeInsets.all(16),
                  onPressed: onMicrophoneTap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CallControlOption(
                  icon: isCameraEnabled
                      ? const Icon(Icons.videocam_rounded)
                      : const Icon(Icons.videocam_off_rounded),
                  padding: const EdgeInsets.all(16),
                  onPressed: onCameraTap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CallControlOption(
                  icon: isScreenShareEnabled
                      ? const Icon(Icons.screen_share_rounded)
                      : const Icon(Icons.stop_screen_share),
                  padding: const EdgeInsets.all(16),
                  onPressed: onScreenShareTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          //hang up button
          CallControlOption(
            icon: const Icon(Icons.call_end_rounded),
            iconColor: Colors.white,
            backgroundColor: Colors.red,
            onPressed: onCancelCallTap,
            padding: const EdgeInsets.all(24),
          ),
        ],
      ),
    );
  }
}
