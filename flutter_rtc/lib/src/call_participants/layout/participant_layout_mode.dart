
import '../../models/call_participant_state.dart';
import '../../sorting/call_participant_sorting_presets.dart';

enum ParticipantLayoutMode {
  /// The layout mode is set to grid view.
  grid,

  /// The layout mode is set to spotlight view.
  spotlight,

  pictureInPicture;
}

extension SortingExtension on ParticipantLayoutMode {
  Comparator<CallParticipantState> get sorting {
    switch (this) {
      case ParticipantLayoutMode.grid:
        return CallParticipantSortingPresets.regular;
      case ParticipantLayoutMode.spotlight:
        return CallParticipantSortingPresets.speaker;
      case ParticipantLayoutMode.pictureInPicture:
        return CallParticipantSortingPresets.speaker;
    }
  }
}
