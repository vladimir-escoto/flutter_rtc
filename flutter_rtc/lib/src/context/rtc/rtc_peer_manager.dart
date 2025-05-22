// ---------- rtc_peer_manager.dart ----------
part of 'rtc_manager.dart';

class _RTCPeerManager {
  final String _localUserId;
  final String _callId;
  final ISignaling _signaling;
  final Map<String, PeerConnectionWrapper> _peers = {};
  final _RTCEventHandler _eventHandler;
  final ConnectionStateCallback? onConnectionState;

  Map<String, MediaStream?> get remoteMediaStream =>
      Map.fromEntries(_peers.values.map((p) => p.remoteMediaStream).toList());

  _RTCPeerManager(this._localUserId, this._callId, this._signaling,
      this._eventHandler, this.onConnectionState);

  Future<void> createOffersFor(
    List<Member> members,
    MediaStream localStream,
    CallMode mode,
  ) async {
    for (final member in members.where((p) => p.id != _localUserId)) {
      final peer = await getOrCreatePeer(member.id, localStream);
      await peer.createOffer(mode, members);
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
    _eventHandler.sendCallEvent(CallLifeCycleStatus.ringing);
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

  Future<void> handleIncomingHold(CallEventData data) async {
    final peer = _peers[data.from];
    if (peer == null) return;
    await peer.remoteHold();
  }

  Future<void> handleIncomingResume(CallEventData data) async {
    final peer = _peers[data.from];
    if (peer == null) return;
    await peer.remoteResume();
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
      onConnectionState: onConnectionState,
    );
    await wrapper.initialize();
    return wrapper;
  }

  void replaceVideoTracks(MediaStreamTrack videoTrack) {
    for (final peer in _peers.values) {
      peer.replaceVideoTrack(videoTrack);
    }
  }

  void holdCall() {
    for (final peer in _peers.values) {
      peer.holdCall();
    }
  }

  void resumeCall() {
    for (final peer in _peers.values) {
      peer.resumeCall();
    }
  }

  void removePeer(String remoteId) {
    _peers[remoteId]?.dispose();
    _peers.remove(remoteId);
    if (_peers.isEmpty) {
      _eventHandler.sendCallEvent(CallLifeCycleStatus.ended);
    }
  }

  void disposeAll() {
    for (var peer in _peers.values) {
      peer.dispose();
    }
    _peers.clear();
  }
}
