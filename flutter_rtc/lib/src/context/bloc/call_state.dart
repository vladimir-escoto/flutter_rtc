// call_state.dart
// This file defines the state of the call as managed by the CallBloc.
// It includes lifecycle information, local and remote control statuses,
// UI state (e.g., minimized and position), call duration, and an optional error message.

part of 'call_bloc.dart';

/// The state for the call, including lifecycle, local and remote control statuses,
/// UI state, call duration, and any error message.
class CallBlocState extends Equatable {
  final CallInfo callInfo;

  // UI state.
  final OverlayStatus overlayStatus;

  // Optional error message.
  final String? errorMessage;

  bool get isUiMinimized => overlayStatus == OverlayStatus.minimized;

  bool get isUiIntermediate => overlayStatus == OverlayStatus.intermediate;

  bool get isUiCollapsed => overlayStatus == OverlayStatus.collapsed;

  bool get isUiExpanded => overlayStatus == OverlayStatus.expanded;

  MediaStream? get localStream => self.mediaStream;

  // Call lifecycle status.
  CallLifeCycleStatus get lifecycleStatus => callInfo.callStatus;

  // Local control states.
  bool get localMicOn => callInfo.self.micEnabled;

  bool get localCameraOn => callInfo.self.cameraEnabled;

  bool get localSpeakerOn => callInfo.self.speakerEnable;

  bool get localScreenShareOn => callInfo.self.screenShareEnabled;

  Member get self => callInfo.self;

  bool get isOnHold => lifecycleStatus == CallLifeCycleStatus.hold;

  bool get isConnected => members.any((m) => m.status == ConnectionStatus.connected);

  CallMode get callMode => callInfo.callMode;

  List<Member> get members => callInfo.members;

  List<Member> get remoteMembers => callInfo.remoteMembers;

  bool get isVideoCall => callMode == CallMode.video;

  bool get isAudioCall => callMode == CallMode.audio;

  bool get isIncomingCall => !callInfo.isCaller;

  bool get isOutgoingCall => callInfo.isCaller;

  DateTime get createdAt => callInfo.createdAt;

  const CallBlocState({
    required this.callInfo,
    required this.overlayStatus,
    this.errorMessage,
  });

  Member getMembersById(String id) {
    return members.firstWhere(
      (m) => m.id == id,
      orElse: () => throw Exception("Member not found: memberId: $id"),
    );
  }

  factory CallBlocState.fromCallInfo(CallInfo callInfo) {
    return CallBlocState(callInfo: callInfo, overlayStatus: OverlayStatus.expanded);
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
    return copyMember(
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
    var member = callInfo.members.where((p) => p.id == remoteId).firstOrNull;
    if (member == null) return this;

    return copyMember(
      member.copyWith(
        micEnabled: micEnabled ?? member.micEnabled,
        cameraEnabled: cameraEnabled ?? member.cameraEnabled,
        screenShareEnabled: screenShareEnabled ?? member.screenShareEnabled,
      ),
    );
  }

  CallBlocState copyMember(Member member) {
    var members = List<Member>.from(callInfo.members);
    members.removeWhere((p) => p.id == member.id);
    members.add(member);
    return copyWithCallInfo(callInfo.copyWith(members: members));
  }

  CallBlocState copyWithCallInfo(CallInfo callInfo) {
    return copyWith(callInfo: callInfo);
  }

  /// Returns a copy of the current state with updated values.
  CallBlocState copyWith({
    CallInfo? callInfo,
    OverlayStatus? overlayStatus,
    Offset? uiPosition,
    Duration? callDuration,
    String? errorMessage,
  }) {
    return CallBlocState(
      overlayStatus: overlayStatus ?? this.overlayStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      callInfo: callInfo ?? this.callInfo,
    );
  }

  @override
  String toString() {
    return 'CallBlocState(lifecycleStatus: $lifecycleStatus, localMicOn: $localMicOn, localCameraOn: $localCameraOn, callMode: $callMode,  overlayStatus: $overlayStatus, , errorMessage: $errorMessage)';
  }

  @override
  List<Object?> get props => [callInfo, lifecycleStatus, overlayStatus, errorMessage];
}
