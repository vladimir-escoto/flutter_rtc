// lib/src/coordinator/call_coordinator.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/callkit_manager.dart';
import 'package:flutter_rtc/src/context/call_context.dart';
import 'package:flutter_rtc/src/session/call_user_session.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';

import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
import 'package:flutter_rtc/src/coordinator/signaling_event.dart';

export 'package:flutter_rtc/src/context/bloc/call_enums.dart';
export 'package:flutter_rtc/src/context/model/participant.dart';

typedef GlobalEventCallback = void Function(dynamic event);

class CallCoordinator {
  static final CallCoordinator instance = CallCoordinator._internal();

  CallCoordinator._internal();

  final callKitManager = CallKitManager();

  final Map<String, CallUserSession> _userSessions = {};


  late final SignalingInterface signaling;

  GlobalEventCallback? onGlobalEvent;

  CallUserSession? getUserSessionByCallId(String callId) =>
      _userSessions.values.where((s) => s.containsCall(callId)).firstOrNull;

  bool _initialized = false;

  /// Initializes the coordinator with a shared signaling interface.
  void initialize(SignalingInterface signalingInterface, {GlobalEventCallback? onEvent}) {
    if (_initialized) return;
    signaling = signalingInterface;
    onGlobalEvent = onEvent;
    callKitManager.setGlobalEventCallback(_handCallKitGlobalEvent);
    signaling.setOnSignalingEvent(_handleSignalingEvent);
    signaling.setOnCallEvent(_handleCallEvent);
    _initialized = true;
  }

  /// Registers a new user and creates a session for them.
  void registerUser(String userId, {Map<String, dynamic> params = const {}}) {
    if (_userSessions.containsKey(userId)) return;
    final session = CallUserSession(userId, signaling, params);
    _userSessions[userId] = session;
    signaling.registerUser(userId);
  }

  void unregisterUser(String userId) {
    final session = _userSessions.remove(userId);
    if (session != null) {
      // Dispose the session to release resources.
      session.dispose();
      signaling.unregisterUser(userId);
    }
  }

  Future<String> startSingleCall(
    String userId,
    String targetUserId, {
    CallMode mode = CallMode.audio,
  }) async => await startCall(
    userId: userId,
    participants: [Participant(userId: targetUserId)],
    mode: CallMode.video,
  );

  Future<String> startCall({
    required String userId,
    required List<Participant> participants,
    CallMode mode = CallMode.audio,
  }) async {
    final session = _getUserSession(userId);
    return await session.startCall(participants, mode);
  }

  /// Returns a session for a given user.
  CallUserSession _getUserSession(String userId) {
    registerUser(userId);
    final session = _userSessions[userId];
    if (session == null) {
      throw Exception('User session not found for userId: $userId');
    }
    return session;
  }

  /// Dispatches signaling events to the correct session and logs globally if needed.
  void _handleSignalingEvent(SignalingEvent event) {
    debugPrint('[CallCoordinator] Received event: ${event.type}');
    onGlobalEvent?.call(event); // Logging, tracing, analytics, etc.

    for (final session in _userSessions.values) {
      session.setConnectionStatus(
        event.type == SignalingEventType.disconnected,
        event.data,
      );
    }
  }

  Future<void> _handleCallEvent(CallEventData data) async {
    var session = getUserSessionByCallId(data.callId);

    if (session == null) {
      debugPrint('[CallCoordinator] No active session for call $data');
      return;
    }

    await session.handleSignalingCallEvent(data);
  }

  ///handler callkit incoming events, for backGround proposes
  void _handCallKitGlobalEvent(CallKitEventData event) {
    debugPrint('[CallCoordinator] Received callkit event: ${event.event}');
    if (event.event == CallKitEvent.incoming) {
      debugPrint('[CallCoordinator] Received callkit Incoming event: ${event.body}');
      var callData = CallEventData.fromJson(event.body as Map<String, dynamic>);
      debugPrint(
        '[CallCoordinator] UserSession Exist? [${_userSessions.containsKey(callData.to)}]',
      );
      //Todo: Validate if the user session exist
      final session = _getUserSession(callData.to);
      session.receiveIncomingCall(callData);
    } else if (event.event == CallKitEvent.start) {
      // TODO: started an outgoing call
      // TODO: show screen calling in Flutter
    }
  }

  /// Clears all active sessions (used for logout or reset).
  void clearAllSessions() {
    callKitManager.endAllCalls();
    for (final session in _userSessions.values) {
      session.dispose();
    }
    _userSessions.clear();
  }

  void endCall(String callId) {
    final session = getUserSessionByCallId(callId);
    if (session != null) {
      session.endCall(callId);
    }
  }

  void setAppLifecycleState(AppLifecycleState status) {
    for (final session in _userSessions.values) {
      session.setAppLifecycleState(status);
    }
  }
}
