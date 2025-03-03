// call_enums.dart
// This file contains enums used to represent the lifecycle status of a call,
// the type of controls, UI events, signaling events, and the call mode.

/// Enum representing the different lifecycle statuses of a call.
enum CallLifecycleStatus {
  initial,    // No call has been initiated.
  initiated,  // Call process has started.
  outgoing,   // Outgoing call is in progress.
  incoming,   // Incoming call received.
  ringing,    // Incoming call is ringing.
  connecting, // Negotiation (offer/answer/ICE) is in progress.
  connected,  // Call has been successfully connected.
  ended,      // Call has ended normally.
  declined,   // Call was declined.
  cancelled,  // Outgoing call was cancelled before answer.
  failed,     // Call failed due to an error.
  timedOut,   // Call timed out (no answer within expected time).
}

/// Enum for local control types.
enum LocalControlType {
  mic,
  camera,
  speaker,
  screenshare,
  callMode, // Switch between audio and video.
}

/// Enum for remote control types.
enum RemoteControlType {
  mic,
  camera,
  screenshare,
}

/// Enum for UI event types.
enum UIEventType {
  minimized,
  maximized,
  dragged,
  callTimerUpdated,
  callStatusChanged,
}

/// Enum for signaling event types.
enum SignalingEventType {
  iceCandidate,
  dataChannelMessage,
  connectionQualityChanged,
}

/// Enum for call mode.
enum CallMode {
  audio,
  video,
}

