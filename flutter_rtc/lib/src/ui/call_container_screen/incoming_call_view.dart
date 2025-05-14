part of "../call_container_screen.dart";

class IncomingCallView extends StatelessWidget {
  final CallBloc callBloc;
  final CallBlocState state;
  final RTCVideoRenderer localRenderer;

  const IncomingCallView({
    required this.callBloc,
    required this.state,
    required this.localRenderer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCallScreen(
      controls: _buildControls(),
      children: [
        if (state.isVideoCall)
          VideoBox(
            renderer: localRenderer,
            photoUrl: state.self.photoUrlOrId,
            available: state.isVideoCall,
            mirror: true,
          ),
        Align(
          alignment: const FractionalOffset(0.5, 0.25),
          child: RemoteMembersCarousel(
            spacing: 10,
            members: state.remoteMembers, children: [
            Icon(state.isVideoCall ? Icons.videocam : Icons.call,
              color: Colors.white,),
            Text("Incoming Call",
              style: TextStyle(color: Colors.white, fontSize: 18),)
          ],),
        ),
      ],
    );
  }

  Widget _buildControls() =>
      IncomingCallControls(
        isVideoCall: state.isVideoCall,
        onDeclineCallTap:
            (reason) => callBloc.add(DeclineIncomingCallEvent(reason)),
        onAcceptCallTap: () => callBloc.add(AcceptIncomingCallEvent()),
        onCallSwitch: (isVideo) {
          callBloc.add(
            SwitchCallModeEvent(isVideo ? CallMode.video : CallMode.audio),
          );
        },
      );
}

/// A widget that displays up to three remote member avatars overlapped
/// in a curved, backward-stack style, with an indicator for additional members.
class RemoteMembersCarousel extends StatelessWidget {
  /// List of remote members to display (Member must have photoUrlOrId & displayNameOrId).
  final List<Member> members;

  final List<Widget> children;

  /// Radius of each avatar circle.
  final double avatarRadius;

  /// Vertical spacing between avatars and names.
  final double spacing;

  const RemoteMembersCarousel({
    super.key,
    required this.members,
    this.children = const [],
    this.avatarRadius = 80,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OverlappingImageRow(members: members, diameter: avatarRadius),
        SizedBox(height: spacing),
        RemoteMemberNames(members: members, width: 200),
        for(var child in children)...{
          SizedBox(height: spacing),
          child
        }
      ],
    );
  }
}

class OverlappingImageRow extends StatelessWidget {
  final List<Member> members;
  final double diameter;
  final double overlapFraction;

  const OverlappingImageRow({
    super.key,
    required this.members,
    this.diameter = 80,
    this.overlapFraction = 0.33,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrls = members.map((m) => m.photoUrlOrId).toList();
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    if (imageUrls.length == 1) {
      final singleDiam = diameter * 1.5;
      return SizedBox(
        width: singleDiam,
        height: singleDiam,
        child: CircleAvatar(
          radius: singleDiam / 2,
          backgroundImage: NetworkImage(imageUrls.first),
        ),
      );
    }

    final overlap = diameter * overlapFraction;
    final displayCount = imageUrls.length.clamp(0, 3);
    final extraCount = imageUrls.length - displayCount;

    final totalItems = displayCount + (extraCount > 0 ? 1 : 0);
    final totalWidth = diameter + (totalItems - 1) * (diameter - overlap);

    return SizedBox(
      width: totalWidth,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < displayCount; i++)
            Positioned(
              left: i * (diameter - overlap),
              child: CircleAvatar(
                radius: diameter / 2,
                backgroundImage: NetworkImage(imageUrls[i]),
              ),
            ),

          if (extraCount > 0)
            Positioned(
              left: displayCount * (diameter - overlap),
              child: CircleAvatar(
                radius: diameter / 2,
                backgroundColor: Colors.white24,
                child: Text(
                  '+$extraCount',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RemoteMemberNames extends StatelessWidget {
  final List<Member> members;
  final double width;
  final double spacing;

  const RemoteMemberNames({
    super.key,
    required this.members,
    required this.width,
    this.spacing = 8,
  });

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    // Limit to 3 names, add badge if needed
    final displayCount = members.length.clamp(0, 3);
    final extraCount = members.length - displayCount;

    // Build and capitalize names
    final List<String> nameList =
    members
        .take(displayCount)
        .map((m) => _capitalize(m.displayNameOrId))
        .toList();

    if (extraCount > 0) nameList.add('+$extraCount');
    final displayNames = nameList.join(', ');

    return SizedBox(
      width: width,
      child: Text(
        displayNames,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
