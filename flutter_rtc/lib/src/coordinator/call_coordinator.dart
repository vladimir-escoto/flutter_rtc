// lib/src/coordinator/call_coordinator.dart

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/callkit_manager.dart';
import 'package:flutter_rtc/src/config/app_constants.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/context/call_context.dart';
import 'package:flutter_rtc/src/context/model/member.dart';
import 'package:flutter_rtc/src/signaling/mqtt_signaling.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:uuid/uuid.dart';

typedef GlobalEventCallback = void Function(dynamic event);
typedef UserData = Map<String, dynamic>;
typedef CallList = List<CallContext>;

class CallCoordinator {
  static final CallCoordinator instance = CallCoordinator._internal();

  CallCoordinator._internal();

  late final ISignaling _signaling;
  final _callKitManager = CallKitManager();

  final Map<String, CallContext> _activeCalls = {};
  final Map<String, StreamSubscription> _callSubs = {};
  final Map<String, UserData> _users = {};

  final _onGlobalEvent = StreamController<dynamic>.broadcast();
  final _callStreamController = StreamController<CallList>.broadcast();

  StreamSubscription? _signalingSubscription;
  StreamSubscription? _callEventsSubscription;

  bool _initialized = false;

  get onGlobalEvent => _onGlobalEvent.stream;

  Stream<CallList> get callStateStream => _callStreamController.stream;

  CallList get activeCalls => List.unmodifiable(_activeCalls.values);

  int get onHoldCount =>
      activeCalls
          .where((c) => c.isOnHold)
          .length;

  void _updateState() =>
      _callStreamController.add(List.from(_activeCalls.values));

  /// Initializes the coordinator with a shared signaling interface.
  void initialize({ISignaling? signaling}) {
    if (_initialized) return;

    if (signaling == null) {
      final config = SignalingConfiguration(
        brokerUrl: AppConstants.mqttServer,
        clientId: Uuid().v4(),
        port: AppConstants.mqttPort,
        topicPrefix: AppConstants.topicPrefix,
        keepAlive: AppConstants.keepAlive,
      );

      signaling = MQTTSignaling(config: config);
    }

    _signaling = signaling;
    _callKitManager.setGlobalEventCallback(_handCallKitGlobalEvent);
    _signaling.callEvents.listen(_handleCallEvent);
    _signaling.signalingEvents.listen(_handleSignalingEvent);
    _signaling.connect();
    _initialized = true;
  }

  void registerUser(String userId, {Map<String, dynamic> params = const {}}) {
    _users[userId] = params;
    _signaling.registerUser(userId);
  }

  /// Registers a new user and creates a session for them.
  void unregisterUser(String userId) {
    _users.remove(userId);
    _signaling.unregisterUser(userId);
  }

  Future<String> startSingleCall(
    String userId,
    String targetUserId, {
    CallMode mode = CallMode.audio,
  }) async => await startCall(
    userId: userId,
    members: [Member(id: targetUserId)],
    mode: CallMode.video,
  );

  Future<String> startCall({
    required String userId,
    required List<Member> members,
    CallMode mode = CallMode.audio,
  }) async {
    final context = _makeCall(userId, members, mode);
    context.startOutgoingCall();
    return context.callId;
  }

  CallContext _makeCall(String userId, List<Member> members, CallMode mode) {
    final callId = _generateCallId();
    debugPrint('[CallCoordinator] [callId: $callId] makeCall, callId: $callId');

    final context = CallContext(
      params: _users[userId] ?? const {},
      callId: callId,
      userId: userId,
      members: members,
      signaling: _signaling,
      isCaller: true,
      mode: mode
    );

    for (var c in _activeCalls.values) {
      c.holdCall();
    }

    _callSubs[callId] = context.callStatus.listen((event) =>
        _handleCallStatusEvent(event, callId));

    _activeCalls[callId] = context;

    return context;
  }

