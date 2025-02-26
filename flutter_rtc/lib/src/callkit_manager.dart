import 'dart:async';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

// Enumeration for CallKit events.
enum CallKitEvent { accepted, declined }

class CallKitManager {
  final StreamController<CallKitEvent> _callKitEventController = StreamController.broadcast();
  Stream<CallKitEvent> get callKitEvents => _callKitEventController.stream;

  /// Displays the incoming call notification using CallKit.
  Future<void> showIncomingCall({required String callId, required String callerName}) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'FlutterRTC',
      type: 1, // video call
      duration: 30000,
    );
    print("[CallKit] Showing incoming call from $callerName (id: $callId)");
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    // For demonstration, simulate acceptance after 5 seconds.
    Future.delayed(Duration(seconds: 5), () {
      print("[CallKit] Simulated: call accepted");
      _callKitEventController.add(CallKitEvent.accepted);
    });
    // In a real implementation, listen to native CallKit events and add accepted/declined accordingly.
  }

  Future<void> hideIncomingCall({required String callId}) async {
    await FlutterCallkitIncoming.endCall(callId);
  }
}
