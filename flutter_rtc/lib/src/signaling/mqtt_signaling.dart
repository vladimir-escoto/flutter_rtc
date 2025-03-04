import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'signaling_interface.dart';
import 'signaling_event.dart';
import 'signaling_configuration.dart';

class MQTTSignaling implements SignalingInterface {
  final SignalingConfiguration config;
  late MqttServerClient _client;
  final StreamController<SignalingEvent> _eventController = StreamController.broadcast();

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
      print("[MQTT] Connecting to broker ${config.brokerUrl}...");
      await _client.connect();
      print("[MQTT] Connected");
      // Subscribe to the client's topic.
      _client.subscribe('${config.topicPrefix}/${config.clientId}', MqttQos.atMostOnce);
      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> event) {
        for (var msg in event) {
          final payload = (msg.payload as MqttPublishMessage).payload.message;
          final message = utf8.decode(payload);
          _handleIncomingMessage(message);
        }
      });
    } catch (e) {
      print("[MQTT] Connection error: $e");
      _eventController.add(SignalingEvent(type: SignalingEventType.error, data: e));
    }
  }

  @override
  Future<void> disconnect() async {
    print("[MQTT] Disconnecting...");
    _client.disconnect();
  }

  Future<void> _publishMessage(String topic, Map<String, dynamic> message) async {
    if (_client.connectionStatus!.state != MqttConnectionState.connected) {
      debugPrint("[MQTT] Connection not established. Cannot publish message.");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(message));
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print("[MQTT] Published on $topic: ${jsonEncode(message)}");
  }

  void _handleIncomingMessage(String message) {
    print("[MQTT] Received message: $message");
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String eventType = data['event'];
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
              data: {'senderId': data['senderId'], 'candidate': data['candidate']},
            ),
          );
          break;
        case 'callDeclined':
          _eventController.add(
            SignalingEvent(
              type: SignalingEventType.callDeclined,
              data: {'senderId': data['senderId'], 'info': data['info']},
            ),
          );
          break;
        case 'callEnded':
          _eventController.add(
            SignalingEvent(
              type: SignalingEventType.callEnded,
              data: {'senderId': data['senderId'], 'info': data['info']},
            ),
          );
          break;
        default:
          break;
      }
    } catch (e) {
      print("[MQTT] Error processing message: $e");
      _eventController.add(SignalingEvent(type: SignalingEventType.error, data: e));
    }
  }

  void _onConnected() {
    print("[MQTT] Connection established");
    _eventController.add(SignalingEvent(type: SignalingEventType.connected));
  }

  void _onDisconnected() {
    print("[MQTT] Disconnected");
    _eventController.add(SignalingEvent(type: SignalingEventType.disconnected));
  }

  void _onSubscribed(String topic) {
    print("[MQTT] Subscribed to $topic");
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

  @override
  Future<void> sendCallDecline(String peerId, dynamic info) async {
    final topic = '${config.topicPrefix}/$peerId';
    final message = {'event': 'callDeclined', 'senderId': config.clientId, 'info': info};
    await _publishMessage(topic, message);
  }

  @override
  Future<void> sendCallEnded(String peerId, info) async {
    final topic = '${config.topicPrefix}/$peerId';
    final message = {'event': 'callEnded', 'senderId': config.clientId, 'info': info};
    await _publishMessage(topic, message);
  }
}
