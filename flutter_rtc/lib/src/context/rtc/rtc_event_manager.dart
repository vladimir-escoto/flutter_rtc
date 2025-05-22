part of 'rtc_manager.dart';

typedef RemoteEvent = Map<String, dynamic>;

class _RTCEventHandler {
  final _peerEventController = StreamController<PeerCallEvent>.broadcast();
  final _callEventController = StreamController<CallEvent>.broadcast();
  final _remoteEventController = StreamController<RemoteEvent>.broadcast();

  RTCDataChannel? dataChannel;

  Stream<PeerCallEvent> get peerEvents => _peerEventController.stream;

  Stream<CallEvent> get callEvents => _callEventController.stream;

  Stream<RemoteEvent> get remoteEventEvents => _remoteEventController.stream;

  void sendCallEvent(CallLifeCycleStatus status, {dynamic value}) {
    _callEventController.add(CallEvent(status, value: value));
  }

  void sendPeerEvent(String memberId, ConnectionStatus status,
      {dynamic value}) =>
      _peerEventController.add(PeerCallEvent(memberId, status, value: value));

  void dispose() {
    _peerEventController.close();
    _callEventController.close();
    _remoteEventController.close();
  }
}
