import 'package:equatable/equatable.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';

final class CallInfo extends Equatable {
  final String callId;
  final String userId;
  final List<Participant> participants;
  final CallMode callMode;
  final bool isCaller;
  final DateTime createdAt;

  const CallInfo({
    required this.callId,
    required this.userId,
    required this.participants,
    required this.callMode,
    required this.isCaller,
    required this.createdAt,
  });

  Participant get self =>
      participants.firstWhere((p) => p.userId == userId, orElse: () => throw Exception('Local participant not found'));

  set self(Participant participant) {
    participants.removeWhere((p) => p.userId == userId);
    participants.add(participant);
  }

  List<Participant> get remoteParticipants => participants.where((p) => !p.isLocal).toList();

  CallInfo copyWith({
    String? callId,
    String? userId,
    List<Participant>? participants,
    CallMode? callMode,
    bool? isCaller,
    DateTime? createdAt,
  }) {
    return CallInfo(
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
