// ---------- rtc_media_handler.dart ----------
part of 'rtc_manager.dart';

class _RTCMediaHandler {
  MediaStream? _localStream;

  MediaStream? get localStream => _localStream;

  MediaStreamTrack? get videoTrack => _localStream?.getVideoTracks().first;

  /// Ensures that necessary permissions are granted.
  Future<void> _ensureHasPermissions(bool requireCamera) async {
    final statuses =
        await [
          if (requireCamera) Permission.camera,
          Permission.microphone,
          Permission.notification,
        ].request();

    final microphoneGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final _ = statuses[Permission.notification]?.isGranted ?? false;

    if (!microphoneGranted) {
      throw Exception("Required microphone permissions not granted");
    }

    if (requireCamera) {
      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      if (!cameraGranted) {
        throw Exception("Required camera permissions not granted");
      }
    }
  }

  Future<void> ensureLocalStream({
    bool enableAudio = true,
    bool enableVideo = false,
  }) async {
    _localStream ??= await navigator.mediaDevices.getUserMedia({
      'audio': enableAudio,
      'video': enableVideo ? {'facingMode': 'user'} : false,
    });
  }

  void toggleAudio(bool enabled) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = enabled);
  }

  void toggleVideo(bool enabled) {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = enabled);
  }

  Future<void> toggleScreenSharing({
    required bool isScreenSharing ,
    required Function(MediaStream) onStart,
    required Function(MediaStream) onStop,
  }) async {
    if (isScreenSharing) {
      final cameraStream = await navigator.mediaDevices.getUserMedia({'video': true});
      await _localStream?.dispose();
      _localStream = cameraStream;
      onStop(cameraStream);
    } else {
      final screenStream = await navigator.mediaDevices.getDisplayMedia({'video': true});
      onStart(screenStream);
    }
  }

  void dispose() {
    _localStream?.dispose();
    _localStream = null;
  }
}
