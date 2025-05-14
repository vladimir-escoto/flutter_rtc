import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

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
          backgroundColor: Colors.white24,
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
                backgroundColor: Colors.white24,
                backgroundImage: NetworkImage(imageUrls[i]),
              ),
            ),

          if (extraCount > 0)
            Positioned(
              left: displayCount * (diameter - overlap),
              child: CircleAvatar(
                radius: diameter / 2,
                backgroundColor: Colors.white24,
                child: Text('+$extraCount', style: const TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

