import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'signaling_interface.dart';
import 'signaling_event.dart';
import 'signaling_configuration.dart';

class MQTTSignaling implements SignalingInterface {
  final SignalingConfiguration config;
  late MqttServerClient _client;
  final StreamController<SignalingEvent> _eventController =
      StreamController.broadcast();

  MQTTSignaling({required this.config}) {
    _client = MqttServerClient(config.brokerUrl, config.clientId);
    _client.port = config.port;
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
  }

  @override
  Stream<SignalingEvent> get events => _eventController.stream;

  @override
  Future<void> connect() async {
    try {
      await _client.connect();
      // Subscribe to a topic specific to this client to receive signaling messages.
      _client.subscribe(
        '${config.topicPrefix}/${config.clientId}',
        MqttQos.atMostOnce,
      );

      // Listen for incoming messages.
      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> event) {
        for (var msg in event) {
          final payload = (msg.payload as MqttPublishMessage).payload.message;
          final message = utf8.decode(payload);
          _handleIncomingMessage(message);
        }
      });
    } catch (e) {
      _eventController.add(
        SignalingEvent(type: SignalingEventType.error, data: e),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _client.disconnect();
  }

  Future<void> _publishMessage(
    String topic,
    Map<String, dynamic> message,
  ) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(message));
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void _handleIncomingMessage(String message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String eventType = data['event'];
      // It's assumed that the sender's client id is included in the data.
      switch (eventType) {
        case 'incomingOffer':
          _eventController.add(
            SignalingEvent(
              type: SignalingEventType.incomingOffer,
              data: {'senderId': data['senderId'], 'offer': data['offer']},
            ),
          );
          break;
        case 'incomingAnswer':
          _eventController.add(
            SignalingEvent(
              type: SignalingEventType.incomingAnswer,
              data: {'senderId': data['senderId'], 'answer': data['answer']},
            ),
          );
          break;
        case 'incomingIceCandidate':
          _eventController.add(
            SignalingEvent(
              type: SignalingEventType.incomingIceCandidate,
              data: {
                'senderId': data['senderId'],
                'candidate': data['candidate'],
              },
            ),
          );
          break;
        default:
          break;
      }
    } catch (e) {
      _eventController.add(
        SignalingEvent(type: SignalingEventType.error, data: e),
      );
    }
  }

  void _onConnected() {
    _eventController.add(SignalingEvent(type: SignalingEventType.connected));
  }

  void _onDisconnected() {
    _eventController.add(SignalingEvent(type: SignalingEventType.disconnected));
  }

  void _onSubscribed(String topic) {
    // Optionally handle subscription confirmation.
  }

  @override
  Future<void> sendOffer(String peerId, dynamic offer) async {
    final topic = '${config.topicPrefix}/$peerId';
    final message = {
      'event': 'incomingOffer',
      'senderId': config.clientId,
      'offer': offer,
    };
    await _publishMessage(topic, message);
  }

  @override
  Future<void> sendAnswer(String peerId, dynamic answer) async {
    final topic = '${config.topicPrefix}/$peerId';
    final message = {
      'event': 'incomingAnswer',
      'senderId': config.clientId,
      'answer': answer,
    };
    await _publishMessage(topic, message);
  }

  @override
  Future<void> sendIceCandidate(String peerId, dynamic candidate) async {
    final topic = '${config.topicPrefix}/$peerId';
    final message = {
      'event': 'incomingIceCandidate',
      'senderId': config.clientId,
      'candidate': candidate,
    };
    await _publishMessage(topic, message);
  }
}
