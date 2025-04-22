// lib/src/context/rtc/rtc_manager.dart

import 'package:flutter_rtc/src/context/model/participant.dart' show Participant;
import 'package:flutter_rtc/src/context/rtc/peer_connection_wrapper.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';

import 'package:flutter_rtc/src/context/bloc/call_enums.dart';

class RTCManager {
  final String callId;
  final String userId;
  final SignalingInterface signaling;

  final Map<String, PeerConnectionWrapper> _peers = {};

  MediaStream? _localStream;
  bool _isScreenSharing = false;

  RTCManager({required this.callId, required this.userId, required this.signaling});

  Future<void> _ensureLocalStream({
    bool enableAudio = true,
    bool enableVideo = false,
  }) async {
    if (_localStream != null) return;
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': enableAudio,
      'video': enableVideo ? {'facingMode': 'user'} : false,
    });
  }

  /// Create offer for participants in the call.
  /// It creates peer connection for each participant and sends offer.
  Future<void> createOfferFor(List<Participant> participants, CallMode mode) async {
    await _ensureLocalStream(enableVideo: mode == CallMode.video);
    for (final participant in participants) {
      final peer = await _getOrCreatePeer(participant.userId);
      await peer.createOffer(mode, participants);
    }
  }

  void handleOffer(Map<String, dynamic> offer) async {
    final from = offer['from'];
    await _ensureLocalStream();
    final peer = await _getOrCreatePeer(from);
    await peer.handleOffer(offer);
  }

  void handleRemoteEvent(String from, dynamic event) async {
    final peer = _peers[from];
    if (peer == null) return;

    switch (event['type']) {
      case 'answer':
        await peer.setRemoteDescription(event['sdp'], event['sdpType']);
        break;
      case 'candidate':
        await peer.addIceCandidate(event['candidate']);
        break;
      case 'end':
        removeParticipant(from);
        break;
    }
  }

  Future<void> joinParticipant(String remoteId) async {
    await _ensureLocalStream();
    await _getOrCreatePeer(remoteId);
  }

  void removeParticipant(String remoteId) {
    _peers[remoteId]?.dispose();
    _peers.remove(remoteId);
  }

  void toggleMic(bool enabled) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = enabled);
    _peers.forEach((_, peer) => peer.toggleMic(enabled));
  }

  void toggleCamera(bool enabled) {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = enabled);
  }

  Future<void> switchCamera() async {
    if (_isScreenSharing || _localStream == null) return;
    final videoTrack = _localStream!.getVideoTracks().first;
    await Helper.switchCamera(videoTrack);
  }

  void switchSpeaker(bool enabled) {
    Helper.setSpeakerphoneOn(enabled);
  }

  Future<void> startScreenSharing() async {
    if (_isScreenSharing) return;
    final screenStream = await navigator.mediaDevices.getDisplayMedia({'video': true});
    for (final peer in _peers.values) {
      await peer.replaceVideoTrack(screenStream.getVideoTracks().first);
    }
    _isScreenSharing = true;
  }

  Future<void> stopScreenSharing() async {
    if (!_isScreenSharing) return;
    final cameraStream = await navigator.mediaDevices.getUserMedia({'video': true});
    final videoTrack = cameraStream.getVideoTracks().first;
    for (final peer in _peers.values) {
      await peer.replaceVideoTrack(videoTrack);
    }
    _isScreenSharing = false;
  }

  Future<PeerConnectionWrapper> _getOrCreatePeer(String remoteId) async {
    if (_peers.containsKey(remoteId)) return _peers[remoteId]!;

    final wrapper = PeerConnectionWrapper(
      localUserId: userId,
      remoteUserId: remoteId,
      callId: callId,
      signaling: signaling,
      localStream: _localStream!,
    );

    await wrapper.initialize();
    _peers[remoteId] = wrapper;
    return wrapper;
  }

  void close() {
    for (final peer in _peers.values) {
      peer.dispose();
    }
    _peers.clear();
    _localStream?.dispose();
  }

  void dispose() {
    close();
  }
}
