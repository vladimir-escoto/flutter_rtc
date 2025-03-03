// call_state.dart
// This file defines the state of the call as managed by the CallBloc.
// It includes lifecycle information, local and remote control statuses,
// UI state (e.g., minimized and position), call duration, and an optional error message.

import 'dart:ui'; // for Offset
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_enums.dart';

/// The state for the call, including lifecycle, local and remote control statuses,
/// UI state, call duration, and any error message.
class CallBlocState {
  // Call lifecycle status.
  final CallLifecycleStatus lifecycleStatus;

  // Local control states.
  final bool localMicOn;
  final bool localCameraOn;
  final bool localSpeakerOn;
  final bool localScreenShareOn;
  final CallMode callMode;

  // Remote control states.
  final bool remoteMicOn;
  final bool remoteCameraOn;
  final bool remoteScreenShareOn;

  // UI state.
  final bool uiMinimized;
  final Offset uiPosition;

  // Call duration.
  final Duration callDuration;

  // Optional error message.
  final String? errorMessage;

  final MediaStream? localStream;
  final MediaStream? remoteStream;

  const CallBlocState( {
    required this.localStream,
    required this.remoteStream,
    required this.lifecycleStatus,
    required this.localMicOn,
    required this.localCameraOn,
    required this.localSpeakerOn,
    required this.localScreenShareOn,
    required this.callMode,
    required this.remoteMicOn,
    required this.remoteCameraOn,
    required this.remoteScreenShareOn,
    required this.uiMinimized,
    required this.uiPosition,
    required this.callDuration,
    this.errorMessage,
  });

  /// Returns a copy of the current state with updated values.
  CallBlocState copyWith({
    localStream,
    remoteStream,
    CallLifecycleStatus? lifecycleStatus,
    bool? localMicOn,
    bool? localCameraOn,
    bool? localSpeakerOn,
    bool? localScreenShareOn,
    CallMode? callMode,
    bool? remoteMicOn,
    bool? remoteCameraOn,
    bool? remoteScreenShareOn,
    bool? uiMinimized,
    Offset? uiPosition,
    Duration? callDuration,
    String? errorMessage,
  }) {
    return CallBlocState(
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      localMicOn: localMicOn ?? this.localMicOn,
      localCameraOn: localCameraOn ?? this.localCameraOn,
      localSpeakerOn: localSpeakerOn ?? this.localSpeakerOn,
      localScreenShareOn: localScreenShareOn ?? this.localScreenShareOn,
      callMode: callMode ?? this.callMode,
      remoteMicOn: remoteMicOn ?? this.remoteMicOn,
      remoteCameraOn: remoteCameraOn ?? this.remoteCameraOn,
      remoteScreenShareOn: remoteScreenShareOn ?? this.remoteScreenShareOn,
      uiMinimized: uiMinimized ?? this.uiMinimized,
      uiPosition: uiPosition ?? this.uiPosition,
      callDuration: callDuration ?? this.callDuration,
      errorMessage: errorMessage?? this.errorMessage,
      localStream: localStream??this.localStream,
      remoteStream: remoteStream??this.remoteStream,
    );
  }

  @override
  String toString() {
    return 'CallBlocState(lifecycleStatus: $lifecycleStatus, localMicOn: $localMicOn, localCameraOn: $localCameraOn, callMode: $callMode, remoteMicOn: $remoteMicOn, remoteCameraOn: $remoteCameraOn, uiMinimized: $uiMinimized, callDuration: ${callDuration.inSeconds}s, errorMessage: $errorMessage)';
  }
}

/// The initial state for the call BLoC.
final CallBlocState initialCallBlocState = CallBlocState(
  lifecycleStatus: CallLifecycleStatus.initial,
  localMicOn: true,
  localCameraOn: true,
  localSpeakerOn: true,
  localScreenShareOn: false,
  callMode: CallMode.video,
  remoteMicOn: true,
  remoteCameraOn: true,
  remoteScreenShareOn: false,
  uiMinimized: false,
  uiPosition: const Offset(20, 80),
  callDuration: Duration.zero,
  errorMessage: null,
  localStream: null,
  remoteStream: null,
);
