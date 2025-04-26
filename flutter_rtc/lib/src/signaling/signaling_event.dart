// Enumeration of signaling event types.
part of 'signaling_interface.dart';

enum SignalingEventType { connected, disconnected, error }

// A class representing a signaling event.
class SignalingEvent {
  final SignalingEventType type;
  final dynamic data;

  SignalingEvent({required this.type, this.data});
}

enum CallDataEventType {
  offer,
  answer,
  hold,
  resume,
  iceCandidate,
  callDeclined,
  callEnded,
  connectionQuality,
  error,
}

/// Data class to hold information about a call event.
class CallEventData {
  final CallDataEventType type;
  final String callId;
  final String from;
  final String to;
  final Map<String, dynamic> data;

  /// Constructor to create a [CallEventData] instance.
  CallEventData({
    required this.type,
    required this.callId,
    required this.from,
    required this.to,
    required this.data,
  });

  /// Converts the [CallEventData] object to a JSON map.
  Map<String, dynamic> toJson() => {
    'callId': callId,
    'from': from,
    'to': to,
    'data': data,
    'type': type.toString(),
  };

  /// Creates a [CallEventData] instance from a JSON map.
  factory CallEventData.fromJson(Map<String, dynamic> json) => CallEventData(
    callId: json['callId'],
    from: json['from'],
    to: json['to'],
    data: json['data'],
    type: CallDataEventType.values.firstWhere((e) => e.toString() == json['type']),
  );

  factory CallEventData.fromAnswer(
    RTCSessionDescription answer,
    String callId,
    String from,
    String to,
  ) => CallEventData(
    type: CallDataEventType.answer,
    callId: callId,
    from: from,
    to: to,
    data: answer.toMap(),
  );

  factory CallEventData.fromOffer(
    CallOffer offer,
    String callId,
    String from,
    String to,
  ) => CallEventData(
    type: CallDataEventType.offer,
    callId: callId,
    from: from,
    to: to,
    data: offer.toMap(),
  );

  factory CallEventData.fromHold(
    CallOffer offer,
    String callId,
    String from,
    String to,
  ) => CallEventData(
    type: CallDataEventType.hold,
    callId: callId,
    from: from,
    to: to,
    data: offer.toMap(),
  );

  factory CallEventData.fromCandidate(
    RTCIceCandidate candidate,
    String callId,
    String from,
    String to,
  ) => CallEventData(
    type: CallDataEventType.iceCandidate,
    callId: callId,
    from: from,
    to: to,
    data: candidate.toMap(),
  );

  RTCSessionDescription toAnswer() => RTCSessionDescription(data['sdp'], data['type']);

  CallOffer toOffer() => CallOffer.fromJson(data);

  RTCIceCandidate toCandidate() =>
      RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
}

class CallOffer extends RTCSessionDescription {
  final CallMode mode;
  final List<Member> members;

  CallOffer({
    required String sdp,
    required String type,
    required this.mode,
    required this.members,
  }) : super(sdp, type);

  factory CallOffer.fromRTCSession(
    RTCSessionDescription offer, {
    CallMode mode = CallMode.audio,
    List<Member> members = const <Member>[],
  }) {
    return CallOffer(
      sdp: offer.sdp ?? "",
      type: offer.type ?? "",
      mode: mode,
      members: members,
    );
  }

  /// Converts the [CallOffer] object to a JSON map.
  Map<String, dynamic> toJson() => {
    'sdp': sdp,
    'type': type,
    'mode': mode.toString(),
    'members': members.toJsonList(),
  };

  /// Creates a [CallOffer] instance from a JSON map.
  factory CallOffer.fromJson(Map<String, dynamic> json) => CallOffer(
    sdp: json['sdp'],
    type: json['type'],
    mode: CallMode.values.firstWhere((e) => e.toString() == json['mode']),
    members: MembersListExtension.fromJsonList(
      json['members'] as List<Map<String, dynamic>>,
    ),
  );
}
