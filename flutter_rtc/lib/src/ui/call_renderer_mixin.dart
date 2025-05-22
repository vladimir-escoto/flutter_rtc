import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../context/bloc/call_bloc.dart';

mixin CallRendererMixin<T extends StatefulWidget> on State<T> {
  @protected
  String get userId;
  /// Map of remote renderers by member.id.
  final Map<String, RTCVideoRenderer> _renderers = {};

  RTCVideoRenderer? get localRenderer =>
      _renderers[userId];

  RTCVideoRenderer get activeRenderer =>
      _renderers.entries
          .where((e) => e.key != userId)
          .first
          .value;

  Map<String, RTCVideoRenderer> get renderers => _renderers;

  /// Initializes all renderers (local + remotes) once.
  Future<void> initRenderers(CallBlocState state) async {
    for (final m in state.members) {
      final r = _renderers.putIfAbsent(m.id, () => RTCVideoRenderer());
      await r.initialize();
    }
  }

  /// Updates each renderer according to the call state.
  Future<void> updateRenderers(CallBlocState state) async {
    debugPrint('[CallRendererMixin]:Updating renderers: ${state.members
        .where((e) => e.mediaStream != null)
        .length})}');
    for (final m in state.members) {
      final r = _renderers[m.id];
      if (r == null) continue;
      if (r.textureId != null && r.srcObject != m.mediaStream) {
        r.srcObject = m.mediaStream;
      }
    }
  }

  @override
  void dispose() {
    for (final r in _renderers.values) {
      r.dispose();
    }
    _renderers.clear();
    super.dispose();
  }
}
