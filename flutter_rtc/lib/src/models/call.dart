// ignore_for_file: deprecated_member_use_from_same_package

import 'package:equatable/equatable.dart';
import 'package:flutter_rtc/src/call/call_connect_options.dart';
import 'package:flutter_rtc/src/call/call_reject_reason.dart';

import 'call_participant_state.dart';
import 'call_status.dart';

class Call {
  CallConnectOptions connectOptions = CallConnectOptions();

  // CallStatus state = CallStatusIncoming(acceptedByMe: false);

  late final Stream<CallState> callStateStream = Stream.value(
    CallStatusIncoming(acceptedByMe: false) as CallState,
  );

  var state = null;

  var stats;

  get callEvents => null;

  accept() {}

  reject({required CallRejectReason reason}) {}

  join({CallConnectOptions? connectOptions}) {}

  void leave() {}

  void startRecording() {}

  void stopRecording() {}

  void setMicrophoneEnabled({required bool enabled}) {}

  void startClosedCaptions() {}

  void stopClosedCaptions() {}

  void setCameraEnabled({required bool enabled}) {}

  void flipCamera() {}

  void sendReaction({required String reactionType, String? emojiCode}) {}

  getOrCreate() {}

  getTrack(trackIdPrefix, param1) {}
}

class StreamTargetResolution {}

class RtcLocalTrack<T> {
  var trackType;

  var trackId;
}

class CallState extends Equatable {
  factory CallState({required String currentUserId, required String callCid}) {
    return CallState._(
      currentUserId: currentUserId,
      callCid: callCid,
      createdByUserId: '',
      isRingingFlow: false,
      sessionId: '',
      // status: CallStatus.idle(),
      status: CallStatus.connected(),
      isRecording: false,
      isBroadcasting: false,
      isTranscribing: false,
      isCaptioning: false,
      isBackstage: false,
      isAudioProcessing: false,
      rtmpIngress: '',
      capabilitiesByRole: const {},
      createdAt: null,
      updatedAt: null,
      startsAt: null,
      endedAt: null,
      liveStartedAt: null,
      liveEndedAt: null,
      timerEndsAt: null,
      latencyHistory: const [],
      blockedUserIds: const [],
      participantCount: 0,
      anonymousParticipantCount: 0,
      iOSMultitaskingCameraAccessEnabled: false,
      custom: const {},
    );
  }

  const CallState._({
    required this.currentUserId,
    required this.callCid,
    required this.createdByUserId,
    required this.isRingingFlow,
    required this.sessionId,
    required this.status,
    required this.isRecording,
    required this.isBroadcasting,
    required this.isTranscribing,
    required this.isCaptioning,
    required this.isBackstage,
    required this.isAudioProcessing,

    required this.rtmpIngress,

    required this.capabilitiesByRole,

    required this.createdAt,
    required this.updatedAt,
    required this.startsAt,
    required this.endedAt,
    required this.liveStartedAt,
    required this.liveEndedAt,
    required this.timerEndsAt,

    required this.latencyHistory,
    required this.blockedUserIds,
    required this.participantCount,
    required this.anonymousParticipantCount,
    required this.iOSMultitaskingCameraAccessEnabled,
    required this.custom,
  });

  final String currentUserId;
  final String callCid;
  final String createdByUserId;
  final bool isRingingFlow;
  final String sessionId;
  final CallStatus status;
  final String rtmpIngress;
  final bool isRecording;
  final bool isBroadcasting;
  final bool isTranscribing;
  final bool isCaptioning;
  final bool isBackstage;
  final bool isAudioProcessing;
  final Map<String, List<String>> capabilitiesByRole;
  final DateTime? createdAt;
  final DateTime? startsAt;
  final DateTime? endedAt;
  final DateTime? updatedAt;
  final DateTime? liveStartedAt;
  final DateTime? liveEndedAt;
  final DateTime? timerEndsAt;
  final List<int> latencyHistory;
  final List<String> blockedUserIds;
  final int participantCount;
  final int anonymousParticipantCount;
  final bool iOSMultitaskingCameraAccessEnabled;
  final Map<String, Object> custom;

  String get callId => "callCid.id";

  CallParticipantState? get localParticipant {
    return CallParticipantState(
      custom: {},
      trackIdPrefix: "PREf",
      name: "Jose Vladimir",
      isLocal: true,
      isSpeaking: true,
      userId: "00001",
      roles: ["publisher"],
      sessionId: "00001",
      image: "https://i.pravatar.cc/200",
    );
  }

