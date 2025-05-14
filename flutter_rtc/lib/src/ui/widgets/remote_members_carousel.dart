import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';
import 'package:flutter_rtc/src/ui/widgets/overlapping_image_row.dart';
import 'package:flutter_rtc/src/ui/widgets/remote_member_names.dart';

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

  final double? fontSize;

  const RemoteMembersCarousel({
    super.key,
    required this.members,
    this.children = const [],
    this.avatarRadius = 100,
    this.spacing = 16,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OverlappingImageRow(members: members, diameter: avatarRadius),
        SizedBox(height: spacing),
        RemoteMemberNames(members: members, width: 200, spacing: spacing,fontSize:fontSize),
        for (var child in children) ...{SizedBox(height: spacing), child},
      ],
    );
  }
}
