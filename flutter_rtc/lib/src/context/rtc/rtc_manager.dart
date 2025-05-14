// lib/src/context/rtc/rtc_manager.dart

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/context/model/member.dart';
import 'package:flutter_rtc/src/context/rtc/peer_connection_wrapper.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/call_bloc.dart';

part 'rtc_device_handler.dart';
part 'rtc_event_manager.dart';

part 'rtc_media_handler.dart';

part 'rtc_peer_manager.dart';

class RTCManager {
  final String callId;
  final String userId;
  final ISignaling signaling;

  late final _RTCPeerManager _peerManager;
  late final _RTCMediaHandler _mediaHandler;
  late final _RTCDeviceHandler _deviceHandler;
  late final _RTCEventHandler _eventHandler;

  Stream<CallEvent> get callEvents => _eventHandler.callEvents;

  Stream<PeerCallEvent> get peerEvents => _eventHandler.peerEvents;

  MediaStream? get localStream => _mediaHandler.localStream;

  Map<String, MediaStream?> get mediaStreams {
    _peerManager.remoteMediaStream.putIfAbsent(userId, () => localStream);

    return _peerManager.remoteMediaStream;
  }

  RTCManager(
      {required this.callId, required this.userId, required this.signaling}) {
    _eventHandler = _RTCEventHandler();
    _mediaHandler = _RTCMediaHandler();
    _deviceHandler = _RTCDeviceHandler();
    _peerManager = _RTCPeerManager(
        userId, callId, signaling, _eventHandler, _onConnectionState);
  }

  //----------------CallManager Controller---------------------------------

  /// Starts an outgoing call by initializing permissions, local media,
  /// peer connection, data channel and sending the offer via signaling.
  Future<void> startOutgoingCall(List<Member> members, CallMode mode) async {
    try {
      debugPrint("[CallManager] startOutgoingCall");
      _eventHandler.sendCallEvent(CallLifeCycleStatus.initial);
      _eventHandler.sendCallEvent(CallLifeCycleStatus.calling);

      await _mediaHandler._ensureHasPermissions(mode == CallMode.video);

      createOfferFor(members, mode);
    } catch (e) {
      debugPrint("[CallManager] Error starting outgoing call: $e");
      _eventHandler.sendCallEvent(
          CallLifeCycleStatus.failed, value: e.toString());
    }
  }

  /// Answers an incoming call by obtaining permissions, local media,
  /// setting up the peer connection and sending the answer via signaling.
  Future<void> answerIncomingCall(CallEventData data) async {
    try {
      debugPrint("[CallManager] Answering incoming call.");

      await _mediaHandler._ensureHasPermissions(data.toOffer().mode == CallMode.video);

      await _mediaHandler.ensureLocalStream();
      await _peerManager.answerToOffer(data, _mediaHandler.localStream!);

    } catch (e) {
      debugPrint("[CallManager] Error answering incoming call: $e");
      _eventHandler.sendCallEvent(
          CallLifeCycleStatus.failed, value: e.toString());
    }
  }

  Future<void> createOfferFor(List<Member> members, CallMode mode) async {
    debugPrint("[CallManager] createOfferFor ${members.length}");
    await _mediaHandler.ensureLocalStream(enableVideo: mode == CallMode.video);
    await _peerManager.createOffersFor(members, _mediaHandler.localStream!, mode);
  }

  /// Handles an incoming offer by storing the offer data and notifying listeners.
  void handleIncomingOffer(CallEventData offer) async {
    debugPrint("[CallManager] Received offer: $offer");
    _eventHandler.sendCallEvent(CallLifeCycleStatus.incoming, value: offer);
  }

  void handleIncomingHold(CallEventData data) =>
      _peerManager.handleIncomingHold(data);

  void handleIncomingResume(CallEventData data) =>
      _peerManager.handleIncomingResume(data);

  void handleIncomingAnswer(CallEventData data) =>
      _peerManager.handleIncomingAnswer(data);

  void handleIncomingCandidate(CallEventData data) =>
      _peerManager.handleIncomingCandidate(data);

  Future<void> handleDeclineIncomingCall(String? reason) async {
    await _peerManager.handleDeclineIncomingCall(reason);
    _eventHandler.sendCallEvent(CallLifeCycleStatus.ended);
  }

  Future<void> handleEndCall() async {
    await _peerManager.handleEndCall();
    _eventHandler.sendCallEvent(CallLifeCycleStatus.ended);
  }

  Future<void> joinMember(String remoteId) async {
    await _mediaHandler.ensureLocalStream();
    await _peerManager.getOrCreatePeer(remoteId, _mediaHandler.localStream!);
  }

  void removeMembers(String remoteId) => _peerManager.removePeer(remoteId);

  //----------------_mediaHandler Controller---------------------------------

  void toggleMicrophone(bool enabled) => _mediaHandler.toggleAudio(enabled);

  void toggleCamera(bool enabled) => _mediaHandler.toggleVideo(enabled);

  void toggleSpeaker(bool enabled) => _deviceHandler.setSpeakerphone(enabled);

  Future<void> switchCamera() async {
    if (_mediaHandler._localStream == null) return;
    _deviceHandler.switchCamera(_mediaHandler.videoTrack);
  }

  Future<void> toggleScreenSharing(
    bool isScreenSharing,
  ) => _mediaHandler.toggleScreenSharing(
    isScreenSharing: isScreenSharing,
    onStart: (stream) => _peerManager.replaceVideoTracks(stream.getVideoTracks().first),
    onStop: (stream) => _peerManager.replaceVideoTracks(stream.getVideoTracks().first),
  );

  void close() {
    _peerManager.disposeAll();
    _mediaHandler.dispose();
  }

  void dispose() => close();

  Future<void> resumeCall() async {
    _peerManager.resumeCall();
    _eventHandler.sendCallEvent(CallLifeCycleStatus.active);
  }

  Future<void> holdCall() async {
    _peerManager.holdCall();
    _eventHandler.sendCallEvent(CallLifeCycleStatus.hold);
  }

  void _onConnectionState(memberId, state) {
    debugPrint("[CallManager] Connection state changed [$memberId :  $state]");
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _eventHandler.sendPeerEvent(memberId, ConnectionStatus.ended);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _eventHandler.sendPeerEvent(memberId, ConnectionStatus.failed);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        _eventHandler.sendPeerEvent(memberId, ConnectionStatus.connecting);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _eventHandler.sendPeerEvent(memberId, ConnectionStatus.connected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        _eventHandler.sendPeerEvent(memberId, ConnectionStatus.disconnected);
        break;
    }
  }
}
