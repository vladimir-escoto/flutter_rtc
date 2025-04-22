// lib/src/context/rtc/peer_connection_wrapper.dart

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';

typedef ConnectionStateCallback = void Function(String, RTCPeerConnectionState);
typedef ErrorCallback = void Function(String, String message);

class PeerConnectionWrapper {
  final String localUserId;
  final String remoteUserId;
  final String callId;
  final SignalingInterface signaling;
  final MediaStream localStream;
  MediaStream? _remoteStream;
  RTCDataChannel? dataChannel;

  final ConnectionStateCallback? onConnectionState;
  final ErrorCallback? onError;

  late final RTCPeerConnection _pc;

  final _config = <String, dynamic>{
    'sdpSemantics': 'unified-plan',
    'iceServers': [
      {'urls': "stun:stun.l.google.com:19302"},
      {'urls': "stun:stun.l.google.com:5349"},
      {'urls': "stun:stun1.l.google.com:3478"},
      {'urls': "stun:stun1.l.google.com:5349"},
      {'urls': "stun:stun2.l.google.com:19302"},
      {'urls': "stun:stun2.l.google.com:5349"},
      {'urls': "stun:stun3.l.google.com:3478"},
      {'urls': "stun:stun3.l.google.com:5349"},
      {'urls': "stun:stun4.l.google.com:19302"},
      {'urls': "stun:stun4.l.google.com:5349"},
    ],
    'continualGatheringPolicy': 'gather_continually',
  };

  PeerConnectionWrapper({
    required this.localUserId,
    required this.remoteUserId,
    required this.callId,
    required this.signaling,
    required this.localStream,
    this.onConnectionState,
    this.onError,
  });

  Future<void> initialize() async {
    // Create the peer connection.
    _pc = await createPeerConnection(_config);

    // Setup peer connection with local stream; store ICE candidates.
    // Add local tracks.
    for (var track in localStream.getTracks()) {
      debugPrint("[CallManager] Adding local track: $track");
      _pc.addTrack(track, localStream);
    }

    // ICE candidate handler.
    _pc.onIceCandidate = (candidate) {
      debugPrint("[CallManager] Sending ICE candidate immediately: ${candidate.toMap()}");

      signaling.sendEvent({
        'type': 'candidate',
        'callId': callId,
        'from': localUserId,
        'to': remoteUserId,
        'candidate': candidate.toMap(),
      });
    };

    // Remote stream handler.
    _pc.onAddStream = (stream) {
      debugPrint("[CallManager] Received remote stream: $stream");
      _remoteStream = stream;
    };

    // Connection state change handler.
    _pc.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionState?.call(remoteUserId, state);
    };

    // // Create a data channel for control messages.
    // dataChannel = await _pc.createDataChannel('control', RTCDataChannelInit());
    // // Setup data channel messages callback.
    // dataChannel?.onMessage = (message) {};
  }

  Future<void> createOffer(CallMode mode, List<Participant> participants) async {
    final offer = await _pc.createOffer();
    await _pc.setLocalDescription(offer);

    signaling.sendEvent({
      'type': 'offer',
      'callId': callId,
      'to': remoteUserId,
      'from': localUserId,
      'sdp': offer.sdp,
      'sdpType': offer.type,
      'mode': mode.name,
      'participants': participants.toJsonList(),
    });
  }

  Future<void> handleOffer(Map<String, dynamic> offer) async {
    await _pc.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['sdpType']));

    final answer = await _pc.createAnswer();
    await _pc.setLocalDescription(answer);

    signaling.sendEvent({
      'type': 'answer',
      'callId': callId,
      'to': remoteUserId,
      'from': localUserId,
      'sdp': answer.sdp,
      'sdpType': answer.type,
    });
  }

  Future<void> setRemoteDescription(String sdp, String type) async {
    await _pc.setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    await _pc.addCandidate(
      RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      ),
    );
  }

  Future<void> replaceVideoTrack(MediaStreamTrack newTrack) async {
    final senders = await _pc.getSenders();
    final sender = senders.where((s) => s.track?.kind == 'video').firstOrNull;

    if (sender != null) {
      await sender.replaceTrack(newTrack);
    } else {
      onError?.call(remoteUserId, "No video sender found");
    }
  }

  Future<void> renegotiate() async {
    final offer = await _pc.createOffer();
    await _pc.setLocalDescription(offer);

    signaling.sendEvent({
      'type': 'offer',
      'callId': callId,
      'to': remoteUserId,
      'from': localUserId,
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });
  }

  Future<void> sendControlMessage(String event, dynamic value) async {
    if (dataChannel != null) {
      try {
        final message = jsonEncode({"event": event, "value": value});
        dataChannel!.send(RTCDataChannelMessage(message));
      } catch (e) {
        debugPrint("[CallManager] Error sending control message: $e");
      }
    }
  }

  void dispose() {
    try {
      _pc.close();
      _remoteStream?.dispose();
    } catch (e) {
      debugPrint("[CallManager] Error during hang up: $e");
    }
    _remoteStream = null;
  }

  void toggleMic(bool enabled) {}
}
