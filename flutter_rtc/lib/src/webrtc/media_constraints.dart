


import 'package:flutter_rtc/src/webrtc/screen_share_constraints.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc_interface;

abstract class MediaConstraints {
  const MediaConstraints({this.deviceId});

  /// The deviceId of the capture device to use.
  /// Available deviceIds can be obtained through `flutter_webrtc`:
  /// <pre>
  /// import 'package:stream_webrtc_flutter/stream_webrtc_flutter.dart' as rtc;
  ///
  /// List<MediaDeviceInfo> devices = await rtc.navigator.mediaDevices.enumerateDevices();
  /// </pre>
  final String? deviceId;

  // All subclasses must be able to report constraints
  // https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
  Map<String, dynamic> toMap();

  MediaConstraints copyWith();
}

extension MediaDevices on rtc_interface.MediaDevices {
  Future<rtc.MediaStream> getMedia(MediaConstraints constraints) {
    final constraintsMap = constraints.toMap();

    if (constraints is ScreenShareConstraints) {
      return rtc.navigator.mediaDevices.getDisplayMedia(
        constraintsMap,
      );
    } else {
      return rtc.navigator.mediaDevices.getUserMedia(
        constraintsMap,
      );
    }
  }
}