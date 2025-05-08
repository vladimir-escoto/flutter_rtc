import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../context/model/member.dart';
import '../context/bloc/call_bloc.dart';

mixin CallRendererMixin<T extends StatefulWidget> on State<T> {
  /// Renderer local único.
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  /// Map de renderers remotos por member.id.
  final Map<String, RTCVideoRenderer> remoteRenderers = {};

  /// Inicializa todos los renderers (local + remotos) una sola vez.
  Future<void> initRenderers(List<Member> members) async {
    await localRenderer.initialize();
    for (final m in members) {
      final r = remoteRenderers.putIfAbsent(m.id, () => RTCVideoRenderer());
      await r.initialize();
    }
  }

  /// Actualiza cada renderer según el estado de la llamada.
  Future<void> updateRenderers(CallBlocState state) async {
    // Local
    if (state.isVideoCall && state.localCameraOn) {
      localRenderer.srcObject = state.localStream;
    } else {
      localRenderer.srcObject = null;
    }

    // Remotos
    for (final m in state.callInfo.remoteMembers) {
      final r = remoteRenderers.putIfAbsent(m.id, () => RTCVideoRenderer());
      await r.initialize();
      if (!state.isVideoCall || !m.cameraEnabled) {
        r.srcObject = null;
      } else if (r.srcObject != m.mediaStream) {
        r.srcObject = m.mediaStream;
      }
    }
  }

  /// Devuelve un renderer “activo” para vistas minimizadas, por ejemplo.
  RTCVideoRenderer activeRenderer(CallBlocState state) {
    final first = state.callInfo.remoteMembers.first;
    return remoteRenderers.putIfAbsent(first.id, () => RTCVideoRenderer());
  }

  @override
  void dispose() {
    localRenderer.dispose();
    for (final r in remoteRenderers.values) {
      r.dispose();
    }
    remoteRenderers.clear();
    super.dispose();
  }
}
