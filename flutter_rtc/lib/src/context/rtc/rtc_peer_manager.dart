// ---------- rtc_peer_manager.dart ----------
part of 'rtc_manager.dart';

class _RTCPeerManager {
  final String _localUserId;
  final String _callId;
  final ISignaling _signaling;
  final Map<String, PeerConnectionWrapper> _peers = {};
  final _RTCEventHandler _eventHandler;

  Map<String, MediaStream?> get remoteMediaStream =>
      Map.fromEntries(_peers.values.map((p) => p.remoteMediaStream).toList());

  _RTCPeerManager(this._localUserId, this._callId, this._signaling, this._eventHandler);

  Future<void> createOffersFor(
    List<Participant> participants,
    MediaStream localStream,
    CallMode mode,
  ) async {
    for (final participant in participants.where((p)=>p.userId != _localUserId)) {
      final peer = await getOrCreatePeer(participant.userId, localStream);
      await peer.createOffer(mode, participants);
    }
  }

  Future<void> answerToOffer(CallEventData data, MediaStream localStream) async {
    final peer = await getOrCreatePeer(data.from, localStream);
    await peer.answerToOffer(data.toOffer());
  }

  /// Handles an incoming answer by setting the remote description
  /// and sending any stored ICE candidates.
  Future<void> handleIncomingAnswer(CallEventData data) async {
    final peer = _peers[data.from];

    if (peer == null) return;
    final answer = data.toAnswer();

    debugPrint("[CallManager] Received answer: $answer");
    _eventHandler._sendCallEvent(CallLifecycleStatus.ringing);
    await peer.handleIncomingAnswer(data.toAnswer());
  }

  Future<void> handleIncomingCandidate(CallEventData data) async {
    final peer = _peers[data.from];
    if (peer == null) return;
    peer.addIceCandidate(data.toCandidate());
  }

  Future<void> handleDeclineIncomingCall(String? reason) async {
    for (final peer in _peers.values) {
      await peer.declineCall(reason);
    }
  }

  Future<void> handleEndCall() async {
    for (final peer in _peers.values) {
      await peer.endCall();
    }
  }

  Future<PeerConnectionWrapper> getOrCreatePeer(
    String remoteId,
    MediaStream localStream,
  ) async {
    return _peers[remoteId] ??= await _createPeerConnection(remoteId, localStream);
  }

  Future<PeerConnectionWrapper> _createPeerConnection(
    String remoteId,
    MediaStream localStream,
  ) async {
    final wrapper = PeerConnectionWrapper(
      localUserId: _localUserId,
      remoteUserId: remoteId,
      callId: _callId,
      signaling: _signaling,
      localStream: localStream,
    );
    await wrapper.initialize();
    return wrapper;
  }

  void replaceVideoTracks(MediaStreamTrack videoTrack) {
    for (final peer in _peers.values) {
      peer.replaceVideoTrack(videoTrack);
    }
  }

  void pause() {
    //TODO: Implement this method
  }

  void resume() {
    //TODO: Implement this method
  }

  void removePeer(String remoteId) {
    _peers[remoteId]?.dispose();
    _peers.remove(remoteId);
    if (_peers.isEmpty) {
      _eventHandler._sendCallEvent(CallLifecycleStatus.ended);
    }
  }

  void disposeAll() {
    for (var peer in _peers.values) {
      peer.dispose();
    }
    _peers.clear();
  }
}
