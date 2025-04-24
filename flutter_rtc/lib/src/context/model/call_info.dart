import 'package:equatable/equatable.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final class CallInfo extends Equatable {
  final Map<String, dynamic> params;
  final String callId;
  final String userId;
  final List<Participant> participants;
  final CallMode callMode;
  final bool isCaller;
  final DateTime createdAt;

  const CallInfo({
    this.params = const {},
    required this.callId,
    required this.userId,
    required this.participants,
    required this.callMode,
    required this.isCaller,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'params': params,
    'callId': callId,
    'userId': userId,
    'participants': participants.map((p) => p.toJson()).toList(),
    'callMode': callMode.name,
    'isCaller': isCaller,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CallInfo.fromJson(Map<String, dynamic> json) => CallInfo(
    params: json['params'],
    callId: json['callId'],
    userId: json['userId'],
    participants:
        (json['participants'] as List).map((p) => Participant.fromJson(p)).toList(),
    callMode: CallMode.values.byName(json['callMode']),
    isCaller: json['isCaller'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Participant get self => participants.firstWhere(
    (p) => p.userId == userId,
    orElse: () => throw Exception('Local participant not found'),
  );

  set self(Participant participant) {
    participants.removeWhere((p) => p.userId == userId);
    participants.add(participant);
  }

  List<Participant> get remoteParticipants =>
      participants.where((p) => !p.isLocal).toList();

  CallInfo copyAndUpdateStream(Map<String, MediaStream?> remoteStream) {
    var newParticipants = List<Participant>.from(participants);
    newParticipants.map((p) => p.copyWith(mediaStream: remoteStream[p.userId])).toList();

    return copyWith(participants: newParticipants);
  }

  CallInfo copyWith({
    Map<String, dynamic>? params,
    String? callId,
    String? userId,
    List<Participant>? participants,
    CallMode? callMode,
    bool? isCaller,
    DateTime? createdAt,
  }) {
    return CallInfo(
      params: params ?? this.params,
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      participants: participants ?? this.participants,
      callMode: callMode ?? this.callMode,
      isCaller: isCaller ?? this.isCaller,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    callId,
    userId,
    participants,
    callMode,
    isCaller,
    createdAt,
  ];
}
