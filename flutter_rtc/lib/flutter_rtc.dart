export 'src/signaling/signaling_interface.dart';
export 'src/signaling/mqtt_signaling.dart';
export 'src/signaling/signaling_configuration.dart';
export 'src/signaling/signaling_event.dart';
export 'src/call_manager.dart';

import 'src/signaling/mqtt_signaling.dart';
import 'src/signaling/signaling_configuration.dart';
import 'src/call_manager.dart';
import 'src/signaling/signaling_interface.dart';

class FlutterRTC {
  late final SignalingInterface signaling;
  late final CallManager callManager;

  /// The [clientId] must be specified by the application.
  /// Optionally, a custom signaling implementation can be provided.
  FlutterRTC({required String clientId, SignalingInterface? customSignaling}) {
    signaling =
        customSignaling ??
        MQTTSignaling(
          config: SignalingConfiguration(
            brokerUrl: 'broker.hivemq.com',
            clientId: clientId,
          ),
        );
    callManager = CallManager(signaling: signaling, clientId: clientId);
  }

  /// Initialize the package (establish local media, peer connection and signaling).
  Future<void> initialize() async {
    await signaling.connect();
    await callManager.initialize();
  }

  /// Initiate an outgoing call to [targetPeerId].
  Future<void> makeCall(String targetPeerId) async {
    await callManager.makeCall(targetPeerId);
  }

  /// Hang up the current call.
  Future<void> hangUp() async {
    await callManager.hangUp();
    await signaling.disconnect();
  }
}