  List<CallParticipantState> get otherParticipants {
    return [
      // CallParticipantState(
      //   custom: {},
      //   trackIdPrefix: "PREf",
      //   name: "Romeo",
      //   isLocal: false,
      //   isSpeaking: false,
      //   userId: "00002",
      //   roles: ["publisher"],
      //   sessionId: "0002",
      //   image: "https://i.pravatar.cc/100",
      // ),
      // CallParticipantState(
      //   custom: {},
      //   trackIdPrefix: "PREf",
      //   name: "Juanito",
      //   isLocal: false,
      //   isSpeaking: false,
      //   userId: "00003",
      //   roles: ["publisher"],
      //   sessionId: "00003",
      //   image: "https://i.pravatar.cc/150",
      // )
    // ,CallParticipantState(
      //   custom: {},
      //   trackIdPrefix: "PREf",
      //   name: "Laura",
      //   isLocal: true,
      //   isSpeaking: true,
      //   userId: "00004",
      //   roles: ["publisher"],
      //   sessionId: "00004",
      //   image: "https://i.pravatar.cc/200",
      // )
    ];
  }

  List<CallParticipantState> get activeSpeakers {
    return [
      CallParticipantState(
        custom: {},
        trackIdPrefix: "PREf",
        name: "Juana",
        isLocal: false,
        isSpeaking: true,
        userId: "00010",
        roles: ["publisher"],
        sessionId: "00010",
        image: "https://i.pravatar.cc/220",
      ),
    ];
  }

  /// Returns a copy of this [CallState] with the given fields replaced
  /// with the new values.
  CallState copyWith({
    String? currentUserId,
    String? callCid,
    String? createdByUserId,
    bool? isRingingFlow,
    String? sessionId,
    CallStatus? status,
    bool? isRecording,
    bool? isBroadcasting,
    bool? isTranscribing,
    bool? isCaptioning,
    bool? isBackstage,
    bool? isAudioProcessing,

    String? rtmpIngress,

    List<CallParticipantState>? callParticipants,
    Map<String, List<String>>? capabilitiesByRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endedAt,
    DateTime? liveStartedAt,
    DateTime? liveEndedAt,
    DateTime? timerEndsAt,

    List<int>? latencyHistory,
    List<String>? blockedUserIds,
    int? participantCount,
    int? anonymousParticipantCount,
    bool? iOSMultitaskingCameraAccessEnabled,
    Map<String, Object>? custom,
  }) {
    return CallState._(
      currentUserId: currentUserId ?? this.currentUserId,
      callCid: callCid ?? this.callCid,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      isRingingFlow: isRingingFlow ?? this.isRingingFlow,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      isRecording: isRecording ?? this.isRecording,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      isCaptioning: isCaptioning ?? this.isCaptioning,
      isBackstage: isBackstage ?? this.isBackstage,
      isAudioProcessing: isAudioProcessing ?? this.isAudioProcessing,

      rtmpIngress: rtmpIngress ?? this.rtmpIngress,

      capabilitiesByRole: capabilitiesByRole ?? this.capabilitiesByRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startsAt: startsAt ?? this.startsAt,
      endedAt: endedAt ?? this.endedAt,
      liveStartedAt: liveStartedAt ?? this.liveStartedAt,
      liveEndedAt: liveEndedAt ?? this.liveEndedAt,
      timerEndsAt: timerEndsAt ?? this.timerEndsAt,

      latencyHistory: latencyHistory ?? this.latencyHistory,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      participantCount: participantCount ?? this.participantCount,
      anonymousParticipantCount:
          anonymousParticipantCount ?? this.anonymousParticipantCount,
      iOSMultitaskingCameraAccessEnabled:
          iOSMultitaskingCameraAccessEnabled ?? this.iOSMultitaskingCameraAccessEnabled,
      custom: custom ?? this.custom,
    );
  }

  @override
  List<Object?> get props => [
    currentUserId,
    callCid,
    createdByUserId,
    sessionId,
    status,
    isRecording,
    isTranscribing,
    isCaptioning,
    isBroadcasting,
    isBackstage,
    isAudioProcessing,

    rtmpIngress,

    capabilitiesByRole,
    createdAt,
    updatedAt,
    startsAt,
    endedAt,
    liveStartedAt,
    liveEndedAt,
    timerEndsAt,

    latencyHistory,
    blockedUserIds,
    participantCount,
    anonymousParticipantCount,
    iOSMultitaskingCameraAccessEnabled,
    custom,
  ];

  List<CallParticipantState> get callParticipants {
    var list = otherParticipants.toList();
    list.add(localParticipant!);
    list.addAll(activeSpeakers);
    return list;
  }

  @override
  String toString() {
    return 'CallState';
  }
}
