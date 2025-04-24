// ---------- rtc_device_handler.dart ----------
part of 'rtc_manager.dart';

class _RTCDeviceHandler {
  Future<void> switchCamera(MediaStreamTrack? videoTrack) async {
    if (videoTrack == null) return;
    await Helper.switchCamera(videoTrack);
  }

  void setSpeakerphone(bool enabled) => Helper.setSpeakerphoneOn(enabled);
}
