import 'dart:async';

class CallEvents {
  final StreamController<String> _eventController =
      StreamController.broadcast();

  Stream<String> get events => _eventController.stream;

  // Trigger an event for an incoming call
  void triggerIncomingCall() {
    _eventController.add("incoming_call");
  }

  // Dispose the controller when done
  void dispose() {
    _eventController.close();
  }
}
