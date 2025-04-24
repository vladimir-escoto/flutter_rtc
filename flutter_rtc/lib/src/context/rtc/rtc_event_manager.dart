part of 'rtc_manager.dart';

class _RTCEventHandler {
  final StreamController<CallEvent> _callEventController =
      StreamController<CallEvent>.broadcast();

  Stream<CallEvent> get callEvents => _callEventController.stream;

  RTCDataChannel? dataChannel;
  final StreamController<Map<String, dynamic>> _remoteControlController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get remoteControlEvents => _remoteControlController.stream;

  void _sendCallEvent(CallLifecycleStatus status, {dynamic value}) {
    _callEventController.add(CallEvent(type: status, value: value));
  }
}
