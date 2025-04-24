// call_state.dart
// This file defines the state of the call as managed by the CallBloc.
// It includes lifecycle information, local and remote control statuses,
// UI state (e.g., minimized and position), call duration, and an optional error message.

import 'dart:ui'; // for Offset
import 'package:equatable/equatable.dart';
import 'package:flutter_rtc/src/context/model/call_info.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:flutter_rtc/src/coordinator/call_coordinator.dart';

/// The state for the call, including lifecycle, local and remote control statuses,
/// UI state, call duration, and any error message.
class CallBlocState extends Equatable {
  final CallInfo callInfo;

  // Call lifecycle status.
  final CallLifecycleStatus lifecycleStatus;

  // Local control states.
  bool get localMicOn => callInfo.self.micEnabled;

  bool get localCameraOn => callInfo.self.cameraEnabled;

  bool get localSpeakerOn => callInfo.self.speakerEnable;

  bool get localScreenShareOn => callInfo.self.screenShareEnabled;

  CallMode get callMode => callInfo.callMode;

  // UI state.
  final bool uiMinimized;
  final Offset uiPosition;

  // Call duration.
  final Duration callDuration;

  // Optional error message.
  final String? errorMessage;

  final MediaStream? localStream;

  bool get isVideoCall => callMode == CallMode.video;

  bool get isAudioCall => callMode == CallMode.audio;

  bool get isIncomingCall => !callInfo.isCaller;

  bool get isOutgoingCall => callInfo.isCaller;

  const CallBlocState({
    required this.callInfo,
    required this.localStream,
    required this.lifecycleStatus,
    required this.uiMinimized,
    required this.uiPosition,
    required this.callDuration,
    this.errorMessage,
  });

  factory CallBlocState.fromCallInfo(CallInfo callInfo) {
    return CallBlocState(
      callInfo: callInfo,
      localStream: null,
      lifecycleStatus: CallLifecycleStatus.initial,
      uiMinimized: false,
      uiPosition: const Offset(20, 80),
      callDuration: Duration(),
    );
  }

  Participant get self => callInfo.self;

  CallBlocState copySelf(Participant participant) {
    callInfo.participants.removeWhere((p) => p.userId == participant.userId);
    callInfo.participants.add(participant);
    return copyWith(callInfo: callInfo);
  }

  CallBlocState copyWithCallInfo(CallInfo callInfo) {
    return copyWith(callInfo: callInfo);
  }

  /// Returns a copy of the current state with updated values.
  CallBlocState copyWith({
    CallInfo? callInfo,
    localStream,
    CallLifecycleStatus? lifecycleStatus,
    bool? uiMinimized,
    Offset? uiPosition,
    Duration? callDuration,
    String? errorMessage,
  }) {
    return CallBlocState(
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      uiMinimized: uiMinimized ?? this.uiMinimized,
      uiPosition: uiPosition ?? this.uiPosition,
      callDuration: callDuration ?? this.callDuration,
      errorMessage: errorMessage ?? this.errorMessage,
      localStream: localStream ?? this.localStream,
      callInfo: callInfo ?? this.callInfo,
    );
  }

  @override
  String toString() {
    return 'CallBlocState(lifecycleStatus: $lifecycleStatus, localMicOn: $localMicOn, localCameraOn: $localCameraOn, callMode: $callMode,  uiMinimized: $uiMinimized, callDuration: ${callDuration.inSeconds}s, errorMessage: $errorMessage)';
  }

  @override
  List<Object?> get props => [
    callInfo,
    localStream,
    lifecycleStatus,
    uiMinimized,
    uiPosition,
    callDuration,
    errorMessage,
  ];
}
