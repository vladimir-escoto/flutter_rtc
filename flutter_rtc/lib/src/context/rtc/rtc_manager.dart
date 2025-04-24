// lib/src/context/rtc/rtc_manager.dart

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/context/rtc/peer_connection_wrapper.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/call_bloc.dart';


part 'rtc_media_handler.dart';

part 'rtc_peer_manager.dart';

part 'rtc_device_handler.dart';

part 'rtc_event_manager.dart';

class RTCManager {
  final String callId;
  final String userId;
  final ISignaling signaling;

  late final _RTCPeerManager _peerManager;
  late final _RTCMediaHandler _mediaHandler;
  late final _RTCDeviceHandler _deviceHandler;
  late final _RTCEventHandler _eventHandler;

  Stream<CallEvent> get callEvents => _eventHandler.callEvents;

  MediaStream? get localStream => _mediaHandler.localStream;

  Map<String, MediaStream?> get mediaStreams {
    _peerManager.remoteMediaStream.putIfAbsent(userId, () => localStream);

    return _peerManager.remoteMediaStream;
  }

  RTCManager({required this.callId, required this.userId, required this.signaling}) {
    _eventHandler = _RTCEventHandler();
    _mediaHandler = _RTCMediaHandler();
    _deviceHandler = _RTCDeviceHandler();
    _peerManager = _RTCPeerManager(userId, callId, signaling, _eventHandler);
  }

  //----------------CallManager Controller---------------------------------

  /// Starts an outgoing call by initializing permissions, local media,
  /// peer connection, data channel and sending the offer via signaling.
  Future<void> startOutgoingCall(List<Participant> participants, CallMode mode) async {
    try {
      debugPrint("[CallManager] startOutgoingCall");
      _eventHandler._sendCallEvent(CallLifecycleStatus.initial);
      _eventHandler._sendCallEvent(CallLifecycleStatus.calling);

      await _mediaHandler._ensureHasPermissions(mode == CallMode.video);

      createOfferFor(participants, mode);

      _eventHandler._sendCallEvent(CallLifecycleStatus.ringing);
    } catch (e) {
      debugPrint("[CallManager] Error starting outgoing call: $e");
      _eventHandler._sendCallEvent(CallLifecycleStatus.failed, value: e.toString());
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
      _eventHandler._sendCallEvent(CallLifecycleStatus.failed, value: e.toString());
    }
  }

  Future<void> createOfferFor(List<Participant> participants, CallMode mode) async {
    debugPrint("[CallManager] createOfferFor ${participants.length}");
    await _mediaHandler.ensureLocalStream(enableVideo: mode == CallMode.video);
    await _peerManager.createOffersFor(participants, _mediaHandler.localStream!, mode);
  }

  /// Handles an incoming offer by storing the offer data and notifying listeners.
  void handleIncomingOffer(CallEventData offer) async {
    debugPrint("[CallManager] Received offer: $offer");
    _eventHandler._sendCallEvent(CallLifecycleStatus.incoming, value: offer);

  }

  void handleIncomingAnswer(CallEventData data) =>
      _peerManager.handleIncomingAnswer(data);

  void handleIncomingCandidate(CallEventData data) =>
      _peerManager.handleIncomingCandidate(data);

  Future<void> handleDeclineIncomingCall(String? reason) async =>
      await _peerManager.handleDeclineIncomingCall(reason);

  Future<void> handleEndCall() async => await _peerManager.handleEndCall();

  Future<void> joinParticipant(String remoteId) async {
    await _mediaHandler.ensureLocalStream();
    await _peerManager.getOrCreatePeer(remoteId, _mediaHandler.localStream!);
  }

  void removeParticipant(String remoteId) => _peerManager.removePeer(remoteId);

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

  void resume() {
    _peerManager.resume();
  }

  void pause() {
    _peerManager.pause();
  }
}
