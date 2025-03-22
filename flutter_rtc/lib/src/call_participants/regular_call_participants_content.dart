import 'package:flutter/material.dart';

import '../models/call.dart';
import '../models/call_participant_state.dart';
import '../theme/call_participant_theme.dart';
import '../utils/device_segmentation.dart';
import 'call_participant.dart';
import 'call_participants.dart';
import 'layout/call_participants_grid_view.dart';
import 'layout/call_participants_spotlight_view.dart';
import 'layout/participant_layout_mode.dart';
import 'local_video.dart';

/// A widget that represents the main area of the call when nobody is
/// sharing their screen.
class RegularCallParticipantsContent extends StatelessWidget {
  /// Creates a new instance of [RegularCallParticipantsContent].
  const RegularCallParticipantsContent({
    super.key,
    required this.call,
    required this.participants,
    this.callParticipantBuilder = _defaultParticipantBuilder,
    this.enableLocalVideo,
    this.localVideoParticipantBuilder,
    this.layoutMode = ParticipantLayoutMode.grid,
  });

  /// Represents a call.
  final Call call;

  /// The list of participants to display.
  final Iterable<CallParticipantState> participants;

  /// Enable local video view for the local participant.
  final bool? enableLocalVideo;

  /// Builder function used to build a participant grid item.
  final CallParticipantBuilder callParticipantBuilder;

  /// Builder function used to build a local video participant widget.
  final CallParticipantBuilder? localVideoParticipantBuilder;

  /// The layout mode used to display the participants.
  final ParticipantLayoutMode layoutMode;

  // The default participant builder.
  static Widget _defaultParticipantBuilder(
    BuildContext context,
    Call call,
    CallParticipantState participant,
  ) {
    return StreamCallParticipant(
      key: ValueKey(participant.userId),
      call: call,
      participant: participant,
      backgroundColor: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final participantsTheme = StreamCallParticipantTheme.of(context);

    final remoteParticipants = participants.where((e) => !e.isLocal);
    final localParticipant = participants.where((e) => e.isLocal).firstOrNull;

    if (layoutMode == ParticipantLayoutMode.spotlight) {
      var spotlight = participants.first;

      // In a 1-on-1 call we don't spotlight the local participant.
      if (remoteParticipants.length == 1) {
        spotlight = remoteParticipants.first;
      }

      final barParticipants = [...participants]..remove(spotlight);

      return CallParticipantsSpotlightView(
        call: call,
        spotlight: spotlight,
        participants: barParticipants,
        participantBuilder: callParticipantBuilder,
      );
    }

    // By default we don't show local video on desktop devices.
    final enableLocalVideo = this.enableLocalVideo ?? !isDesktopDevice;
    final showLocalVideo = enableLocalVideo && remoteParticipants.isNotEmpty;

    final gridParticipants = [...participants];
    if (showLocalVideo && localParticipant != null) {
      gridParticipants.remove(localParticipant);
    }

    Widget child = CallParticipantsGridView(
      call: call,
      participants: gridParticipants,
      itemBuilder: callParticipantBuilder,
      padding: participantsTheme.participantsGridPadding,
      mainAxisSpacing: participantsTheme.participantsGridMainAxisSpacing,
      crossAxisSpacing: participantsTheme.participantsGridCrossAxisSpacing,
    );

    if (showLocalVideo && localParticipant != null) {
      child = StreamLocalVideo(
        call: call,
        participant: localParticipant,
        participantBuilder: localVideoParticipantBuilder,
        child: child,
      );
    }

    return child;
  }
}
