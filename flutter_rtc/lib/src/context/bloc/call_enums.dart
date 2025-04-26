// call_enums.dart
// This file contains enums used to represent the lifecycle status of a call,
// the type of controls, UI events, signaling events, and the call mode.

part of 'call_bloc.dart';

class CallEvent {
  final CallLifecycleStatus type;
  final dynamic value;

  CallEvent({required this.type, this.value});
}

/// Enum representing the different lifecycle statuses of a call.
enum CallLifecycleStatus {
  initial, // No call has been initiated.
  calling, // Outgoing call is in progress.
  incoming, // Incoming call received.
  ringing, // Outgoing call is ringing.
  connecting, // Negotiation (offer/answer/ICE) is in progress.
  connected, // Call has been successfully connected.
  ended, // Call has ended normally.
  declined, // Outgoing call was cancelled before answer.
  failed, // Call failed due to an error.
  hold, // Call has been paused.
}

/// Enum for local control types.
enum LocalControlType {
  mic,
  camera,
  speaker,
  screenShare,
  callMode, // Switch between audio and video.
}

/// Enum for remote control types.
enum RemoteControlType { mic, camera, screenShare }

/// Enum for UI event types.
enum UIEventType { minimized, maximized, dragged, callTimerUpdated }

/// Enum for call mode.
enum CallMode { audio, video }
