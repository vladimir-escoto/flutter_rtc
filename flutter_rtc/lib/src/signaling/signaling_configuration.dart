// Configuration for the MQTT signaling.
class SignalingConfiguration {
  final String brokerUrl;
  final int port;
  final String clientId;
  final String topicPrefix;

  SignalingConfiguration({
    required this.brokerUrl,
    this.port = 1883,
    required this.clientId,
    this.topicPrefix = 'flutter_rtc',
  });
}
