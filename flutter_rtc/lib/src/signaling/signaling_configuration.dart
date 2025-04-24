part of 'signaling_interface.dart';

// Configuration for the MQTT signaling.
class SignalingConfiguration {
  final String brokerUrl;
  final int port;
  final String clientId;
  final String topicPrefix;
  final int keepAlive;

  SignalingConfiguration({
    required this.brokerUrl,
    required this.port,
    required this.clientId,
    required this.topicPrefix,
    required this.keepAlive,
  });
}
