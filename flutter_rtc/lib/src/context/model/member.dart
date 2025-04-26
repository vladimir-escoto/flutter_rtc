import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final class Member extends Equatable {
  final String userId;
  final String displayName;
  final bool isLocal;

  final bool speakerEnable;
  final bool micEnabled;
  final bool cameraEnabled;
  final bool screenShareEnabled;

  final MediaStream? mediaStream;

  const Member({
    required this.userId,
    this.displayName = 'unknown',
    this.isLocal = false,
    this.micEnabled = true,
    this.speakerEnable = false,
    this.cameraEnabled = false,
    this.screenShareEnabled = false,
    this.mediaStream,
  });

  Member copyWith({
    String? displayName,
    bool? micEnabled,
    bool? speakerEnable,
    bool? cameraEnabled,
    bool? screenShareEnabled,
    MediaStream? mediaStream,
  }) {
    return Member(
      userId: userId,
      displayName: displayName ?? this.displayName,
      isLocal: isLocal,
      micEnabled: micEnabled ?? this.micEnabled,
      speakerEnable: speakerEnable ?? this.speakerEnable,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      screenShareEnabled: screenShareEnabled ?? this.screenShareEnabled,
      mediaStream: mediaStream ?? this.mediaStream,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'isLocal': isLocal,
      'micEnabled': micEnabled,
      'speakerEnable': speakerEnable,
      'cameraEnabled': cameraEnabled,
      'screenShareEnabled': screenShareEnabled,
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId'],
      displayName: json['displayName'],
      isLocal: json['isLocal'],
      micEnabled: json['micEnabled'],
      speakerEnable: json['speakerEnable'],
      cameraEnabled: json['cameraEnabled'],
      screenShareEnabled: json['screenShareEnabled'],
    );
  }

  @override
  List<Object?> get props => [
    userId,
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
