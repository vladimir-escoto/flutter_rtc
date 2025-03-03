export 'src/signaling/signaling_interface.dart';
export 'src/signaling/mqtt_signaling.dart';
export 'src/signaling/signaling_configuration.dart';
export 'src/signaling/signaling_event.dart';
export 'src/call_manager.dart';
export 'src/ui/call_screen.dart';

import 'package:flutter/material.dart';

import 'flutter_rtc.dart';

class FlutterRTC {
  late final SignalingInterface signaling;
  late final CallManager callManager;
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Constructs FlutterRTC with a 6-digit client ID.
  /// Optionally, a custom signaling implementation and navigatorKey can be provided.
  FlutterRTC({
    required String clientId,
    SignalingInterface? customSignaling,
    this.navigatorKey,
  }) {
    signaling =
        customSignaling ??
        MQTTSignaling(
          config: SignalingConfiguration(brokerUrl: 'broker.emqx.io', clientId: clientId),
        );
    callManager = CallManager(signaling: signaling, clientId: clientId);
  }

  /// Initialize the framework (only signaling is connected at this point).
  Future<void> initialize() async {
    await callManager.setupIncomingCallListener();
    await signaling.connect();
  }

  /// Initiates an outgoing call.
  Future<void> makeCall(String targetPeerId) async {
    await callManager.startOutgoingCall(targetPeerId);
    // If a navigatorKey is provided, show the call screen modal.
    if (navigatorKey != null && navigatorKey!.currentState != null) {
      navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => CallScreen(callManager: callManager, onHangUp: hangUp),
          fullscreenDialog: true,
        ),
      );
    }
  }

  /// Hangs up the call.
  Future<void> hangUp() async {
    await callManager.hangUp();
    await signaling.disconnect();
    // If a navigatorKey is provided, pop the call screen modal.
    if (navigatorKey != null && navigatorKey!.currentState != null) {
      navigatorKey!.currentState!.pop();
    }
  }

  void checkNotificationPermission(BuildContext context) {
    callManager.checkNotificationPermission(context);
  }
}
