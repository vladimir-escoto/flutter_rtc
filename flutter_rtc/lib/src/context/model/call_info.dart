import 'package:equatable/equatable.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/context/model/member.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


final class CallInfo extends Equatable {
  final CallLifeCycleStatus callStatus;
  final Map<String, dynamic> params;
  final String callId;
  final String userId;
  final List<Member> members;
  final CallMode callMode;
  final bool isCaller;
  final DateTime createdAt;

  const CallInfo({
    this.params = const {},
    required this.callId,
    required this.userId,
    required this.members,
    required this.callMode,
    required this.isCaller,
    required this.createdAt,
    required this.callStatus,
  });

  Map<String, dynamic> toJson() => {
    'params': params,
    'callId': callId,
    'userId': userId,
    'members': members.map((p) => p.toJson()).toList(),
    'callMode': callMode.name,
    'isCaller': isCaller,
    'createdAt': createdAt.toIso8601String(),
    'callStatus': callStatus.name,
  };

  factory CallInfo.fromJson(Map<String, dynamic> json) => CallInfo(
    params: json['params'],
    callId: json['callId'],
    userId: json['userId'],
    members:
        (json['members'] as List).map((p) => Member.fromJson(p)).toList(),
    callMode: CallMode.values.byName(json['callMode']),
    callStatus: CallLifeCycleStatus.values.byName(json['callStatus']),
    isCaller: json['isCaller'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Member get self => members.firstWhere(
    (p) => p.id == userId,
    orElse: () => throw Exception('Local member not found'),
  );

  set self(Member member) {
    members.removeWhere((p) => p.id == userId);
    members.add(member);
  }

  List<Member> get remoteMembers =>
      members.where((m) => m.id != userId ).toList();

  CallInfo copyAndUpdateStream(Map<String, MediaStream?> remoteStream,
      CallLifeCycleStatus callStatus) {
    var newMembers = members.map((p) =>
        p.copyWith(mediaStream: remoteStream[p.id])).toList();
    return copyWith(members: newMembers, callStatus: callStatus);
  }

  CallInfo copyWith({
    Map<String, dynamic>? params,
    String? callId,
    String? userId,
    List<Member>? members,
    CallMode? callMode,
    bool? isCaller,
    DateTime? createdAt,
    CallLifeCycleStatus? callStatus,
  }) {
    return CallInfo(
      params: params ?? this.params,
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      members: members ?? this.members,
      callMode: callMode ?? this.callMode,
      isCaller: isCaller ?? this.isCaller,
      createdAt: createdAt ?? this.createdAt,
      callStatus: callStatus ?? this.callStatus,
    );
  }

  @override
  List<Object?> get props => [
    callId,
    userId,
    members,
    callMode,
    isCaller,
    createdAt,
    callStatus,
  ];
}
