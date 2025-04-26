// call_state.dart
// This file defines the state of the call as managed by the CallBloc.
// It includes lifecycle information, local and remote control statuses,
// UI state (e.g., minimized and position), call duration, and an optional error message.

part of 'call_bloc.dart';

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

  Member get self => callInfo.self;

  CallMode get callMode => callInfo.callMode;

  // UI state.
  final bool uiMinimized;
  final Offset uiPosition;

  // Call duration.
  final Duration callDuration;

  // Optional error message.
  final String? errorMessage;

  final MediaStream? localStream;

  //TODO: Remove this
  MediaStream? get remoteStream =>
      callInfo.members.where((p) => p.userId != callInfo.userId).firstOrNull?.mediaStream;

  //TODO: Remove this
  bool get remoteCameraOn =>
      callInfo.members
          .where((p) => p.userId != callInfo.userId)
          .firstOrNull
          ?.cameraEnabled ??
      false;

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

  CallBlocState copyWithStream(Map<String, MediaStream?> remoteStream) {
    return copyWithCallInfo(callInfo.copyAndUpdateStream(remoteStream));
  }

  CallBlocState toggleControl({
    bool? speakerEnable,
    bool? micEnabled,
    bool? cameraEnabled,
    bool? screenShareEnabled,
  }) {
    return copySelf(
      self.copyWith(
        speakerEnable: speakerEnable ?? self.speakerEnable,
        micEnabled: micEnabled ?? self.micEnabled,
        cameraEnabled: cameraEnabled ?? self.cameraEnabled,
        screenShareEnabled: screenShareEnabled ?? self.screenShareEnabled,
      ),
    );
  }

  CallBlocState setRemoteControl(
    String remoteId, {
    bool? micEnabled,
    bool? cameraEnabled,
    bool? screenShareEnabled,
  }) {
    var member = callInfo.members.where((p) => p.userId == remoteId).firstOrNull;
    if (member == null) return this;

    return copySelf(
      member.copyWith(
        micEnabled: micEnabled ?? member.micEnabled,
        cameraEnabled: cameraEnabled ?? member.cameraEnabled,
        screenShareEnabled: screenShareEnabled ?? member.screenShareEnabled,
      ),
    );
  }

  CallBlocState copySelf(Member member) {
    var members = List<Member>.from(callInfo.members);
    members.removeWhere((p) => p.userId == member.userId);
    members.add(member);
    return copyWithCallInfo(callInfo.copyWith(members: members));
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
