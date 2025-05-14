import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

class RemoteMemberNames extends StatelessWidget {
  final List<Member> members;
  final double width;
  final double spacing;
  final double? fontSize;

  const RemoteMemberNames({
    super.key,
    required this.members,
    required this.width,
    this.spacing = 8,
    this.fontSize = 16,
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
        members.take(displayCount).map((m) => _capitalize(m.displayNameOrId)).toList();

    if (extraCount > 0) nameList.add('+$extraCount');
    final displayNames = nameList.join(', ');

    return SizedBox(
      width: width,
      child: Text(
        displayNames,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: fontSize),
      ),
    );
  }
}
