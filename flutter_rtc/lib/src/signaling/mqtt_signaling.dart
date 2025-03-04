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

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  MQTTSignaling({required this.config}) {
    _client = MqttServerClient(config.brokerUrl, config.clientId);
    _client.port = config.port;
    _client.logging(on: false);
    _client.keepAlivePeriod = 15;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
  }

  @override
  Stream<SignalingEvent> get events => _eventController.stream;

  @override
  Future<void> connect() async {
    try {
      debugPrint("[MQTT] Connecting to broker ${config.brokerUrl}...");
      await _client.connect();

    } catch (e) {
      debugPrint("[MQTT] Connection error: $e");
      _eventController.add(SignalingEvent(type: SignalingEventType.error, data: e));
      _scheduleReconnect(); // Attempt to reconnect if failed
    }
  }

  @override
  Future<void> disconnect() async {
    debugPrint("[MQTT] Disconnecting...");
    _client.disconnect();
  }

  /// Intenta reconectar con backoff exponencial
  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      final int delay = 2 << _reconnectAttempts; // Backoff exponencial (2^n segundos)
      debugPrint("[MQTT] Reconnecting in $delay seconds...");

      Future.delayed(Duration(seconds: delay), () {
        _reconnectAttempts++;
        connect();
      });
    } else {
      print("[MQTT] Maximum reconnect attempts reached.");
    }
  }

  void _onConnected() {
    debugPrint("[MQTT] Connection established");
    _eventController.add(SignalingEvent(type: SignalingEventType.connected));
    _reconnectAttempts = 0; // Reset the reconnection counter
    // Subscribe to the client's topic
    _client.subscribe('${config.topicPrefix}/${config.clientId}', MqttQos.atMostOnce);

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> event) {
      for (var msg in event) {
        final payload = (msg.payload as MqttPublishMessage).payload.message;
        final message = utf8.decode(payload);
        _handleIncomingMessage(message);
      }
    });
  }

  void _onDisconnected() {
    debugPrint("[MQTT] Disconnected");
    _eventController.add(SignalingEvent(type: SignalingEventType.disconnected));

    // Try to reconnect automatically
    _scheduleReconnect();
  }

  void _onSubscribed(String topic) {
    debugPrint("[MQTT] Subscribed to $topic");
  }

  Future<void> _publishMessage(String topic, Map<String, dynamic> message) async {
    if (_client.connectionStatus!.state != MqttConnectionState.connected) {
      debugPrint("[MQTT] Connection not established. Cannot publish message.");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(message));
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    debugPrint("[MQTT] Published on $topic: ${jsonEncode(message)}");
  }

  void _handleIncomingMessage(String message) {
    debugPrint("[MQTT] Received message: $message");
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String eventType = data['event'];

      switch (eventType) {
        case 'incomingOffer':
          _eventController.add(SignalingEvent(type: SignalingEventType.incomingOffer, data: {'senderId': data['senderId'], 'offer': data['offer']}));
          break;
        case 'incomingAnswer':
          _eventController.add(SignalingEvent(type: SignalingEventType.incomingAnswer, data: {'senderId': data['senderId'], 'answer': data['answer']}));
          break;
        case 'incomingIceCandidate':
          _eventController.add(SignalingEvent(type: SignalingEventType.incomingIceCandidate, data: {'senderId': data['senderId'], 'candidate': data['candidate']}));
          break;
        case 'callDeclined':
          _eventController.add(SignalingEvent(type: SignalingEventType.callDeclined, data: {'senderId': data['senderId'], 'info': data['info']}));
          break;
        case 'callEnded':
          _eventController.add(SignalingEvent(type: SignalingEventType.callEnded, data: {'senderId': data['senderId'], 'info': data['info']}));
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint("[MQTT] Error processing message: $e");
      _eventController.add(SignalingEvent(type: SignalingEventType.error, data: e));
    }
  }

  @override
  Future<void> sendOffer(String peerId, dynamic offer) async {
    await _publishMessage('${config.topicPrefix}/$peerId', {'event': 'incomingOffer', 'senderId': config.clientId, 'offer': offer});
  }

  @override
  Future<void> sendAnswer(String peerId, dynamic answer) async {
    await _publishMessage('${config.topicPrefix}/$peerId', {'event': 'incomingAnswer', 'senderId': config.clientId, 'answer': answer});
  }

  @override
  Future<void> sendIceCandidate(String peerId, dynamic candidate) async {
    await _publishMessage('${config.topicPrefix}/$peerId', {'event': 'incomingIceCandidate', 'senderId': config.clientId, 'candidate': candidate});
  }

  @override
  Future<void> sendCallDecline(String peerId, dynamic info) async {
    await _publishMessage('${config.topicPrefix}/$peerId', {'event': 'callDeclined', 'senderId': config.clientId, 'info': info});
  }

  @override
  Future<void> sendCallEnded(String peerId, info) async {
    await _publishMessage('${config.topicPrefix}/$peerId', {'event': 'callEnded', 'senderId': config.clientId, 'info': info});
  }
}
