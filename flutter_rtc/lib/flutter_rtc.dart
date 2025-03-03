export 'src/signaling/signaling_interface.dart';
export 'src/signaling/mqtt_signaling.dart';
export 'src/signaling/signaling_configuration.dart';
export 'src/signaling/signaling_event.dart';
export 'src/call_manager.dart';
export 'src/ui/call_screen.dart';
export 'src/ui/flutter_rtc_widget.dart';
export 'src/ui/incoming_call_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/call_manager.dart';
import 'package:flutter_rtc/src/signaling/mqtt_signaling.dart';
import 'package:flutter_rtc/src/signaling/signaling_configuration.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:flutter_rtc/src/ui/call_screen.dart';

class FlutterRTC {
  late final SignalingInterface signaling;
  late final CallManager callManager;
  final GlobalKey<NavigatorState> navigatorKey;

  FlutterRTC({
    required String clientId,
    SignalingInterface? customSignaling,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    signaling = customSignaling ??
        MQTTSignaling(
          config: SignalingConfiguration(
            brokerUrl: 'broker.emqx.io',
            clientId: clientId,
          ),
        );
    callManager = CallManager(signaling: signaling, clientId: clientId);
  }

  Future<void> initialize(BuildContext context) async {
    await callManager.setupIncomingCallListener(context);
    await signaling.connect();
  }

  Future<void> makeCall(String targetPeerId) async {
    await callManager.startOutgoingCall(targetPeerId);
    // navigatorKey.currentState?.push(MaterialPageRoute(
    //   builder: (_) => EnhancedCallScreen(
    //     callManager: callManager,
    //     onHangUp: () async => hangUp(),
    //     onRedial: () {
    //       // Implement re-dial logic if needed.
    //     },
    //   ),
    // ));
  }

  Future<void> hangUp() async {
    await callManager.hangUp();
    await signaling.disconnect();
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}

