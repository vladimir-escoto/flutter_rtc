// lib/src/coordinator/call_coordinator.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/session/call_user_session.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';

import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';

typedef GlobalEventCallback = void Function(String userId, dynamic event);

class CallCoordinator {
  static final CallCoordinator instance = CallCoordinator._internal();

  CallCoordinator._internal();

  final Map<String, CallUserSession> _userSessions = {};
  late final SignalingInterface signaling;

  GlobalEventCallback? onGlobalEvent;

  bool _initialized = false;

  /// Initializes the coordinator with a shared signaling interface.
  void initialize(SignalingInterface signalingInterface, {GlobalEventCallback? onEvent}) {
    if (_initialized) return;
    signaling = signalingInterface;
    onGlobalEvent = onEvent;
    signaling.setOnMessage(_handleSignalingEvent);
    _initialized = true;
  }

  /// Registers a new user and creates a session for them.
  void registerUser(String userId) {
    if (_userSessions.containsKey(userId)) return;
    final session = CallUserSession(userId, signaling);
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
  }) async {
    return await startCall(
      userId: userId,
      participants: [Participant(userId: targetUserId)],
      mode: CallMode.video,
    );
  }

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
    final session = _userSessions[userId];
    if (session == null) {
      throw Exception('User session not found for userId: $userId');
    }
    return session;
  }

  /// Dispatches signaling events to the correct session and logs globally if needed.
  void _handleSignalingEvent(Map<String, dynamic> event) {
    final to = event['to'];
    if (to == null) return;

    final session = _userSessions[to];
    if (session == null) {
      debugPrint('[SignalingDispatcher] No active session for userId: $to');
      return;
    }

    onGlobalEvent?.call(session.userId, event); // Logging, tracing, analytics, etc.
    session.handleSignalingEvent(event);
  }

  /// Clears all active sessions (used for logout or reset).
  void clearAllSessions() {
    for (final session in _userSessions.values) {
      session.dispose();
    }
    _userSessions.clear();
  }

  /// Optional: restore session from persistence layer.
  void restoreSession(String userId, dynamic savedState) {
    final session = CallUserSession(userId, signaling);
    session.restoreFromState(savedState);
    _userSessions[userId] = session;
  }
}
