// call_enums.dart
// This file contains enums used to represent the lifecycle status of a call,
// the type of controls, UI events, signaling events, and the call mode.

part of 'call_bloc.dart';

class CallEvent {
  final CallLifeCycleStatus type;
  final dynamic value;

  CallEvent(this.type, {this.value});
}

class PeerCallEvent {
  final String memberId;
  final ConnectionStatus type;
  final dynamic value;

  PeerCallEvent(this.memberId, this.type, {this.value});
}

enum OverlayStatus { minimized, intermediate, collapsed, expanded }

/// Enum representing the different lifecycle statuses of a call.
enum CallLifeCycleStatus {
  initial, // No call has been initiated.
  calling, // Outgoing call is in progress.
  incoming, // Incoming call received.
  ringing, // Outgoing call is ringing.
  active, // Call is active.
  hold, // Call has been paused.
  declined, // Outgoing call was cancelled before answer.
  failed, // Call failed due to an error.
  ended, // Call has ended normally.
}

/// Enum representing the different lifecycle statuses of a Member Connection.
enum ConnectionStatus {
  connecting, // Negotiation (offer/answer/ICE) is in progress.
  connected, // Call has been successfully connected.
  disconnected, // Call has been disconnected.
  ended, // Call has ended normally.
  failed, // Call failed due to an error.
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
enum UIEventType { changeOverlay, dragged, callTimerUpdated }

/// Enum for call mode.
enum CallMode { audio, video }
