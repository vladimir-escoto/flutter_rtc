import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../models/call.dart';
import '../../utils/extensions.dart';
import '../call_control_option.dart';

// These are eyeballed device IDs for the speaker and earpiece.
// based on Android and iOS enumerated devices.
const deviceIdSpeaker = 'speaker';
const deviceIdEarpiece = 'earpiece';

/// A widget that represents a call control option to toggle if the
/// speakerphone is on or off.
///
/// This widget is only available on Android and iOS.
class ToggleSpeakerphoneOption extends StatefulWidget {
  /// Creates a new instance of [ToggleSpeakerphoneOption].
  const ToggleSpeakerphoneOption({
    super.key,
    required this.call,
    this.enabledSpeakerphoneIcon = Icons.volume_up_rounded,
    this.disabledSpeakerphoneIcon = Icons.volume_off_rounded,
  });

  /// Represents a call.
  final Call call;

  /// The icon that is shown when the speakerphone is enabled.
  final IconData enabledSpeakerphoneIcon;

  /// The icon that is shown when the speakerphone is disabled.
  final IconData disabledSpeakerphoneIcon;

  @override
  State<ToggleSpeakerphoneOption> createState() => _ToggleSpeakerState();
}

class _ToggleSpeakerState extends State<ToggleSpeakerphoneOption> {
  Future<void> _setSpeakerphoneEnabled({bool enabled = false}) async {}

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var enabled = false;


    return CallControlOption(
      icon:
          enabled
              ? Icon(widget.enabledSpeakerphoneIcon)
              : Icon(widget.disabledSpeakerphoneIcon),
      onPressed: () async {
        try {
          // Enable/disable the speaker.
          await _setSpeakerphoneEnabled(enabled: !enabled);
        } catch (_) {}
      },
    );
  }
}
