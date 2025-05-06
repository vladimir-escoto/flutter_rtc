import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../bloc/call_bloc.dart';

final class Member extends Equatable {
  final String id;
  final String displayName;
  final bool isLocal;

  final bool speakerEnable;
  final bool micEnabled;
  final bool cameraEnabled;
  final bool screenShareEnabled;

  final MediaStream? mediaStream;

  final ConnectionStatus status;

  bool get isStreamAvailable => mediaStream != null && cameraEnabled;

  const Member({
    required this.id,
    this.displayName = 'Unknown Name',
    this.isLocal = false,
    this.micEnabled = true,
    this.speakerEnable = false,
    this.cameraEnabled = false,
    this.screenShareEnabled = false,
    this.mediaStream,
    this.status = ConnectionStatus.disconnected,
  });

  Member copyWith({
    String? displayName,
    bool? micEnabled,
    bool? speakerEnable,
    bool? cameraEnabled,
    bool? screenShareEnabled,
    MediaStream? mediaStream,
    ConnectionStatus? status,
  }) {
    return Member(
      id: id,
      displayName: displayName ?? this.displayName,
      isLocal: isLocal,
      micEnabled: micEnabled ?? this.micEnabled,
      speakerEnable: speakerEnable ?? this.speakerEnable,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      screenShareEnabled: screenShareEnabled ?? this.screenShareEnabled,
      mediaStream: mediaStream ?? this.mediaStream,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'isLocal': isLocal,
      'micEnabled': micEnabled,
      'speakerEnable': speakerEnable,
      'cameraEnabled': cameraEnabled,
      'screenShareEnabled': screenShareEnabled,
      'status': status.name,
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      displayName: json['displayName'],
      isLocal: json['isLocal'],
      micEnabled: json['micEnabled'],
      speakerEnable: json['speakerEnable'],
      cameraEnabled: json['cameraEnabled'],
      screenShareEnabled: json['screenShareEnabled'],
      status: ConnectionStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    isLocal,
    micEnabled,
    speakerEnable,
    cameraEnabled,
    screenShareEnabled,
    mediaStream,
  ];
}

extension MembersListExtension on List<Member> {
  List<Map<String, dynamic>> toJsonList() => map((e) => e.toJson()).toList();

  static List<Member> fromJsonList(List<dynamic> jsonList) =>
      jsonList.map((json) => Member.fromJson(json as Map<String, dynamic>)).toList();

  String toJsonString() => jsonEncode(toJsonList());

  static List<Member> fromJsonString(String jsonString) =>
      fromJsonList(jsonDecode(jsonString) as List<dynamic>);
}
