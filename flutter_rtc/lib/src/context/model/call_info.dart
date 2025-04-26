import 'package:equatable/equatable.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/context/model/member.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


final class CallInfo extends Equatable {
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
  });

  Map<String, dynamic> toJson() => {
    'params': params,
    'callId': callId,
    'userId': userId,
    'members': members.map((p) => p.toJson()).toList(),
    'callMode': callMode.name,
    'isCaller': isCaller,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CallInfo.fromJson(Map<String, dynamic> json) => CallInfo(
    params: json['params'],
    callId: json['callId'],
    userId: json['userId'],
    members:
        (json['members'] as List).map((p) => Member.fromJson(p)).toList(),
    callMode: CallMode.values.byName(json['callMode']),
    isCaller: json['isCaller'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Member get self => members.firstWhere(
    (p) => p.userId == userId,
    orElse: () => throw Exception('Local member not found'),
  );

  set self(Member member) {
    members.removeWhere((p) => p.userId == userId);
    members.add(member);
  }

  List<Member> get remoteMembers =>
      members.where((p) => !p.isLocal).toList();

  CallInfo copyAndUpdateStream(Map<String, MediaStream?> remoteStream) {
    var newMembers = List<Member>.from(members);
    newMembers.map((p) => p.copyWith(mediaStream: remoteStream[p.userId])).toList();

    return copyWith(members: newMembers);
  }

  CallInfo copyWith({
    Map<String, dynamic>? params,
    String? callId,
    String? userId,
    List<Member>? members,
    CallMode? callMode,
    bool? isCaller,
    DateTime? createdAt,
  }) {
    return CallInfo(
      params: params ?? this.params,
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      members: members ?? this.members,
      callMode: callMode ?? this.callMode,
      isCaller: isCaller ?? this.isCaller,
      createdAt: createdAt ?? this.createdAt,
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
  ];
}
