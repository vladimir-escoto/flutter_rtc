import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

import 'signaling_interface.dart';

class MQTTSignaling implements ISignaling {
  final SignalingConfiguration config;

  final StreamController<SignalingEvent> _signalingEC = StreamController.broadcast();
  final StreamController<CallEventData> _callEC = StreamController.broadcast();

  final int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;
  late final MqttServerClient _client;
  StreamSubscription? _sub;

  @override
  Stream<CallEventData> get callEvents => _callEC.stream;

  @override
  Stream<SignalingEvent> get signalingEvents => _signalingEC.stream;

  MQTTSignaling({required this.config}) {
    _client = MqttServerClient(config.brokerUrl, config.clientId);
    _client.port = config.port;
    _client.logging(on: false);
    _client.keepAlivePeriod = config.keepAlive; // Keep the connection alive
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.onSubscribeFail = _onSubscribeFail;
    _client.onUnsubscribed = _onUnsubscribed;
    _client.pongCallback = _onPong;

    final connMess =
        MqttConnectMessage().withClientIdentifier(config.clientId).startSession();
    _client.connectionMessage = connMess;
  }

  @override
  Future<void> connect() async {
    try {
      debugPrint("[MQTT] Connecting to broker ${config.brokerUrl}...");
      await _client.connect();
    } catch (e) {
      debugPrint("[MQTT] Connection error: $e");
      _signalingEC.add(SignalingEvent(type: SignalingEventType.error, data: e));
      _scheduleReconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    debugPrint("[MQTT] Disconnecting...");
    _client.disconnect();
  }

  /// Attempts to reconnect with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      final int delay = 2 << _reconnectAttempts;
      debugPrint("[MQTT] Reconnecting in $delay seconds...");

      Future.delayed(Duration(seconds: delay), () {
        _reconnectAttempts++;
        connect();
      });
    } else {
      debugPrint("[MQTT] Maximum reconnect attempts reached.");
    }
  }

  void _onConnected() {
    debugPrint("[MQTT] Connection established");
    _signalingEC.add(SignalingEvent(type: SignalingEventType.connected));

    _sub = _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> event) {
      for (var msg in event) {
        final payload = (msg.payload as MqttPublishMessage).payload.message;
        final message = utf8.decode(payload as List<int>);
        _handleIncomingMessage(message);
      }
    });
  }

  void _onDisconnected() {
    debugPrint("[MQTT] Disconnected");
    _signalingEC.add(SignalingEvent(type: SignalingEventType.disconnected));
    _scheduleReconnect();
  }

  void _onSubscribed(MqttSubscription subscription) {
    debugPrint("[MQTT] Subscribed to ${subscription.toString()}");
  }

  void _onSubscribeFail(MqttSubscription subscription) {
    debugPrint("[MQTT] Failed to subscribe to ${subscription.toString()}");
  }

  void _onUnsubscribed(MqttSubscription subscription) {
    debugPrint("[MQTT] Unsubscribed from  ${subscription.toString()}");
  }

  void _onPong() {
    //debugPrint("[MQTT] Ping response received");
  }

  Future<void> _publishMessage(String topic, Map<String, dynamic> message) async {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint("[MQTT] Connection not established. Cannot publish message.");
      return;
    }
    final builder = MqttPayloadBuilder();
    builder.addString(jsonEncode(message));
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    debugPrint("[MQTT] Published on $topic: ${jsonEncode(message)}");
  }

  void _handleIncomingMessage(String message) {
    debugPrint("[MQTT] Received message: $message");
    try {
      final Map<String, dynamic> data = jsonDecode(message);

      var callData = CallEventData.fromJson(data);
      _callEC.add(callData);
    } catch (e) {
      debugPrint("[MQTT] Error processing message: $e");
      _signalingEC.add(SignalingEvent(type: SignalingEventType.error, data: e));
    }
  }

  @override
  Future<void> registerUser(String userId) async {
    debugPrint("[MQTT] register User: $userId");
    // Subscribe to the client's topic
    final topic = '${config.topicPrefix}/+/+/$userId';
    _client.subscribe(topic, MqttQos.atMostOnce);
  }

  @override
  Future<void> unregisterUser(String userId) async {
    debugPrint("[MQTT] Unregister User: $userId");
    // Unsubscribe to the client's topic
    final topic = '${config.topicPrefix}/+/+/$userId';
    _client.unsubscribeStringTopic(topic);
  }

  @override
  Future<void> sendEvent(CallEventData payload) async {
    final topic =
        '${config.topicPrefix}/${payload.callId}/${payload.type.name}/${payload.to}';
    debugPrint("[MQTT] sendEvent: ${payload.type.name} to $topic: ${payload.toJson()}");
    await _publishMessage(topic, payload.toJson());
  }

  @override
  void dispose() {
    debugPrint("[MQTT] dispose");
    _sub?.cancel();
    _callEC.close();
    _signalingEC.close();
  }

  @override
  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;
}