  void _handleCallStatusEvent(CallLifeCycleStatus event, String callId) {
    var status = _activeCalls[callId]?.status;
    debugPrint('[CallCoordinator] [callId: $callId] status: $status, new status: $event');

    _updateState();
    if (event == CallLifeCycleStatus.ended) {
      endCall(callId);
    }
  }

  /// Dispatches signaling events to the correct session and logs globally if needed.
  void _handleSignalingEvent(SignalingEvent event) {
    debugPrint('[CallCoordinator] Received event: ${event.type}');
    _onGlobalEvent.add(event); // Logging, tracing, analytics, etc.

    for (final context in _activeCalls.values) {
      context.setConnectionStatus(
        event.type == SignalingEventType.disconnected,
        event.data,
      );
    }
  }

  /// Handles an incoming signaling event and routes it to the correct call context.
  Future<void> _handleCallEvent(CallEventData data) async {
    _onGlobalEvent.add(data);
    var context = _activeCalls[data.callId];

    if (context == null) {
      debugPrint('[CallCoordinator] [callId: ${data.callId}] No active session for call $data');
      return;
    }

    await context.handleSignalingEvent(data);
  }

  ///handler callkit incoming events, for backGround proposes
  void _handCallKitGlobalEvent(CallKitEventData event) {
    debugPrint('[CallCoordinator] [callId: ${event.body["id"]}] Received callkit event: ${event.event}');
    if (event.event == CallKitEvent.incoming) {
      var callData = CallEventData.fromJson(event.body as Map<String, dynamic>);
      receiveIncomingCall(callData);
    } else if (event.event == CallKitEvent.start) {
      // TODO: started an outgoing call
      // TODO: show screen calling in Flutter
    }
  }

  void receiveIncomingCall(CallEventData data) {
    if (!_activeCalls.containsKey(data.callId)) {
      debugPrint('[CallCoordinator] [callId: ${data.callId}] receiveIncomingCall');
      var offer = data.toOffer();
      var context = _makeCall(data.to, offer.members, offer.mode);
      context.handleIncomingOffer(data);
    }
  }

  /// Clears all active sessions (used for logout or reset).
  void clearAllSessions() {
    debugPrint('[CallCoordinator] clearAllSessions');
    for (final entry in _activeCalls.entries) {
      entry.value.dispose();
      _callSubs.remove(entry.key)?.cancel();
    }
    _activeCalls.clear();
    _users.clear();
  }

  void endCall(String callId) {
    debugPrint('[CallCoordinator] [callId: $callId] endCall');
    _activeCalls.remove(callId)?.endCall();
    _callSubs.remove(callId)?.cancel();
    _callKitManager.endCall(callId);
    _updateState();
  }

  void holdCall(String callId, ) {
    debugPrint('[CallCoordinator] [callId: $callId] holdCall');
    _activeCalls[callId]?.holdCall();
  }

  void resumeCall(String callId) {
    debugPrint('[CallCoordinator] [callId: $callId] resumeCall');
    _activeCalls[callId]?.resumeCall();
  }

  void closeAllOnHold() {
    debugPrint('[CallCoordinator] closeAllOnHold');
    _activeCalls.removeWhere((key, value) => value.isOnHold);
    _updateState();
  }

  void setAppLifecycleState(AppLifecycleState status) {
    debugPrint('[CallCoordinator] setAppLifecycleState ${status.name}');
    for (final context in _activeCalls.values) {
      context.setAppLifecycleState(status);
    }
  }

  String _generateCallId() {
    // For now use timestamp; can be replaced with UUID if needed
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    clearAllSessions();
    _signalingSubscription?.cancel();
    _callEventsSubscription?.cancel();
    _signaling.dispose();
  }

  Future<String> simulateCall({
    CallLifeCycleStatus state = CallLifeCycleStatus.active,
    String userId = "John",
    List<Member> members = const [Member(id: "Patricia")],
    CallMode mode = CallMode.audio,
  }) async {
    final context = _makeCall(userId, members, mode);
    context.simulateCall(state);
    return context.callId;
  }
}
