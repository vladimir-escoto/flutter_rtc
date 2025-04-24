// lib/src/context/rtc/peer_connection_wrapper.dart

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../bloc/call_bloc.dart';

typedef ConnectionStateCallback = void Function(String, RTCPeerConnectionState);
typedef ErrorCallback = void Function(String, String message);

class PeerConnectionWrapper {
  final String localUserId;
  final String remoteUserId;
  final String callId;
  final ISignaling signaling;
  final MediaStream localStream;
  MediaStream? remoteStream;
  RTCDataChannel? dataChannel;
  bool _accepted = false;

  MapEntry<String, MediaStream> get remoteMediaStream =>
      MapEntry(remoteUserId, localStream);

  final List<RTCIceCandidate> _iceCandidates = [];
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
      if (_accepted) {
        _senIceCandidate(candidate);
      } else {
        _iceCandidates.add(candidate);
      }
    };

    // Remote stream handler.
    _pc.onAddStream = (stream) {
      debugPrint("[CallManager] Received remote stream: $stream");
      remoteStream = stream;
    };

    // Connection state change handler.
    _pc.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionState?.call(remoteUserId, state);
    };

    // // Create a data channel for control messages.
    dataChannel = await _pc.createDataChannel('control', RTCDataChannelInit());
    // // Setup data channel messages callback.
    dataChannel?.onMessage = (message) {};
  }

  Future<void> createOffer(CallMode mode, List<Participant> participants) async {
    final offer = await _pc.createOffer();
    await _pc.setLocalDescription(offer);

    final callOffer = CallOffer.fromSessionDescription(offer, mode, participants);
    final data = CallEventData.fromOffer(callOffer, callId, localUserId, remoteUserId);
    debugPrint("[CallManager] Sent offer");

    signaling.sendEvent(data);
  }

  Future<void> answerToOffer(CallOffer offer) async {
    await _pc.setRemoteDescription(offer);

    final answer = await _pc.createAnswer();
    await _pc.setLocalDescription(answer);

    final data = CallEventData.fromAnswer(answer, callId, localUserId, remoteUserId);

    debugPrint("[CallManager] Sent answer: $answer");
    signaling.sendEvent(data);
    _accepted = true;

    for (var candidate in _iceCandidates) {
      _senIceCandidate(candidate);
    }
  }

  Future<void> declineCall(String? reason) async {
    dispose();

    final data = CallEventData(
      type: CallDataEventType.callDeclined,
      callId: callId,
      from: localUserId,
      to: remoteUserId,
      data: {"reason": reason ?? ""},
    );

    debugPrint("[CallManager] Sent decline");

    signaling.sendEvent(data);
  }

  Future<void> endCall() async {
    dispose();

    final data = CallEventData(
      type: CallDataEventType.callEnded,
      callId: callId,
      from: localUserId,
      to: remoteUserId,
      data: {},
    );

    debugPrint("[CallManager] Sent decline");

    signaling.sendEvent(data);
  }

  Future<void> handleIncomingAnswer(RTCSessionDescription answer) async {
    await _pc.setRemoteDescription(answer);
    _accepted = true;
    for (var candidate in _iceCandidates) {
      _senIceCandidate(candidate);
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _pc.addCandidate(candidate);
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

    // signaling.sendEvent({
    //   'type': 'offer',
    //   'callId': callId,
    //   'to': remoteUserId,
    //   'from': localUserId,
    //   'sdp': offer.sdp,
    //   'sdpType': offer.type,
    // });
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
      remoteStream?.dispose();
    } catch (e) {
      debugPrint("[CallManager] Error during hang up: $e");
    }
    remoteStream = null;
  }

  void _senIceCandidate(RTCIceCandidate candidate) {
    debugPrint("[CallManager] Sending ICE candidate immediately: ${candidate.toMap()}");
    signaling.sendEvent(
      CallEventData.fromCandidate(candidate, callId, localUserId, remoteUserId),
    );
  }
}
