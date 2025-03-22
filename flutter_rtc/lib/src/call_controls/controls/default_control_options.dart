import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/call_controls/controls/toggle_camera_option.dart';
import 'package:flutter_rtc/src/call_controls/controls/toggle_microphone_option.dart';
import 'package:flutter_rtc/src/call_controls/controls/toggle_screen_sharing_option.dart';
import 'package:flutter_rtc/src/call_controls/controls/toggle_speakerphone_option.dart';

import '../../models/call.dart';
import '../../models/call_participant_state.dart';
import 'flip_camera_option.dart';
import 'leave_call_option.dart';



/// Builds the default set of call control options.
List<Widget> defaultCallControlOptions({
  required Call call,
  required CallParticipantState localParticipant,
}) {
  return [
    ToggleScreenShareOption(call: call, localParticipant: localParticipant),
    ToggleSpeakerphoneOption(call: call),
    ToggleCameraOption(call: call, localParticipant: localParticipant),
    ToggleMicrophoneOption(call: call, localParticipant: localParticipant),
    FlipCameraOption(call: call, localParticipant: localParticipant),
    LeaveCallOption(call: call)
  ];
}
