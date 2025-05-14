import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../context/bloc/call_bloc.dart';
import '../context/model/member.dart';

mixin CallRendererMixin<T extends StatefulWidget> on State<T> {
  /// Unique local renderer.
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  /// Map of remote renderers by member.id.
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  Map<String, RTCVideoRenderer> get renderers => _remoteRenderers;

  /// Initializes all renderers (local + remotes) once.
  Future<void> initRenderers(List<Member> members) async {
    await localRenderer.initialize();
    for (final m in members) {
      final r = _remoteRenderers.putIfAbsent(m.id, () => RTCVideoRenderer());
      await r.initialize();
    }
  }

  /// Updates each renderer according to the call state.
  Future<void> updateRenderers(CallBlocState state) async {
    // Local
    final localStream =
        state.isVideoCall && state.localCameraOn ? state.localStream : null;
    if (localRenderer.srcObject != localStream) {
      localRenderer.srcObject = localStream;
    }

    // Remotes
    for (final m in state.callInfo.remoteMembers) {
      final r = _remoteRenderers.putIfAbsent(m.id, () => RTCVideoRenderer());
      final remoteStream = state.isVideoCall && m.cameraEnabled ? m.mediaStream : null;
      if (r.srcObject != remoteStream) {
        r.srcObject = remoteStream;
      }
    }
  }

  /// Returns an "active" renderer for minimized views, for example.
  RTCVideoRenderer activeRenderer(CallBlocState state) {
    final first = state.callInfo.remoteMembers.first;
    return _remoteRenderers.putIfAbsent(first.id, () => RTCVideoRenderer());
  }

  @override
  void dispose() {
    localRenderer.dispose();
    for (final r in _remoteRenderers.values) {
      r.dispose();
    }
    _remoteRenderers.clear();
    super.dispose();
  }
}
